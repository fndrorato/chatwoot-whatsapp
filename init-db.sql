-- Criar bancos de dados para cada serviço
-- Este script é executado automaticamente na primeira vez que o PostgreSQL inicia

-- Banco para Chatwoot
CREATE DATABASE chatwoot_production;

-- Banco para N8N
CREATE DATABASE n8n;

-- Conceder permissões
GRANT ALL PRIVILEGES ON DATABASE chatwoot_production TO postgres;
GRANT ALL PRIVILEGES ON DATABASE n8n TO postgres;

-- Conectar ao banco do Chatwoot e criar extensão vector
\c chatwoot_production;
CREATE EXTENSION IF NOT EXISTS vector;

-- Voltar ao banco postgres
\c postgres;