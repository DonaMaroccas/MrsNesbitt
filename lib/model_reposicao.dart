class Reposicao {
  String? id;
  String produto;
  String quantidade;
  String observacao;
  bool concluida;
  DateTime dataCriacao;

  Reposicao({
    this.id,
    required this.produto,
    required this.quantidade,
    this.observacao = '',
    this.concluida = false,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produto': produto,
      'quantidade': quantidade,
      'observacao': observacao,
      'concluida': concluida,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory Reposicao.fromMap(Map<String, dynamic> map) {
    return Reposicao(
      id: map['id'],
      produto: map['produto'] ?? '',
      quantidade: map['quantidade'] ?? '',
      observacao: map['observacao'] ?? '',
      concluida: map['concluida'] ?? false,
      dataCriacao: map['dataCriacao'] != null
          ? DateTime.parse(map['dataCriacao'])
          : DateTime.now(),
    );
  }
}
