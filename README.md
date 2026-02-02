# 🌐 PrintSolução
Automação de **Pedidos de Compra (POs)** e **Relatórios** integrados ao **RD Station CRM**.

O sistema executa automaticamente:
- Geração de POs para negócios ganhos
- Criação de task no CRM para o responsável entrar com o pedido.
- Envio de relatórios CSV com deals cadastrados  

---

### ⚙️ Requisitos

- Ruby **3.2+**
- Bundler
- Conta **RD Station CRM** com token de API
- Servidor SMTP válido (produção)
- **MailCatcher** (ambiente de desenvolvimento)
---

### 🧩 Configuração
```
#0. Clonar o projeto
git clone git@github.com:usuario/printsolucao.git
cd printsolucao

#1.Instalar dependências
bundle install

#2. Preencher arquivo .env
config smtp e rd token

#3. Preencher arquivo .txt com o número do último PO gerado.
output/last_po.txt
```
---
### ▶️ Executando Jobs
```
#Gerar POs
rake -f bin/jobs.rake jobs:process_pos

#Enviar relatório CSV
rake -f bin/jobs.rake jobs:envia_dados_relatorio

#Logs gerados em:
log/process_pos.log
log/envia_dados_relatorio.log
```
---
### ⏱️ Agendando via CRON
```
1. Abrir o crontab
crontab -e

2. Exemplos
✔ Executar daily às 08:00 — geração de POs
0 8 * * * cd /caminho/do/projeto && /usr/bin/env bundle exec rake -f bin/jobs.rake jobs:process_pos

✔ Executar toda sexta às 18:00 — relatório
0 18 * * 5 cd /caminho/do/projeto && /usr/bin/env bundle exec rake -f bin/jobs.rake jobs:envia_dados_relatorio
```
---

#### Links úteis
- https://developers.rdstation.com/reference/crm-v1-introducao-e-requisitos (RD API Doc)
- https://crm.rdstation.com/app/home (RD Station app)
