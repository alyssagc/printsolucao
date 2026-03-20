require 'json'
require 'erb'
require 'time'
require 'fileutils'

class POGenerator
  attr_reader :deals, :logger

  LAST_PO_FILE   = 'output/last_po.txt'
  BACKUP_PO_FILE = 'output/last_po.txt.bak'
  TEMPLATE_PATH  = 'templates/emails/po_email.html.erb'
  ID_RESPONSIBLE_PO_TASK = RD_CONFIG[:id_responsible_po_task]

  def initialize(deals, logger: nil, crm_connector: nil)
    @deals = deals || []
    @logger = logger || Logger.new($stdout)
    @current_po = read_last_po
    @crm_connector = crm_connector
    @mailer = SmtpMailer.new
  end

  # Retorna hash com total, success e failures
  def process_pos
    @failures = []
    @success_count = 0

    logger.info "Fluxo POs iniciado"
    logger.info ""

    @deals.each do |deal|
      po = po_hash(deal)
      failures_before = @failures.size

      logger.info "Gerando pedido para #{po['deal_name']}"
      logger.info "Deal ID #{po['deal_id']}"
      logger.info "#{po['po_number']}"

      mark_deal_as_sent(po)
      write_last_po(po['po_number'])
      send_po_email(po)
      create_task(po)

      @success_count += 1 if @failures.size == failures_before

      logger.info ""
    end

    logger.info "Fluxo de POs finalizado!"

    { total: @deals.size, success: @success_count, failures: @failures }
  end

  private

  def create_task(po_hash)
    task_payload = {
      task: {
        deal_id: po_hash['deal_id'],
        subject: "Entrar com o Pedido",
        notes: po_hash['po_number'],
        date: Date.today.strftime("%Y-%m-%d"),
        hour: Time.now.strftime("%H:%M"),
        type: "task",
        user_ids: ID_RESPONSIBLE_PO_TASK
      }
    }

    response = @crm_connector.create_task(task_payload)
    logger.info "Tarefa criada para Viviane: #{response['id']} -> #{response['subject']}"
  rescue StandardError => e
    msg = "Falha ao criar tarefa para deal #{po_hash['deal_id']}: #{e.message}"
    logger.error "*** #{msg}"
    @failures << msg
  end

  def send_po_email(po)
    recipient = po.dig('owner', 'email')

    if recipient.blank?
      logger.warn "*** Deal #{po['deal_name']} não tem email responsável da print cadastrado. Pulando envio."
      return
    end

    template_content = File.read(TEMPLATE_PATH)

    begin
      html_body = ERB.new(template_content).result_with_hash(deal: po)
      @mailer.mail_po_infos(po_number: po['po_number'], recipient: recipient, html_body: html_body)

      logger.info "Email enviado para #{recipient} com o PO #{po['po_number']}"
    rescue StandardError => e
      msg = "Falha ao enviar email para #{recipient} (deal #{po['deal_id']}): #{e.message}"
      logger.error "*** #{msg}"
      @failures << msg
    end
  end

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
    msg = "Falha ao atualizar CRM para deal #{po_hash['deal_id']}: #{e.message}"
    logger.error "*** #{msg}"
    @failures << msg
  end

  def safe_format_date(date)
    return "—" if date.blank?

    Time.parse(date).strftime("%d/%m/%Y %H:%M")
  rescue StandardError
    "—"
  end

  def po_hash(deal)
    {
      "po_number" => next_po_number,
      "deal_id" => deal["id"],
      "deal_name" => deal["name"],
      "fase" => deal.dig("deal_stage", "name"),
      "status" => deal["win"] ? 'Vendido' : 'Perdido',
      "campanha" => deal.dig("campaign", "name"),
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
      "created_at" => safe_format_date(deal["created_at"]),
      "updated_at" => safe_format_date(deal["updated_at"])
    }
  end

  def read_last_po
    content = read_po_file
    logger.info "Ultimo PO gerado: #{content}"
    logger.info " "
    content.split('-')[1].split('/').first.to_i
  end

  def read_po_file
    if File.exist?(LAST_PO_FILE)
      File.read(LAST_PO_FILE).strip
    elsif File.exist?(BACKUP_PO_FILE)
      logger.warn "Arquivo principal ausente. Usando backup: #{BACKUP_PO_FILE}"
      File.read(BACKUP_PO_FILE).strip
    else
      raise "Nenhum arquivo de PO encontrado (#{LAST_PO_FILE} ou #{BACKUP_PO_FILE}). Verifique o estado do sistema."
    end
  end

  def next_po_number
    @current_po += 1
    year = Time.now.year.to_s[2..3]
    "PO-#{@current_po}/#{year}"
  end

  def write_last_po(po_number)
    logger.info "Atualizando arquivo .txt com ultimo PO: #{po_number}"
    FileUtils.cp(LAST_PO_FILE, BACKUP_PO_FILE) if File.exist?(LAST_PO_FILE)
    File.write(LAST_PO_FILE, po_number)
  end
end
