require 'rake'
require 'logger'
require 'fileutils'
require_relative '../config/environment'

namespace :jobs do
  # Configuração do logger
  LOG_DIR  = 'log'
  LOG_FILE = File.join(LOG_DIR, 'po_jobs.log')

  desc 'Gera e processa pedidos'
  task :process_pos do
    FileUtils.mkdir_p(LOG_DIR)
    logger = Logger.new(LOG_FILE, 'daily')
    logger.level = Logger::INFO

    logger.info "Iniciando Job: process_pos..."

    begin
      # 1️⃣ Inicializa CRM e busca deals
      crm_connector = RDStationCRMConnector.new
      deals = crm_connector.get_won_notsent_deals
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

  desc 'Relatorio pedidosXfunisXresponsaveis'
  task :envia_dados_relatorio do
    FileUtils.mkdir_p(LOG_DIR)
    logger = Logger.new(LOG_FILE, 'daily')
    logger.level = Logger::INFO

    logger.info "Iniciando Job: envia_dados_relatorio..."
    begin
      crm_connector = RDStationCRMConnector.new
      deals = crm_connector.get_po_deals
      logger.info "✅ #{deals.size} deals encontrados"

      if deals.any?
        exporter = DealReportExporter.new(deals)
        exporter.generate_csv("output/relatorio_pedidos.csv")
        logger.info "Dados salvos com sucesso!"
      else
        logger.info "*** Nenhum deal ganho encontrado. Encerrando execução."
      end

      logger.info "Job encerrado!"

    rescue StandardError => e
      logger.error "Erro na execução: #{e.message}"
      logger.error e.backtrace.join("\n")
      raise
    end
  end
end
