require 'csv'

class DealReportExporter
  def initialize(deals)
    @deals = deals
    @crm_connector = RDStationCRMConnector.new
  end

  # Gera CSV no caminho especificado
  def generate_csv(file_path)
    file_path = csv_file_path

    CSV.open(file_path, "w", col_sep: ",", headers: true) do |csv|
      csv << csv_headers

      @deals.each do |deal|
        full_infos = @crm_connector.fetch_deal(deal['id'])
        csv << csv_row(full_infos)
      end
    end
  end

  private

  def csv_file_path
    timestamp = Date.today.strftime("%Y-%m-%d")
    "output/relatorios_vendas/relatorio_#{timestamp}.csv"
  end

  def csv_headers
    [
      "Deal ID",
      "Status",
      "Nome da Negociação",
      "PO Gerado",
      "Funil",
      "Etapa",
      "Responsável",
      "Produtos",
      "Total",
      "Notas sobre a Perda",
      "Motivo da Perda",
      "Data de Criação",
      "Data de Atualização"
    ]
  end

  def csv_row(deal)
    [
      deal["id"],
      deal["win"] ? "Vendido" : "Perdido",
      deal["name"],
      po_number(deal["name"]),
      deal.dig("deal_pipeline", "name"),
      deal.dig("deal_stage", "name"),
      deal.dig("user", "name"),
      format_products(deal["deal_products"]),
      deal["amount_total"],
      deal["deal_lost_note"] || "-",
      deal.dig("deal_lost_reason", "name") || "-",
      deal["created_at"],
      deal["updated_at"]
    ]
  end

  def format_products(products)
    return "" if products.empty?

    products.map do |p|
      "#{p['name'].strip} (Preço_unit: #{p['price']}, Qtd: #{p['amount']}, Preço_total: #{p['total']})"
    end.join("; ")
  end

  def po_number(deal_name)
    match = deal_name.to_s.match(/PO[-\s]?(\d+\/\d+)/i)
    match ? match[1] : "-"
  end
end
