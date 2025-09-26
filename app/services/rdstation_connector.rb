require 'net/http'
require 'uri'
require 'json'

class RDStationCRMConnector
  attr_reader :token, :base_url, :logger

  # Status que consideramos "pedido"
  PO_STATUS = [
    "pedido",
    "fechamento do pedido",
    "fechamento pedido"
  ].freeze

  def initialize(token: RD_CONFIG[:token], base_url: "https://crm.rdstation.com/api/v1", logger: nil)
    @token = token
    @base_url = base_url
    @logger = logger || Logger.new($stdout)
  end

  # Método genérico para GET (com suporte a query params)
  def get(endpoint, params = {})
    query = URI.encode_www_form(params.merge(token: token))
    url = URI("#{base_url}/#{endpoint}?#{query}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request['accept'] = 'application/json'

    begin
      response = http.request(request)
    rescue StandardError => e
      raise "Erro de conexão GET #{url}: #{e.message}"
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Erro na requisição GET #{url}: #{response.code} #{response.message}\n#{response.body}"
    end

    JSON.parse(response.body)
  end

  # Retorna apenas os deals ganhos e em status de pedido
  def get_won_deals
    all_won = []

    each_deal_page do |deals|
      deals.select! do |deal|
        stage_name = normalize_string(deal.dig("deal_stage", "name"))
        in_po_status = PO_STATUS.any? { |status| normalize_string(status) == stage_name }

        campo_pedido_enviado = deal.dig("deal_custom_fields")&.find { |f| f["custom_field_id"] == RD_CONFIG[:id_pedido_enviado] }
        enviar_pedido = campo_pedido_enviado.nil?

        in_po_status && enviar_pedido
      end

      all_won.concat(deals)
    end
    all_won
  end

  # Método PUT atualizar atributos crm
  def update_deal(deal_id, attributes = {})
    url = URI("#{base_url}/deals/#{deal_id}?token=#{token}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Put.new(url)
    request['Content-Type'] = 'application/json'
    request.body = attributes.to_json

    begin
      response = http.request(request)
    rescue StandardError => e
      raise "Erro de conexão PUT #{url}: #{e.message}"
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Erro ao atualizar deal #{deal_id}: #{response.code} #{response.message}\n#{response.body}"
    end

    JSON.parse(response.body)
  end

  private

  def normalize_string(str)
    str.to_s.downcase.strip
  end

  # Itera por todas as páginas de deals, usando filtro win=true
  def each_deal_page
    next_page = nil

    loop do
      params = { win: true } # filtro no servidor
      params[:next_page] = next_page if next_page

      response = get("deals", params)
      deals = response.fetch("deals", [])

      yield deals if block_given?

      break unless response["has_more"]

      next_page = response["next_page"]
    end
  end
end
