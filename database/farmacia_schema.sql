-- Esquema do Banco de Dados - Abstergo Industries (Farmácia)
-- Criado para migração AWS RDS

-- Criação das tabelas principais
CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    email VARCHAR(100),
    telefone VARCHAR(15),
    endereco TEXT,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE categorias_produtos (
    id_categoria INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(50) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE produtos (
    id_produto INT PRIMARY KEY AUTO_INCREMENT,
    codigo_barras VARCHAR(50) UNIQUE,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    preco_custo DECIMAL(10,2) NOT NULL,
    preco_venda DECIMAL(10,2) NOT NULL,
    estoque_atual INT DEFAULT 0,
    estoque_minimo INT DEFAULT 10,
    id_categoria INT,
    fabricante VARCHAR(100),
    principio_ativo VARCHAR(100),
    concentracao VARCHAR(50),
    forma_farmaceutica VARCHAR(50),
    receita_obrigatoria BOOLEAN DEFAULT FALSE,
    ativo BOOLEAN DEFAULT TRUE,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_categoria) REFERENCES categorias_produtos(id_categoria)
);

CREATE TABLE funcionarios (
    id_funcionario INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cpf VARCHAR(14) UNIQUE NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    telefone VARCHAR(15),
    data_admissao DATE,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE vendas (
    id_venda INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT,
    id_funcionario INT,
    data_venda TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valor_total DECIMAL(10,2) NOT NULL,
    forma_pagamento VARCHAR(20),
    status VARCHAR(20) DEFAULT 'CONCLUIDA',
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_funcionario) REFERENCES funcionarios(id_funcionario)
);

CREATE TABLE itens_venda (
    id_item INT PRIMARY KEY AUTO_INCREMENT,
    id_venda INT,
    id_produto INT,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_venda) REFERENCES vendas(id_venda),
    FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

CREATE TABLE fornecedores (
    id_fornecedor INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cnpj VARCHAR(18) UNIQUE,
    email VARCHAR(100),
    telefone VARCHAR(15),
    endereco TEXT,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE TABLE compras (
    id_compra INT PRIMARY KEY AUTO_INCREMENT,
    id_fornecedor INT,
    data_compra TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valor_total DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDENTE',
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedores(id_fornecedor)
);

CREATE TABLE itens_compra (
    id_item INT PRIMARY KEY AUTO_INCREMENT,
    id_compra INT,
    id_produto INT,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_compra) REFERENCES compras(id_compra),
    FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

-- Inserção de dados de exemplo
INSERT INTO categorias_produtos (nome, descricao) VALUES
('Analgésicos', 'Medicamentos para dor'),
('Antibióticos', 'Medicamentos antibacterianos'),
('Anti-inflamatórios', 'Medicamentos para inflamação'),
('Cosméticos', 'Produtos de beleza e higiene'),
('Suplementos', 'Vitaminas e suplementos alimentares');

INSERT INTO funcionarios (nome, cpf, cargo, email, data_admissao) VALUES
('João Silva', '123.456.789-01', 'Farmacêutico', 'joao@abstergo.com', '2023-01-15'),
('Maria Santos', '987.654.321-00', 'Atendente', 'maria@abstergo.com', '2023-02-01'),
('Pedro Costa', '456.789.123-45', 'Auxiliar', 'pedro@abstergo.com', '2023-03-10');

INSERT INTO fornecedores (nome, cnpj, email, telefone) VALUES
('Farma Distribuidora Ltda', '12.345.678/0001-90', 'contato@farmadist.com', '(11) 9999-8888'),
('Medicamentos Brasil S.A.', '98.765.432/0001-10', 'vendas@medbrasil.com', '(11) 8888-7777'),
('Cosméticos Express', '55.666.777/0001-33', 'pedidos@cosmeticos.com', '(11) 7777-6666');

-- Índices para otimização de performance
CREATE INDEX idx_produtos_categoria ON produtos(id_categoria);
CREATE INDEX idx_produtos_ativo ON produtos(ativo);
CREATE INDEX idx_vendas_data ON vendas(data_venda);
CREATE INDEX idx_vendas_cliente ON vendas(id_cliente);
CREATE INDEX idx_estoque_produto ON produtos(estoque_atual, estoque_minimo);
