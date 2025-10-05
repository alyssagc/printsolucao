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

  # Retorna um deal específico pelo ID
  def fetch_deal(deal_id)
    raise "deal_id não pode ser nil" if deal_id.blank?

    request(:get, "deals/#{deal_id}")
  end

  # Atualiza um deal específico
  def update_deal(deal_id, attributes = {})
    request(:put, "deals/#{deal_id}", body: attributes)
  end

  # Retorna negociações ganhas na coluna de pedido, que ainda não tiveram PO gerado/enviado
  def fetch_won_deals_pending_po
    all_won = []

    iterate_deals_page(win: true) do |deals|
      deals.select! do |deal|
        stage_name = normalize_string(deal.dig("deal_stage", "name"))
        in_po_status = PO_STATUS.any? { |status| normalize_string(status) == stage_name }

        campo_pedido_enviado = deal.dig("deal_custom_fields")&.find { |f| f["custom_field_id"] == RD_CONFIG[:id_pedido_enviado] }
        enviar_pedido = campo_pedido_enviado.blank?

        in_po_status && enviar_pedido
      end

      all_won.concat(deals)
    end
    all_won
  end

  # Retorna negociações em qualquer status da coluna de pedido, independente de ganho
  def fetch_deals_in_po_stage
    all_won = []

    iterate_deals_page do |deals|
      deals.select! do |deal|
        stage_name = normalize_string(deal.dig("deal_stage", "name"))
        PO_STATUS.any? { |status| normalize_string(status) == stage_name }
      end

      all_won.concat(deals)
    end
    all_won
  end

  # Cria uma tarefa
  def create_task(payload)
    request(:post, "tasks", body: payload)
  end

  private

  def normalize_string(str)
    str.to_s.downcase.strip
  end

  def iterate_deals_page(params = {})
    next_page = nil

    loop do
      query = params.dup
      query[:limit] ||= 200
      query[:next_page] = next_page if next_page

      response = request(:get, "deals", params: query)
      deals = response.fetch("deals", [])

      yield deals if block_given?

      break unless response["has_more"]
      next_page = response["next_page"]
    end
  end

  def request(method, endpoint, params: {}, body: nil)
    url = URI("#{base_url}/#{endpoint}")
    url.query = URI.encode_www_form(params.merge(token: token)) if method == :get && params.any?

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = case method
              when :get  then Net::HTTP::Get.new(url)
              when :put  then Net::HTTP::Put.new(url)
              when :post then Net::HTTP::Post.new(url)
              else
                raise "Método HTTP não suportado: #{method}"
              end

    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request.body = body.to_json if body

    begin
      response = http.request(request)
    rescue StandardError => e
      raise "Erro de conexão #{method.upcase} #{url}: #{e.message}"
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Erro na requisição #{method.upcase} #{url}: #{response.code} #{response.message}\n#{response.body}"
    end

    JSON.parse(response.body)
  end
end
