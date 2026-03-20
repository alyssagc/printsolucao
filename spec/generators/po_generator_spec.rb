require 'spec_helper'
require 'tmpdir'

RSpec.describe POGenerator do
  let(:logger) { Logger.new(nil) }
  let(:crm)    { instance_double(RDStationCRMConnector) }

  let(:deal) do
    {
      "id"           => "deal_1",
      "name"         => "Empresa XPTO",
      "win"          => true,
      "amount_total" => 5000.0,
      "created_at"   => "2026-01-10T08:00:00Z",
      "updated_at"   => "2026-03-01T12:30:00Z",
      "deal_stage"   => { "name" => "Pedido" },
      "campaign"     => { "name" => "Dell" },
      "user"         => { "name" => "Vendedor", "email" => "vendedor@print.com" },
      "organization" => {
        "name"    => "Empresa XPTO",
        "address" => "Rua A, 1",
        "user"    => { "name" => "Resp", "email" => "resp@xpto.com" },
        "organization_segments" => [{ "name" => "Educação" }]
      },
      "deal_products" => [
        { "name" => "Impressora", "amount" => 2, "price" => 1500.0, "total" => 3000.0 }
      ],
      "deal_custom_fields" => [
        { "custom_field" => { "label" => "Observação" }, "value" => "Urgente" }
      ]
    }
  end

  def build_generator(deals, po_content: "PO-100/25")
    dir = Dir.mktmpdir
    po_file = File.join(dir, "last_po.txt")
    File.write(po_file, po_content)

    stub_const("POGenerator::LAST_PO_FILE", po_file)
    stub_const("POGenerator::BACKUP_PO_FILE", File.join(dir, "last_po.txt.bak"))
    stub_const("POGenerator::TEMPLATE_PATH", "templates/emails/po_email.html.erb")

    POGenerator.new(deals, logger: logger, crm_connector: crm)
  end

  describe "#po_hash (via process_pos)" do
    it "mapeia campos do deal corretamente" do
      allow(crm).to receive(:update_deal)
      allow(crm).to receive(:create_task).and_return({ "id" => "t1", "subject" => "Entrar com o Pedido" })

      mailer = instance_double(SmtpMailer)
      allow(SmtpMailer).to receive(:new).and_return(mailer)
      allow(mailer).to receive(:mail_po_infos)

      generator = build_generator([deal])

      # acessa po_hash indiretamente pelo resultado do process_pos
      po = generator.send(:po_hash, deal)

      expect(po["deal_id"]).to eq("deal_1")
      expect(po["deal_name"]).to eq("Empresa XPTO")
      expect(po["status"]).to eq("Vendido")
      expect(po["campanha"]).to eq("Dell")
      expect(po.dig("owner", "email")).to eq("vendedor@print.com")
      expect(po["products"].first["name"]).to eq("Impressora")
      expect(po["custom_fields"]["Observação"]).to eq("Urgente")
    end
  end

  describe "#next_po_number" do
    it "incrementa sequência e formata corretamente" do
      allow(crm).to receive(:update_deal)
      allow(crm).to receive(:create_task).and_return({ "id" => "t1", "subject" => "s" })

      mailer = instance_double(SmtpMailer)
      allow(SmtpMailer).to receive(:new).and_return(mailer)
      allow(mailer).to receive(:mail_po_infos)

      generator = build_generator([], po_content: "PO-99/25")
      year = Time.now.year.to_s[2..3]

      expect(generator.send(:next_po_number)).to eq("PO-100/#{year}")
      expect(generator.send(:next_po_number)).to eq("PO-101/#{year}")
    end
  end

  describe "#safe_format_date" do
    let(:generator) { build_generator([]) }

    it "formata data válida" do
      result = generator.send(:safe_format_date, "2026-03-10T08:00:00Z")
      expect(result).to match(/\d{2}\/\d{2}\/\d{4}/)
    end

    it "retorna '—' para data inválida" do
      expect(generator.send(:safe_format_date, "não-é-data")).to eq("—")
    end

    it "retorna '—' para nil" do
      expect(generator.send(:safe_format_date, nil)).to eq("—")
    end
  end

  describe "#process_pos" do
    it "conta sucesso quando tudo funciona" do
      mailer = instance_double(SmtpMailer)
      allow(SmtpMailer).to receive(:new).and_return(mailer)
      allow(mailer).to receive(:mail_po_infos)
      allow(crm).to receive(:update_deal)
      allow(crm).to receive(:create_task).and_return({ "id" => "t1", "subject" => "s" })

      generator = build_generator([deal])
      result = generator.process_pos

      expect(result[:total]).to eq(1)
      expect(result[:success]).to eq(1)
      expect(result[:failures]).to be_empty
    end

    it "registra falha quando CRM lança erro" do
      mailer = instance_double(SmtpMailer)
      allow(SmtpMailer).to receive(:new).and_return(mailer)
      allow(mailer).to receive(:mail_po_infos)
      allow(crm).to receive(:update_deal).and_raise("timeout")
      allow(crm).to receive(:create_task).and_return({ "id" => "t1", "subject" => "s" })

      generator = build_generator([deal])
      result = generator.process_pos

      expect(result[:failures]).not_to be_empty
      expect(result[:success]).to eq(0)
    end
  end
end
