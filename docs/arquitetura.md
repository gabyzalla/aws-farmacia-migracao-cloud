# Arquitetura da Solução - Abstergo Industries

## Visão Geral

Este documento descreve a arquitetura da solução de migração para nuvem AWS da Abstergo Industries, uma farmácia fictícia que implementou três serviços principais para redução de custos e melhoria da eficiência operacional.

## Componentes da Arquitetura

### 1. Amazon RDS (Relational Database Service)

**Propósito:** Banco de dados gerenciado para o sistema de gestão da farmácia

**Configuração:**
- **Engine:** MySQL 8.0.35
- **Instance Class:** db.t3.micro (escalável conforme demanda)
- **Storage:** 20GB inicial, auto-scaling até 100GB
- **Backup:** Retenção de 7 dias com janela de backup automática
- **Segurança:** Criptografia em repouso e em trânsito

**Benefícios:**
- Eliminação de custos de hardware e licenciamento
- Backup automático e recuperação de desastres
- Alta disponibilidade (99,9% uptime)
- Manutenção gerenciada pela AWS

### 2. Amazon S3 (Simple Storage Service)

**Propósito:** Armazenamento de documentos, imagens e backups

**Configuração:**
- **Bucket:** Versionamento habilitado
- **Lifecycle Policy:** 
  - 30 dias: Standard → Standard-IA
  - 90 dias: Standard-IA → Glacier
  - 365 dias: Expiração automática
- **Segurança:** Criptografia AES-256

**Benefícios:**
- Custo 60% menor que infraestrutura local
- Redundância automática (11 9's de durabilidade)
- Escalabilidade ilimitada
- Políticas de lifecycle para otimização de custos

### 3. AWS Lambda + API Gateway

**Propósito:** Aplicação serverless para gestão de estoque e vendas

**Configuração:**
- **Runtime:** Python 3.9
- **Memory:** 256MB (escalável)
- **Timeout:** 30 segundos
- **VPC:** Integração com subnets privadas para acesso ao RDS

**Benefícios:**
- Pagamento apenas pelo tempo de execução
- Escalabilidade automática
- Eliminação de custos de servidores ociosos
- Alta disponibilidade

## Diagrama da Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    Abstergo Industries                      │
│                     Farmácia Cloud                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Gateway   │    │   Lambda Func   │    │   S3 Bucket     │
│                 │    │                 │    │                 │
│ • REST API      │◄──►│ • Estoque Mgmt  │◄──►│ • Documents     │
│ • Rate Limiting │    │ • Vendas API    │    │ • Images        │
│ • Caching       │    │ • Logs          │    │ • Backups       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Amazon RDS    │
                       │                 │
                       │ • MySQL 8.0     │
                       │ • Auto Scaling  │
                       │ • Multi-AZ      │
                       │ • Backups       │
                       └─────────────────┘
```

## Fluxo de Dados

### 1. Gestão de Estoque
1. Cliente acessa API via API Gateway
2. API Gateway roteia para Lambda Function
3. Lambda conecta ao RDS para consultar/atualizar estoque
4. Logs e alertas são salvos no S3
5. Resposta retorna via API Gateway

### 2. Processamento de Vendas
1. Sistema de vendas envia dados via API
2. Lambda processa transação no RDS
3. Atualiza estoque automaticamente
4. Gera relatórios salvos no S3
5. Envia confirmação para cliente

### 3. Backup e Recuperação
1. RDS executa backup automático diário
2. Backups são replicados para S3
3. Políticas de lifecycle movem dados para classes mais baratas
4. Recuperação pode ser feita em minutos

## Segurança

### Network Security
- **VPC:** Isolamento de rede
- **Security Groups:** Controle de tráfego por porta/protocolo
- **Subnets:** Separação pública/privada
- **NAT Gateway:** Acesso à internet para recursos privados

### Data Security
- **Encryption at Rest:** AES-256 para todos os dados
- **Encryption in Transit:** TLS 1.2+ para todas as comunicações
- **IAM:** Controle de acesso baseado em roles
- **VPC Endpoints:** Comunicação segura entre serviços

### Compliance
- **Backup:** Retenção de 7 dias
- **Audit Logs:** Todos os acessos são logados
- **Monitoring:** CloudWatch para monitoramento contínuo

## Monitoramento e Observabilidade

### CloudWatch
- **Metrics:** CPU, memória, latência, throughput
- **Logs:** Centralização de logs de todos os serviços
- **Alarms:** Alertas automáticos para problemas
- **Dashboards:** Visualização em tempo real

### S3 Analytics
- **Access Logs:** Análise de padrões de acesso
- **Storage Analytics:** Otimização de custos
- **Lifecycle Reports:** Eficiência das políticas

## Custos e Otimização

### Estimativa de Custos Mensais (Dev)
- **RDS:** ~$15-25/mês (db.t3.micro)
- **S3:** ~$5-10/mês (2TB de dados)
- **Lambda:** ~$2-5/mês (500 transações/dia)
- **API Gateway:** ~$1-3/mês
- **Total:** ~$23-43/mês

### Comparação com Infraestrutura Local
- **Hardware:** $500-1000/mês
- **Licenciamento:** $200-500/mês
- **Manutenção:** $100-300/mês
- **Energia:** $50-100/mês
- **Total Local:** ~$850-1900/mês

### Economia Estimada
- **Redução de 50-70% nos custos**
- **ROI positivo em 3-6 meses**
- **Escalabilidade sem custos adicionais**

## Disaster Recovery

### RPO (Recovery Point Objective)
- **RDS:** 5 minutos (backup contínuo)
- **S3:** 0 minutos (replicação síncrona)

### RTO (Recovery Time Objective)
- **RDS:** 15-30 minutos (restore de snapshot)
- **S3:** 0 minutos (disponível imediatamente)
- **Lambda:** 0 minutos (sem estado)

### Estratégia de Backup
1. **Backup Automático:** Diário no RDS
2. **Cross-Region:** Replicação para região secundária
3. **Versionamento:** S3 com histórico completo
4. **Teste Regular:** Validação mensal de restore

## Roadmap de Evolução

### Fase 2 (Próximos 3 meses)
- Implementação de CloudFront para CDN
- Adição de DynamoDB para cache
- Implementação de SQS para processamento assíncrono

### Fase 3 (Próximos 6 meses)
- Migração para containers (ECS/Fargate)
- Implementação de CI/CD pipeline
- Adição de machine learning para previsão de estoque

### Fase 4 (Próximos 12 meses)
- Multi-region deployment
- Implementação de microserviços
- Integração com sistemas externos via API Gateway
