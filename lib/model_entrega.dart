class Cliente {
  String id;
  String nome;
  String telefone;
  String endereco;
  String pontoReferencia;
  DateTime dataCadastro;

  Cliente({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.endereco,
    required this.pontoReferencia,
    required this.dataCadastro,
  });

  String gerarResumo() {
    return "$nome - $telefone";
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'endereco': endereco,
      'referencia': pontoReferencia,
      'data': dataCadastro.toIso8601String(),
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      endereco: map['endereco'] ?? '',
      pontoReferencia: map['referencia'] ?? '',
      dataCadastro:
          map['data'] != null ? DateTime.parse(map['data']) : DateTime.now(),
    );
  }
}

// Classe para representar um item do pedido
class ItemPedido {
  String descricao;
  String lojaRetirada;
  int ordem;

  ItemPedido({
    required this.descricao,
    required this.lojaRetirada,
    required this.ordem,
  });

  Map<String, dynamic> toMap() {
    return {
      'descricao': descricao,
      'loja': lojaRetirada,
      'ordem': ordem,
    };
  }

  factory ItemPedido.fromMap(Map<String, dynamic> map) {
    return ItemPedido(
      descricao: map['descricao'] ?? '',
      lojaRetirada: map['loja'] ?? '',
      ordem: map['ordem'] ?? 0,
    );
  }
}

class Entrega {
  String id;
  String clienteId;
  String nomeCliente;
  String telefone;
  String pedido;
  String localRetirada;
  String valor;
  String formaPagamento;
  String precisaTroco;
  String? valorTroco;
  String endereco;
  String pontoReferencia;
  String horarioEntrega;
  String observacoes;
  List<ItemPedido> itens;
  DateTime dataCriacao;

  Entrega({
    required this.id,
    required this.clienteId,
    required this.nomeCliente,
    required this.telefone,
    required this.pedido,
    required this.localRetirada,
    required this.valor,
    required this.formaPagamento,
    required this.precisaTroco,
    this.valorTroco,
    required this.endereco,
    required this.pontoReferencia,
    required this.horarioEntrega,
    required this.observacoes,
    required this.itens,
    required this.dataCriacao,
  });

  String gerarMensagem() {
    String msg = "";
    msg += "👤 Cliente: $nomeCliente\n";
    msg += "📞 Telefone: $telefone\n\n";

    // Mostrar itens com suas lojas
    if (itens.isNotEmpty) {
      msg += "📦 Pedido:\n";
      for (int i = 0; i < itens.length; i++) {
        String loja = itens[i].lojaRetirada.isNotEmpty
            ? " (${itens[i].lojaRetirada})"
            : "";
        msg += "  ${i + 1}. ${itens[i].descricao}$loja\n";
      }
    } else {
      msg += "📦 Pedido: $pedido\n";
      if (localRetirada.isNotEmpty) {
        msg += "📍 Retirada: $localRetirada\n";
      }
    }

    msg += "\n💰 Valor: ${valor.isNotEmpty ? 'R\$ $valor' : 'A combinar'}\n";
    msg += "💳 Pagamento: $formaPagamento";

    if (precisaTroco == "Sim" && valorTroco != null && valorTroco!.isNotEmpty) {
      msg += "\n💵 Troco para: R\$ $valorTroco";
    }

    msg += "\n\n🏠 Endereço: $endereco";
    msg += "\n📍 Referência: $pontoReferencia";

    if (horarioEntrega.isNotEmpty) {
      msg += "\n\n⏰ Horário de entrega: $horarioEntrega";
    }

    if (observacoes.isNotEmpty) {
      msg += "\n\n📝 Observações: $observacoes";
    }

    return msg;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clienteId': clienteId,
      'nome': nomeCliente,
      'telefone': telefone,
      'pedido': pedido,
      'retirada': localRetirada,
      'valor': valor,
      'pagamento': formaPagamento,
      'precisaTroco': precisaTroco,
      'valorTroco': valorTroco,
      'endereco': endereco,
      'referencia': pontoReferencia,
      'horario': horarioEntrega,
      'observacoes': observacoes,
      'itens': itens.map((e) => e.toMap()).toList(),
      'data': dataCriacao.toIso8601String(),
    };
  }

  factory Entrega.fromMap(Map<String, dynamic> map) {
    List<ItemPedido> itens = [];
    if (map['itens'] != null) {
      itens = List<Map<String, dynamic>>.from(map['itens'])
          .map((e) => ItemPedido.fromMap(e))
          .toList();
    }
    return Entrega(
      id: map['id'] ?? '',
      clienteId: map['clienteId'] ?? '',
      nomeCliente: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      pedido: map['pedido'] ?? '',
      localRetirada: map['retirada'] ?? '',
      valor: map['valor'] ?? '',
      formaPagamento: map['pagamento'] ?? '',
      precisaTroco: map['precisaTroco'] ?? 'Não',
      valorTroco: map['valorTroco'],
      endereco: map['endereco'] ?? '',
      pontoReferencia: map['referencia'] ?? '',
      horarioEntrega: map['horario'] ?? '',
      observacoes: map['observacoes'] ?? '',
      itens: itens,
      dataCriacao:
          map['data'] != null ? DateTime.parse(map['data']) : DateTime.now(),
    );
  }
}
