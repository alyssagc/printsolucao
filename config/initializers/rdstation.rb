RD_CONFIG = {
  token: ENV.fetch("RD_TOKEN") { raise "Missing RD_TOKEN in .env" },
  id_pedido_enviado: ENV.fetch("ID_PEDIDO_ENVIADO")
}
