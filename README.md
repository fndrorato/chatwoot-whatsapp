# Stack Completa: Chatwoot + N8N + WAHA

Arquitetura completa para atendimento WhatsApp com CRM, automações e suporte a Canais.

## 📋 Pré-requisitos

- Docker e Docker Compose instalados
- Pelo menos 4GB de RAM disponível
- Portas disponíveis: 3000, 3001, 5432, 5678, 6379

## 🚀 Instalação Rápida

### 1. Clone ou crie a estrutura de arquivos

```bash
mkdir whatsapp-stack
cd whatsapp-stack
```

Crie os seguintes arquivos:
- `docker-compose.yml`
- `.env`
- `init-db.sql`

### 2. Configure o arquivo .env

Edite o arquivo `.env` e altere:

```bash
# OBRIGATÓRIO ALTERAR:
POSTGRES_PASSWORD=sua_senha_super_segura
CHATWOOT_SECRET_KEY_BASE=$(openssl rand -hex 64)
N8N_BASIC_AUTH_PASSWORD=sua_senha_n8n
WAHA_API_KEY=$(openssl rand -hex 32)
```

### 3. Inicie os serviços

```bash
# IMPORTANTE: Na primeira vez, siga esta ordem:

# 1. Subir apenas o banco e Redis primeiro
docker-compose up -d postgres redis

# 2. Aguardar até ficarem saudáveis (30 segundos)
docker-compose ps

# 3. Preparar o banco de dados do Chatwoot
docker-compose run --rm chatwoot_prepare

# 4. Agora sim, subir todos os serviços
docker-compose up -d

# Ver logs
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f chatwoot_web
```

**Alternativa (mais simples):**
```bash
# Deixar o Docker Compose gerenciar tudo automaticamente
docker-compose up -d

# O chatwoot_prepare vai rodar primeiro e preparar o banco
# Depois chatwoot_web e chatwoot_worker iniciam automaticamente
```

### 4. Aguarde a inicialização

O Chatwoot pode demorar 2-5 minutos na primeira vez (preparação do banco). 

Acompanhe com:
```bash
docker-compose logs -f chatwoot_prepare
```

Aguarde até ver:
```
Database prepared successfully
```

Depois verifique o chatwoot_web:
```bash
docker-compose logs -f chatwoot_web
```

Aguarde até ver:
```
=> Booting Puma
=> Rails 7.x application starting in production
* Listening on http://0.0.0.0:3000
```

### 5. Acesse os serviços

- **Chatwoot**: http://localhost:3000
- **N8N**: http://localhost:5678 (usuário: admin / senha: conforme .env)
- **WAHA**: http://localhost:3001

## 📱 Configuração do WhatsApp

### Opção 1: WhatsApp Cloud API (Oficial - Recomendado)

1. Acesse o [Meta Developers](https://developers.facebook.com/)
2. Crie um app e adicione o produto WhatsApp
3. No Chatwoot:
   - Vá em **Configurações → Caixas de entrada → Adicionar caixa de entrada**
   - Escolha **WhatsApp**
   - Selecione **WhatsApp Cloud**
   - Faça login com Facebook e siga o fluxo

### Opção 2: WAHA para Canais

1. Acesse http://localhost:3001
2. Crie uma nova sessão
3. Escaneie o QR Code com seu WhatsApp
4. Use a API do WAHA para gerenciar canais:

```bash
# Listar canais
curl http://localhost:3001/api/default/channels

# Enviar mensagem para canal
curl -X POST http://localhost:3001/api/sendText \
  -H "Content-Type: application/json" \
  -d '{
    "chatId": "SEU_CANAL_ID@newsletter",
    "text": "Olá!",
    "session": "default"
  }'
```

## 🔄 Integração N8N + Chatwoot

### 1. Configurar Webhook no Chatwoot

No Chatwoot:
1. Vá em **Configurações → Integrações → Webhooks**
2. Adicione: `http://n8n:5678/webhook/chatwoot`
3. Selecione os eventos desejados

### 2. Criar fluxo no N8N

1. Acesse http://localhost:5678
2. Crie novo workflow
3. Adicione trigger "Webhook"
4. URL: `http://localhost:5678/webhook/chatwoot`
5. Adicione ações (HTTP Request para Chatwoot API, etc)

### 3. Testar integração

Envie uma mensagem no Chatwoot e veja chegar no N8N.

## 🔧 Comandos Úteis

```bash
# Parar todos os serviços
docker-compose down

# Parar e remover volumes (CUIDADO: apaga dados)
docker-compose down -v

# Reiniciar um serviço específico
docker-compose restart chatwoot_web

# Ver logs em tempo real
docker-compose logs -f

# Acessar shell de um container
docker-compose exec chatwoot_web bash
docker-compose exec postgres psql -U postgres

# Backup do banco de dados
docker-compose exec postgres pg_dump -U postgres chatwoot_production > backup.sql

# Restaurar backup
docker-compose exec -T postgres psql -U postgres chatwoot_production < backup.sql
```

## 📊 Monitoramento

### Verificar saúde dos serviços

```bash
docker-compose ps
```

Todos devem estar com status "Up" e "healthy".

### Verificar recursos

```bash
docker stats
```

## 🔐 Segurança em Produção

### 1. Altere todas as senhas padrão no .env

### 2. Configure SSL com domínio próprio

Descomente a seção do Traefik no docker-compose.yml e configure:

```env
ACME_EMAIL=seu@email.com
CHATWOOT_DOMAIN=chatwoot.seudominio.com
N8N_DOMAIN=n8n.seudominio.com
WAHA_DOMAIN=waha.seudominio.com
```

### 3. Configure firewall

Permita apenas portas 80 e 443 (se usar Traefik) ou as portas específicas necessárias.

### 4. Backups automáticos

Configure backups regulares do PostgreSQL e dos volumes Docker.

## 🐛 Troubleshooting

### Chatwoot não inicia / fica "carregando"

**Problema**: Os logs mostram erro de inicialização do Rails ou o container fica reiniciando.

**Solução**:
```bash
# 1. Parar tudo
docker-compose down

# 2. Subir só o banco e Redis
docker-compose up -d postgres redis

# 3. Aguardar ficarem saudáveis
sleep 30

# 4. Preparar o banco manualmente
docker-compose run --rm chatwoot_prepare

# 5. Verificar se deu certo
# Deve mostrar: "Database prepared successfully"

# 6. Subir tudo novamente
docker-compose up -d

# 7. Acompanhar os logs
docker-compose logs -f chatwoot_web
```

**Se ainda não funcionar:**
```bash
# Resetar completamente (APAGA DADOS!)
docker-compose down -v
docker-compose up -d
```

### Erro: "PG::ConnectionBad" ou "could not connect to server"

```bash
# Verificar se PostgreSQL está rodando
docker-compose ps postgres

# Ver logs do PostgreSQL
docker-compose logs postgres

# Testar conexão manualmente
docker-compose exec postgres pg_isready -U postgres

# Se não estiver rodando, reiniciar
docker-compose restart postgres
```

### Chatwoot_prepare falha com "Migrations are pending"

```bash
# Executar migrações manualmente
docker-compose run --rm chatwoot_prepare bash -c "bundle exec rails db:migrate"

# Se persistir, resetar o banco (APAGA DADOS!)
docker-compose run --rm chatwoot_prepare bash -c "bundle exec rails db:drop db:create db:migrate"
```

### N8N não conecta ao PostgreSQL

```bash
# Verificar se o PostgreSQL está rodando
docker-compose ps postgres

# Testar conexão
docker-compose exec n8n nc -zv postgres 5432
```

### WAHA não escaneia QR Code

```bash
# Ver logs
docker-compose logs waha

# Reiniciar o serviço
docker-compose restart waha
```

### Porta já em uso

```bash
# Verificar portas em uso
sudo netstat -tulpn | grep LISTEN

# Alterar porta no docker-compose.yml
# De: "3000:3000"
# Para: "3010:3000"
```

## 📚 Recursos Adicionais

- [Documentação Chatwoot](https://www.chatwoot.com/docs/)
- [Documentação N8N](https://docs.n8n.io/)
- [Documentação WAHA](https://waha.devlike.pro/)
- [WhatsApp Business API](https://developers.facebook.com/docs/whatsapp/)

## 🆘 Suporte

Se encontrar problemas:

1. Verifique os logs: `docker-compose logs -f`
2. Verifique se todos os serviços estão rodando: `docker-compose ps`
3. Consulte a documentação oficial de cada ferramenta

## 📝 Notas

- O Chatwoot pode demorar alguns minutos para iniciar na primeira vez
- Certifique-se de ter pelo menos 4GB de RAM disponível
- Para produção, sempre use SSL/HTTPS
- Faça backups regulares dos volumes Docker
- image: devlikeapro/waha-plus:gows-arm