require 'rake'
require 'logger'
require 'fileutils'
require_relative '../config/environment'

namespace :jobs do
  # Configuração do logger
  LOG_DIR  = 'log'
  LOG_FILE = File.join(LOG_DIR, 'po_jobs.log')

  def build_logger
    FileUtils.mkdir_p(LOG_DIR)
    logger = Logger.new(LOG_FILE, 'daily')
    logger = Logger.new(LOG_FILE, 5, 5 * 1024 * 1024)

    logger.formatter = proc do |severity, datetime, _progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
    end

    logger
  end

  desc 'Gera e processa pedidos'
  task :process_pos do
    logger = build_logger
    logger.info "Iniciando Job: process_pos..."

    begin
      crm_connector = RDStationCRMConnector.new
      deals = crm_connector.fetch_won_deals_pending_po

      logger.info "✅ #{deals.size} deals encontrados para gerar POs"

      if deals.blank?
        logger.info "*** Nenhum deal ganho encontrado. Encerrando execução."
        next
      end

      po_gen = POGenerator.new(deals, logger: logger, crm_connector: crm_connector)
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
    logger = build_logger
    logger.info "Iniciando Job: envia_dados_relatorio..."

    begin
      crm_connector = RDStationCRMConnector.new
      deals = crm_connector.fetch_deals_in_po_stage

      logger.info "✅ #{deals.size} deals encontrados"

      if deals.any?
        exporter = DealReportExporter.new(deals)
        csv_string = exporter.to_csv_string

        mailer = SmtpMailer.new
        mailer.mail_deals_info(csv_string)

        logger.info "Relatório enviado por email com sucesso!"
      else
        logger.info "*** Nenhum deal encontrado. Encerrando execução."
      end

      logger.info "Job encerrado!"

    rescue StandardError => e
      logger.error "Erro na execução: #{e.message}"
      logger.error e.backtrace.join("\n")
      raise
    end
  end
end
