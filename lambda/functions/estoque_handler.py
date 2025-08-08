import json
import boto3
import pymysql
import os
from datetime import datetime

# Configurações do banco de dados RDS
DB_HOST = os.environ['DB_HOST']
DB_NAME = os.environ['DB_NAME']
DB_USER = os.environ['DB_USER']
DB_PASSWORD = os.environ['DB_PASSWORD']

# Cliente S3 para armazenamento de logs
s3_client = boto3.client('s3')
S3_BUCKET = os.environ['S3_BUCKET']

def lambda_handler(event, context):
    """
    Função Lambda para gestão de estoque da farmácia
    Endpoints:
    - GET /estoque: Lista produtos em estoque
    - POST /estoque: Adiciona produto ao estoque
    - PUT /estoque/{id}: Atualiza quantidade em estoque
    - DELETE /estoque/{id}: Remove produto do estoque
    """
    
    try:
        # Conectar ao banco de dados RDS
        connection = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        
        http_method = event['httpMethod']
        path = event['path']
        
        if http_method == 'GET' and path == '/estoque':
            return get_estoque(connection)
        elif http_method == 'POST' and path == '/estoque':
            return add_produto(connection, json.loads(event['body']))
        elif http_method == 'PUT' and path.startswith('/estoque/'):
            produto_id = path.split('/')[-1]
            return update_estoque(connection, produto_id, json.loads(event['body']))
        elif http_method == 'DELETE' and path.startswith('/estoque/'):
            produto_id = path.split('/')[-1]
            return remove_produto(connection, produto_id)
        else:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Endpoint não encontrado'})
            }
            
    except Exception as e:
        # Log do erro no S3
        log_error(str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Erro interno do servidor'})
        }
    finally:
        if 'connection' in locals():
            connection.close()

def get_estoque(connection):
    """Lista todos os produtos em estoque"""
    try:
        with connection.cursor() as cursor:
            sql = """
                SELECT p.id_produto, p.nome, p.estoque_atual, p.estoque_minimo, 
                       p.preco_venda, c.nome as categoria
                FROM produtos p
                LEFT JOIN categorias_produtos c ON p.id_categoria = c.id_categoria
                WHERE p.ativo = TRUE
                ORDER BY p.estoque_atual ASC
            """
            cursor.execute(sql)
            produtos = cursor.fetchall()
            
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'produtos': produtos,
                    'total_produtos': len(produtos)
                })
            }
    except Exception as e:
        raise e

def add_produto(connection, data):
    """Adiciona novo produto ao estoque"""
    try:
        with connection.cursor() as cursor:
            sql = """
                INSERT INTO produtos (nome, descricao, preco_custo, preco_venda, 
                                    estoque_atual, estoque_minimo, id_categoria, 
                                    fabricante, principio_ativo, concentracao, 
                                    forma_farmaceutica, receita_obrigatoria)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(sql, (
                data['nome'],
                data.get('descricao', ''),
                data['preco_custo'],
                data['preco_venda'],
                data.get('estoque_atual', 0),
                data.get('estoque_minimo', 10),
                data.get('id_categoria'),
                data.get('fabricante', ''),
                data.get('principio_ativo', ''),
                data.get('concentracao', ''),
                data.get('forma_farmaceutica', ''),
                data.get('receita_obrigatoria', False)
            ))
            connection.commit()
            
            return {
                'statusCode': 201,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': 'Produto adicionado com sucesso',
                    'id_produto': cursor.lastrowid
                })
            }
    except Exception as e:
        connection.rollback()
        raise e

def update_estoque(connection, produto_id, data):
    """Atualiza quantidade em estoque"""
    try:
        with connection.cursor() as cursor:
            sql = """
                UPDATE produtos 
                SET estoque_atual = %s, estoque_minimo = %s
                WHERE id_produto = %s AND ativo = TRUE
            """
            cursor.execute(sql, (
                data['estoque_atual'],
                data.get('estoque_minimo', 10),
                produto_id
            ))
            
            if cursor.rowcount == 0:
                return {
                    'statusCode': 404,
                    'body': json.dumps({'error': 'Produto não encontrado'})
                }
            
            connection.commit()
            
            # Verificar se estoque está baixo
            if data['estoque_atual'] <= data.get('estoque_minimo', 10):
                send_alert_estoque_baixo(produto_id, data['estoque_atual'])
            
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': 'Estoque atualizado com sucesso'
                })
            }
    except Exception as e:
        connection.rollback()
        raise e

def remove_produto(connection, produto_id):
    """Remove produto do estoque (soft delete)"""
    try:
        with connection.cursor() as cursor:
            sql = "UPDATE produtos SET ativo = FALSE WHERE id_produto = %s"
            cursor.execute(sql, (produto_id,))
            
            if cursor.rowcount == 0:
                return {
                    'statusCode': 404,
                    'body': json.dumps({'error': 'Produto não encontrado'})
                }
            
            connection.commit()
            
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'message': 'Produto removido com sucesso'
                })
            }
    except Exception as e:
        connection.rollback()
        raise e

def send_alert_estoque_baixo(produto_id, estoque_atual):
    """Envia alerta quando estoque está baixo"""
    try:
        alert_data = {
            'produto_id': produto_id,
            'estoque_atual': estoque_atual,
            'timestamp': datetime.now().isoformat(),
            'message': f'Estoque baixo para produto ID {produto_id}'
        }
        
        # Salvar alerta no S3
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=f'alerts/estoque_baixo_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json',
            Body=json.dumps(alert_data),
            ContentType='application/json'
        )
        
    except Exception as e:
        print(f"Erro ao enviar alerta: {str(e)}")

def log_error(error_message):
    """Registra erros no S3"""
    try:
        log_data = {
            'timestamp': datetime.now().isoformat(),
            'error': error_message
        }
        
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=f'logs/errors/{datetime.now().strftime("%Y%m%d_%H%M%S")}.json',
            Body=json.dumps(log_data),
            ContentType='application/json'
        )
        
    except Exception as e:
        print(f"Erro ao registrar log: {str(e)}")
