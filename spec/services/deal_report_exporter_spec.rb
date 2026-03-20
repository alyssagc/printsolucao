require 'spec_helper'
require 'csv'

RSpec.describe DealReportExporter do
  let(:crm) { instance_double(RDStationCRMConnector) }

  let(:deal) do
    {
      "id"           => "deal_1",
      "name"         => "Empresa XPTO - PO-101/26",
      "win"          => true,
      "amount_total" => 3000.0,
      "created_at"   => "2026-01-10T08:00:00Z",
      "updated_at"   => "2026-03-01T12:30:00Z",
      "campaign"     => { "name" => "Dell" },
      "deal_pipeline" => { "name" => "Funil Principal" },
      "deal_stage"   => { "name" => "Pedido" },
      "user"         => { "name" => "Vendedor" },
      "deal_products" => [
        { "name" => "Impressora", "price" => 1500.0, "amount" => 2, "total" => 3000.0 }
      ],
      "deal_lost_note"   => nil,
      "deal_lost_reason" => nil
    }
  end

  before do
    allow(RDStationCRMConnector).to receive(:new).and_return(crm)
    allow(crm).to receive(:fetch_deal).and_return(deal)
  end

  describe "#to_csv_string" do
    subject(:csv) { CSV.parse(DealReportExporter.new([deal]).to_csv_string, headers: true) }

    it "gera CSV com cabeçalhos corretos" do
      expect(csv.headers).to include("Deal ID", "Status", "Nome da Negociação", "Produtos", "Total")
    end

    it "preenche linha com dados do deal" do
      row = csv.first
      expect(row["Deal ID"]).to eq("deal_1")
      expect(row["Status"]).to eq("Vendido")
      expect(row["Nome da Negociação"]).to eq("Empresa XPTO - PO-101/26")
    end

    it "extrai número do PO do nome do deal" do
      row = csv.first
      expect(row["PO Gerado"]).to eq("101/26")
    end

    it "formata produtos corretamente" do
      row = csv.first
      expect(row["Produtos"]).to include("Impressora", "1500.0", "3000.0")
    end
  end

  describe "po_number (privado)" do
    let(:exporter) { DealReportExporter.new([]) }

    it "extrai PO do nome" do
      expect(exporter.send(:po_number, "Deal - PO-101/26")).to eq("101/26")
    end

    it "retorna '-' quando não há PO no nome" do
      expect(exporter.send(:po_number, "Deal sem PO")).to eq("-")
    end
  end

  describe "format_products (privado)" do
    let(:exporter) { DealReportExporter.new([]) }

    it "retorna string vazia para lista vazia" do
      expect(exporter.send(:format_products, [])).to eq("")
    end

    it "formata múltiplos produtos separados por ponto-e-vírgula" do
      products = [
        { "name" => "Impressora", "price" => 1500.0, "amount" => 1, "total" => 1500.0 },
        { "name" => "Toner",      "price" => 200.0,  "amount" => 3, "total" => 600.0 }
      ]
      result = exporter.send(:format_products, products)
      expect(result).to include("Impressora", "Toner")
      expect(result.split(";").size).to eq(2)
    end
  end
end
