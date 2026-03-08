class Pedido {
  String nomeCliente;
  String telefone;
  String endereco;
  String pontoReferencia;
  String formaPagamento;
  String? precisaTroco;
  String? valorTroco;
  String localRetirada;
  String horarioEntrega;
  String pedido;

  Pedido({
    required this.nomeCliente,
    required this.telefone,
    required this.endereco,
    required this.pontoReferencia,
    required this.formaPagamento,
    this.precisaTroco,
    this.valorTroco,
    required this.localRetirada,
    required this.horarioEntrega,
    required this.pedido,
  });

  String gerarMensagem() {
    String msg = "";
    msg += "👤 Cliente: $nomeCliente\n";
    msg += "📞 Telefone: $telefone\n\n";
    msg += "📦 Pedido: $pedido\n";
    msg += "📍 Retirada: $localRetirada\n\n";
    msg +=
        "💰 Valor: ${valorTotal.isNotEmpty ? 'R\$ $valorTotal' : 'A combinar'}\n";
    msg += "💳 Pagamento: $formaPagamento";

    if (precisaTroco == "Sim" && valorTroco != null && valorTroco!.isNotEmpty) {
      msg += "\n💵 Troco para: R\$ $valorTroco";
    }

    msg += "\n\n🏠 Endereço: $endereco";
    msg += "\n📍 Referência: $pontoReferencia";

    if (horarioEntrega.isNotEmpty) {
      msg += "\n\n⏰ Horário de entrega: $horarioEntrega";
    }

    return msg;
  }

  String get valorTotal {
    // Extrair valor do pedido se estiver no formato "R$ XX,XX"
    RegExp regex = RegExp(r'R\$\s*([\d,]+)');
    Match? match = regex.firstMatch(pedido);
    if (match != null) {
      return match.group(1)!;
    }
    return "";
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nomeCliente,
      'telefone': telefone,
      'endereco': endereco,
      'referencia': pontoReferencia,
      'pagamento': formaPagamento,
      'precisaTroco': precisaTroco,
      'valorTroco': valorTroco,
      'retirada': localRetirada,
      'horario': horarioEntrega,
      'pedido': pedido,
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      nomeCliente: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      endereco: map['endereco'] ?? '',
      pontoReferencia: map['referencia'] ?? '',
      formaPagamento: map['pagamento'] ?? '',
      precisaTroco: map['precisaTroco'],
      valorTroco: map['valorTroco'],
      localRetirada: map['retirada'] ?? '',
      horarioEntrega: map['horario'] ?? '',
      pedido: map['pedido'] ?? '',
    );
  }
}
