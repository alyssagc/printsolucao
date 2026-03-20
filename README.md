# PrintSolução

Automação de **Pedidos de Compra (POs)** e **Relatórios** integrados ao **RD Station CRM**.

O sistema executa dois jobs:
- **`process_pos`** — busca negócios ganhos na coluna de pedido e gera POs automaticamente, criando uma task no CRM para o responsável.
- **`envia_dados_relatorio`** — exporta deals dos últimos 60 dias em CSV e envia por email.

---

## Requisitos

- Docker e Docker Compose

> Para rodar localmente sem Docker: Ruby 3.2+ e Bundler.

---

## Configuração

### 1. Clonar o projeto

```bash
git clone git@github.com:usuario/printsolucao.git
cd printsolucao
```

### 2. Criar o arquivo `.env`

```bash
cp .env.example .env
# editar com os valores reais
```

Variáveis obrigatórias:

| Variável | Descrição |
|---|---|
| `RD_TOKEN` | Token da API do RD Station CRM |
| `ID_PEDIDO_ENVIADO` | ID do campo customizado "Pedido Enviado" no CRM |
| `ID_RESPONSIBLE_PO_TASK` | IDs (separados por vírgula) dos responsáveis pela task de PO |
| `ID_CAMPAIGN_DELL` | ID da campanha Dell no CRM |
| `IDS_STAGE_PEDIDO` | IDs (separados por vírgula) das etapas de pedido no CRM |
| `EMAIL_USERNAME` | Usuário SMTP |
| `EMAIL_PASSWORD` | Senha SMTP |
| `EMAIL_TO` | Destinatário dos relatórios |
| `EMAIL_ALERT_TO` | Destinatário dos alertas de erro (padrão: `EMAIL_TO`) |
| `SMTP_ADDRESS` | Endereço do servidor SMTP (padrão: `smtp.gmail.com`) |
| `SMTP_PORT` | Porta SMTP (padrão: `587`) |
| `APP_ENV` | Ambiente: `development` ou `production` |

### 3. Preencher o número do último PO gerado

```bash
echo "12345" > output/last_po.txt
```

---

## Executando com Docker

### Build

```bash
docker compose build
```

### Rodar um job manualmente

```bash
# Gerar POs
docker compose run --rm process_pos

# Enviar relatório CSV
docker compose run --rm envia_dados_relatorio
```

### Logs

Os logs são gravados em `./log/` no host (volume montado):

```
log/process_pos.log
log/envia_dados_relatorio.log
```

---

## Agendamento via crontab

O agendamento é feito na crontab da máquina host. Editar com:

```bash
crontab -e
```

Exemplos:

```bash
# Gerar POs — diariamente às 08:00
0 8 * * * docker compose -f /caminho/do/projeto/docker-compose.yml run --rm process_pos

# Enviar relatório — toda sexta às 18:00
0 18 * * 5 docker compose -f /caminho/do/projeto/docker-compose.yml run --rm envia_dados_relatorio
```

---

## Executando localmente (sem Docker)

```bash
bundle install

# Gerar POs
bundle exec rake -f bin/jobs.rake jobs:process_pos

# Enviar relatório CSV
bundle exec rake -f bin/jobs.rake jobs:envia_dados_relatorio
```

> Em desenvolvimento, use o **MailCatcher** para capturar os emails: `APP_ENV=development`

---

## Links úteis

- [RD Station CRM — Documentação da API](https://developers.rdstation.com/reference/crm-v1-introducao-e-requisitos)
- [RD Station CRM — App](https://crm.rdstation.com/app/home)
