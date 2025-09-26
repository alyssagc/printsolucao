require 'rake'
require 'logger'
require 'fileutils'
require_relative '../config/environment'

namespace :po do
  # Configuração do logger
  LOG_DIR  = 'log'
  LOG_FILE = File.join(LOG_DIR, 'po_jobs.log')

  desc 'Executa todo o fluxo: gerar JSON, enviar emails e atualizar CRM'
  task :run do
    FileUtils.mkdir_p(LOG_DIR)
    logger = Logger.new(LOG_FILE, 'daily')
    logger.level = Logger::INFO

    logger.info "Iniciando Job..."

    begin
      # 1️⃣ Inicializa CRM e busca deals
      crm_connector = RDStationCRMConnector.new
      deals = crm_connector.get_won_deals
      logger.info "✅ #{deals.size} deals encontrados para gerar POs"

      if deals.empty?
        logger.info "*** Nenhum deal ganho encontrado. Encerrando execução."
        next
      end

      # 2️⃣ Inicializa POGenerator e EmailSender
      po_gen = POGenerator.new(deals, logger: logger, crm_connector: crm_connector)

      # 3️⃣ Atualiza CRM, envia email com PO
      po_gen.process_pos

      logger.info "Job encerrado!"

    rescue StandardError => e
      logger.error "Erro na execução: #{e.message}"
      logger.error e.backtrace.join("\n")
      raise
    end
  end
end
