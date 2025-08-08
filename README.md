# RELATÓRIO DE IMPLEMENTAÇÃO DE SERVIÇOS AWS

Data: 10/08/2025  
Empresa: Abstergo Industries  
Responsável: Gabriela Zala Coutinho Arruda 

## Introdução  
Este relatório apresenta o processo de implementação de ferramentas na empresa Abstergo Industries, realizado por Gabriela Zala Coutinho Arruda. O objetivo do projeto foi implementar 3 serviços AWS, com a finalidade de realizar diminuição de custos imediatos.

## Descrição do Projeto  
O projeto de implementação de ferramentas foi dividido em 3 etapas, cada uma com seus objetivos específicos. A seguir, serão descritas as etapas do projeto:

Etapa 1:  
- Amazon RDS (Relational Database Service)  
- Migração do banco de dados local para nuvem  
- Substituição do servidor SQL Server local por uma instância RDS gerenciada, eliminando custos de manutenção de hardware, licenciamento de software e infraestrutura física. A farmácia possui um sistema de gestão com aproximadamente 50.000 registros de produtos e 10.000 clientes cadastrados. A migração para RDS eliminará a necessidade de backup manual, garantindo alta disponibilidade e reduzindo custos operacionais significativamente.  

Etapa 2:  
- Amazon S3 (Simple Storage Service)  
- Armazenamento de documentos e backups  
- Migração de todos os documentos digitais da farmácia (receitas, relatórios fiscais, imagens de produtos, backups) para o Amazon S3. Atualmente, a empresa utiliza servidores locais com 2TB de dados, gerando custos de energia e manutenção. O S3 oferece armazenamento escalável com custo reduzido comparado à infraestrutura local, além de redundância automática e políticas de lifecycle para arquivamento de dados antigos, otimizando os custos de armazenamento.  

Etapa 3:  
- AWS Lambda + API Gateway  
- Automação de processos e aplicação web serverless  
- Desenvolvimento de uma aplicação web serverless para gestão de estoque e vendas online. Substituição do servidor web tradicional por uma arquitetura serverless que escala automaticamente conforme a demanda. A farmácia processa em média 500 transações por dia, com picos de 2.000 durante promoções. A solução serverless elimina custos de servidores ociosos e paga apenas pelo tempo de execução real, resultando em economia significativa durante períodos de baixa demanda.

## Conclusão  
A implementação de ferramentas na empresa *Abstergo Industries* tem como esperado redução significativa nos custos de infraestrutura, aumento na disponibilidade dos sistemas, eliminação de custos de manutenção de hardware e melhoria no tempo de backup e recuperação de dados, o que aumentará a eficiência e a produtividade da empresa.  
Recomenda-se a continuidade da utilização das ferramentas implementadas e a busca por novas tecnologias que possam melhorar ainda mais os processos da empresa.

## Anexos  
- Manual de Operação AWS RDS  
- Política de Backup e Recuperação  
- Documentação da Arquitetura Serverless  
- Plano de Migração de Dados  
- Cronograma de Implementação  
- Análise de Custos Comparativa (Antes vs Depois)  

Assinatura do Responsável pelo Projeto:  

Gabriela Zala Coutinho Arruda  
Abstergo Industries
