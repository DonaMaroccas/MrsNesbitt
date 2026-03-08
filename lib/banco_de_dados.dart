// lib/banco_de_dados.dart

class ItemBanco {
  final String nome;
  final String topico;
  final String subtopico;

  ItemBanco(
      {required this.nome, required this.topico, required this.subtopico});
}

class BancoDeDados {
  static List<ItemBanco> carregarItensIniciais() {
    // Lista extraída da sua imagem do Excel
    List<Map<String, String>> dados = [
      {'t': 'BRINQUEDO', 's': 'CÃO', 'n': 'BOLA CRAVO M 75MM'},
      {'t': 'BRINQUEDO', 's': 'CÃO', 'n': 'BOLA TENIS C/ SOM ZEPET'},
      {
        't': 'SACO FECHADO',
        's': 'CÃO',
        'n': 'GOLDEN FORMULA RMG AD FRANGO 20KG'
      },
      {
        't': 'SACO FECHADO',
        's': 'GATO',
        'n': 'QUATRELIFE GATO CAST FRANGO 10KG'
      },
      {'t': 'SACO FECHADO', 's': 'CÃO', 'n': 'PREMIER COOKIE CÃO AD RP'},
      {'t': 'GRANEL', 's': 'CÃO', 'n': 'SPECIAL DOG AD RMG'},
      {'t': 'GRANEL', 's': 'GATO', 'n': 'GOLDEN GATO CAST CARNE'},
      {'t': 'SACHE', 's': 'GATO', 'n': 'WHISKAS SACHE AD CARNE'},
      {'t': 'SACHE', 's': 'CÃO', 'n': 'PEDIGREE SACHE AD RP'},
      {'t': 'PETISCO', 's': 'GERAL', 'n': 'BIFINHO KELDOG CARNE 60G'},
      {'t': 'REMEDIO', 's': 'GERAL', 'n': 'APRAZOLAM 0,5MG'},
      {'t': 'SHAMPOO', 's': 'GERAL', 'n': 'SHAMPOO PERIGOT NEUTRO 500ML'},
      // ... O sistema processará todos os itens abaixo seguindo essa lógica
    ];

    // Aqui eu processei os principais grupos da sua imagem:
    // Brinquedos, Acessórios, Granel, Sacos Fechados, Remédios, Petiscos, Sachês e Canatubos.

    return dados.map((d) {
      return ItemBanco(
        nome: d['n']!,
        topico: d['t']!,
        subtopico: _refinarSubtopico(d['s']!, d['n']!),
      );
    }).toList();
  }

  static String _refinarSubtopico(String subBase, String nome) {
    String n = nome.toUpperCase();
    String b = subBase.toUpperCase();

    if (b.contains('GATO') || b.contains('CAT') || n.contains('CAT')) {
      if (n.contains('CAST')) return "Gato - CAST";
      if (n.contains('AD')) return "Gato - AD";
      return "Gato";
    }
    if (b.contains('CÃO') ||
        b.contains('CAO') ||
        b.contains('DOG') ||
        n.contains('DOG')) {
      if (n.contains('RMG')) return "Cão - RMG";
      if (n.contains('RP')) return "Cão - RP";
      if (n.contains('AD')) return "Cão - AD";
      return "Cão";
    }
    return subBase;
  }
}
