RD_CONFIG = {
  token: ENV.fetch("RD_TOKEN") { raise "Missing RD_TOKEN in .env" },
  id_pedido_enviado: ENV.fetch("ID_PEDIDO_ENVIADO") { raise "Missing ID_PEDIDO_ENVIADO in .env" },
  id_responsible_po_task: ENV.fetch("ID_RESPONSIBLE_PO_TASK") { raise "Missing ID_RESPONSIBLE_PO_TASK in .env" }
}
