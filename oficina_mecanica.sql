-- Modelo físico: Oficina mecânica (MySQL 8+)
-- Para PostgreSQL: troque AUTO_INCREMENT por GENERATED ALWAYS AS IDENTITY

CREATE DATABASE IF NOT EXISTS oficina;
USE oficina;

CREATE TABLE cliente (
    id_cliente  INT AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    telefone    VARCHAR(20),
    endereco    VARCHAR(200)
);

CREATE TABLE veiculo (
    id_veiculo  INT AUTO_INCREMENT PRIMARY KEY,
    placa       VARCHAR(10) NOT NULL UNIQUE,
    marca       VARCHAR(50),
    modelo      VARCHAR(50),
    ano         SMALLINT,
    id_cliente  INT NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
);

CREATE TABLE equipe (
    id_equipe   INT AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(50) NOT NULL
);

CREATE TABLE mecanico (
    codigo        INT AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    endereco      VARCHAR(200),
    especialidade VARCHAR(60),
    id_equipe     INT NOT NULL,
    FOREIGN KEY (id_equipe) REFERENCES equipe (id_equipe)
);

CREATE TABLE servico (
    id_servico     INT AUTO_INCREMENT PRIMARY KEY,
    descricao      VARCHAR(150) NOT NULL,
    valor_mao_obra DECIMAL(10,2) NOT NULL   -- tabela de referência de mão-de-obra
);

CREATE TABLE peca (
    id_peca        INT AUTO_INCREMENT PRIMARY KEY,
    descricao      VARCHAR(150) NOT NULL,
    valor_unitario DECIMAL(10,2) NOT NULL
);

CREATE TABLE ordem_servico (
    numero         INT AUTO_INCREMENT PRIMARY KEY,
    data_emissao   DATE NOT NULL,
    data_conclusao DATE,                    -- data de entrega prevista
    valor          DECIMAL(10,2) NOT NULL DEFAULT 0,
    status         VARCHAR(20) NOT NULL DEFAULT 'ABERTA',
    autorizada     BOOLEAN NOT NULL DEFAULT FALSE,  -- cliente autoriza a execução
    id_veiculo     INT NOT NULL,
    id_equipe      INT NOT NULL,            -- mesma equipe avalia e executa
    FOREIGN KEY (id_veiculo) REFERENCES veiculo (id_veiculo),
    FOREIGN KEY (id_equipe)  REFERENCES equipe (id_equipe),
    CHECK (status IN ('ABERTA','AGUARDANDO_AUTORIZACAO','EM_EXECUCAO','CONCLUIDA','CANCELADA')),
    CHECK (data_conclusao IS NULL OR data_conclusao >= data_emissao)
);

-- N:N entre OS e serviço
CREATE TABLE os_servico (
    numero_os     INT NOT NULL,
    id_servico    INT NOT NULL,
    valor_cobrado DECIMAL(10,2) NOT NULL,   -- copiado da tabela de referência
    PRIMARY KEY (numero_os, id_servico),
    FOREIGN KEY (numero_os)  REFERENCES ordem_servico (numero),
    FOREIGN KEY (id_servico) REFERENCES servico (id_servico)
);

-- N:N entre OS e peça
CREATE TABLE os_peca (
    numero_os      INT NOT NULL,
    id_peca        INT NOT NULL,
    quantidade     INT NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    valor_unitario DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (numero_os, id_peca),
    FOREIGN KEY (numero_os) REFERENCES ordem_servico (numero),
    FOREIGN KEY (id_peca)   REFERENCES peca (id_peca)
);

-- Valor total da OS = serviços + peças
-- SELECT os.numero,
--        COALESCE((SELECT SUM(valor_cobrado) FROM os_servico WHERE numero_os = os.numero), 0)
--      + COALESCE((SELECT SUM(quantidade * valor_unitario) FROM os_peca WHERE numero_os = os.numero), 0)
--        AS valor_total
-- FROM ordem_servico os;
