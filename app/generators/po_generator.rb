require 'json'
require 'erb'
require 'time'

class POGenerator
  attr_reader :deals, :logger

  LAST_PO_FILE = 'output/last_po.txt'
  ID_VIVI = '64d62262f7bee8002510c6eb'

  def initialize(deals, logger: nil, crm_connector: nil)
    @deals = deals || []
    @logger = logger || Logger.new($stdout)
    @current_po = read_last_po
    @crm_connector = crm_connector
  end

  def process_pos
    logger.info "Fluxo POs iniciado"
    logger.info ""

    template_path = File.join('templates', 'emails', 'po_email.html.erb')
    template_content = File.read(template_path)
    mailer = SmtpMailer.new

    @deals.each do |deal|
      po = po_hash(deal)

      logger.info "#{po['po_number']}"

      mark_deal_as_sent(po)
      write_last_po(po['po_number'])
      send_po_email(po, mailer, template_content)
      create_task(po)

      logger.info ""
    end

    logger.info "Fluxo de POs finalizado!"
  end

  private

  #Cria task (vivi) para entrar com pedido
  def create_task(po_hash)
    task_payload = {
      task: {
        deal_id: po_hash['deal_id'],
        subject: "Entrar com o Pedido",
        notes: po_hash['po_number'],
        date: Date.today.strftime("%Y-%m-%d"),
        hour: Time.now.strftime("%H:%M"),
        type: "task",
        user_ids: [ID_VIVI]
      }
    }

    response = @crm_connector.create_task(task_payload)
    logger.info "Tarefa criada para Viviane: #{response['id']} -> #{response['subject']}"
  rescue StandardError => e
    logger.error "*** Falha ao criar tarefa: #{e.message}"
  end

  # Envia email para o vendedor
  def send_po_email(po, mailer, template_content)
    recipient = po.dig('owner', 'email')

    if recipient.blank?
      logger.warn "*** Deal #{po['deal_name']} não tem email responsável da print cadastrado. Pulando envio."
      return
    end

    begin
      html_body = ERB.new(template_content).result_with_hash(deal: po)
      mailer.send(
        to: recipient,
        subject: "Pedido de Compra - #{po['deal_name']}",
        body: html_body
      )

      logger.info "Email enviado para #{recipient} com o PO #{po['po_number']}"
    rescue StandardError => e
      logger.error "*** Falha ao enviar email para #{recipient}: #{e.message}"
    end
  end

  # Atualiza o CRM com o pedido
  def mark_deal_as_sent(po_hash)
    new_name = "#{po_hash['deal_name']} - #{po_hash['po_number']}"
    params = {
      deal: {
        name: new_name,
        deal_custom_fields: [
          {
            custom_field_id: RD_CONFIG[:id_pedido_enviado],
            value: "Sim"
          }
        ]
      }
    }

    @crm_connector.update_deal(po_hash['deal_id'], params)

    logger.info "CRM atualizado: #{po_hash['deal_id']} -> #{new_name}"
  rescue StandardError => e
    logger.error "*** Falha ao atualizar CRM para deal #{po_hash['deal_id']}: #{e.message}"
  end

  # Gera o hash do PO
  def po_hash(deal)
    {
      "po_number" => next_po_number,
      "deal_id" => deal["id"],
      "deal_name" => deal["name"],
      "fase" => deal.dig("deal_stage", "name"),
      "status" => deal["win"] ? 'Vendido' : 'Perdido',
      "organization" => {
        "name" => deal.dig("organization","name"),
        "address" => deal.dig("organization","address"),
        "responsavel" => deal.dig("organization","user","name"),
        "responsavel_email" => deal.dig("organization","user","email"),
        "segmento" => deal.dig("organization", "organization_segments")&.map { |s| s["name"] },
      },
      "owner" => {
        "name" => deal.dig("user","name"),
        "email" => deal.dig("user","email")
      },
      "products" => (deal["deal_products"] || []).map do |p|
        {
          "name" => p["name"],
          "amount" => p["amount"] || 0,
          "price" => p["price"] || 0.0,
          "total" => p["total"] || 0
        }
      end,
      "custom_fields" => (deal["deal_custom_fields"] || []).map do |cf|
        label = cf.dig("custom_field", "label") || "Campo Desconhecido"
        value = cf["value"].is_a?(Array) ? cf["value"].join(", ") : cf["value"].to_s
        [label, value]
      end.to_h,
      "total_amount" => deal["amount_total"],
      "created_at" => deal["created_at"] ? Time.parse(deal["created_at"]).strftime("%d/%m/%Y %H:%M") : "—",
      "updated_at" => deal["updated_at"] ? Time.parse(deal["updated_at"]).strftime("%d/%m/%Y %H:%M") : "—",

    }
  end

  # Pega o ultimo PO gerado
  def read_last_po
    last = File.read(LAST_PO_FILE).strip
    logger.info "Ultimo PO gerado: #{last}"
    logger.info " "

    last.split('-')[1].split('/').first.to_i
  end

  # Gera o numero de PO sequencial formato pedido/ano
  def next_po_number
    @current_po += 1
    year = Time.now.year.to_s[2..3]
    "PO-#{@current_po}/#{year}"
  end

  # Atualiza last_po.txt
  def write_last_po(po_number)
    logger.info "Atualizando arquivo .txt com ultimo PO: #{po_number}"
    File.write(LAST_PO_FILE, po_number)
  end
end
