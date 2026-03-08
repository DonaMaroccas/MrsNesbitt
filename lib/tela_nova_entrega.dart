import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'model_entrega.dart';

// Parser para identificar itens do pedido baseados em números
List<ItemPedido> _parsearItens(String texto) {
  List<ItemPedido> itens = [];
  if (texto.trim().isEmpty) return itens;

  // Divide o texto em partes baseadas em números no início
  RegExp regex = RegExp(r'(\d+)');
  Iterable<Match> matches = regex.allMatches(texto);

  // Se não encontrou números, retorna o texto como um único item
  if (matches.isEmpty) {
    return [
      ItemPedido(
        descricao: texto.trim(),
        lojaRetirada: '',
        ordem: 0,
      )
    ];
  }

  // Converte para lista de posições
  List<int> positions = [];
  for (Match m in matches) {
    positions.add(m.start);
  }

  int ordem = 0;
  for (int i = 0; i < positions.length; i++) {
    int startPos = positions[i];
    int endPos = (i < positions.length - 1) ? positions[i + 1] : texto.length;

    String part = texto.substring(startPos, endPos).trim();

    if (part.isNotEmpty) {
      // Verifica se começa com número
      Match? numMatch = RegExp(r'^(\d+)(.*)$').firstMatch(part);
      if (numMatch != null) {
        String numero = numMatch.group(1)!;
        String descricao = numMatch.group(2)!.trim();

        if (descricao.isNotEmpty) {
          itens.add(ItemPedido(
            descricao: '$numero $descricao'.trim(),
            lojaRetirada: '',
            ordem: ordem++,
          ));
        } else {
          // Se só tem número, pega um pouco mais de contexto
          String context = texto
              .substring(startPos, min(startPos + 15, texto.length))
              .trim();
          if (context.isNotEmpty) {
            itens.add(ItemPedido(
              descricao: context,
              lojaRetirada: '',
              ordem: ordem++,
            ));
          }
        }
      }
    }
  }

  // Se não encontrou nenhum item, retorna o texto como um único item
  if (itens.isEmpty) {
    itens.add(ItemPedido(
      descricao: texto.trim(),
      lojaRetirada: '',
      ordem: 0,
    ));
  }

  return itens;
}

// Formatter para limitar telefone a 9 dígitos após DDD
class _TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String texto = newValue.text;

    // Remove todos os não numéricos
    String numeros = texto.replaceAll(RegExp(r'[^0-9]'), '');

    // Limita a 11 dígitos (2 DDD + 9 telefone)
    if (numeros.length > 11) {
      numeros = numeros.substring(0, 11);
    }

    // Formata o telefone
    String formatted = _formatarTelefone(numeros);

    // Ajusta a posição do cursor
    int cursorOffset = formatted.length;
    if (oldValue.text.length > newValue.text.length) {
      // Usuário está apagando
      cursorOffset = oldValue.selection.baseOffset;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  static String _formatarTelefone(String numeros) {
    if (numeros.isEmpty) return '';
    if (numeros.length <= 2) {
      return '(${numeros.substring(0, numeros.length)}';
    }
    if (numeros.length <= 6) {
      return '(${numeros.substring(0, 2)})${numeros.substring(2)}';
    }
    if (numeros.length <= 10) {
      return '(${numeros.substring(0, 2)})${numeros.substring(2, 6)}-${numeros.substring(6)}';
    }
    // 11 dígitos ou mais
    return '(${numeros.substring(0, 2)})${numeros.substring(2, 7)}-${numeros.substring(7, 11)}';
  }
}

class TelaNovaEntrega extends StatefulWidget {
  const TelaNovaEntrega({super.key});

  @override
  State<TelaNovaEntrega> createState() => _TelaNovaEntregaState();
}

class _TelaNovaEntregaState extends State<TelaNovaEntrega> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _pedidoController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _horarioController = TextEditingController();
  final TextEditingController _trocoController = TextEditingController();
  final TextEditingController _lojaController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  String _localRetirada = "";
  String _formaPagamento = "PIX";
  String _precisaTroco = "Não";
  bool _pagamentoNaEntrega = false; // Checkbox para pagamento na entrega
  bool _entregarAmanha = false; // Flag para indicar entrega amanhã
  String? _clienteIdSelecionado;
  bool _usarItensPorLoja = true; // Controla se usa itens com loja específica
  bool _dinheiroJaPago =
      false; // Para Dinheiro: true = já pago, false = pagar na entrega
  final TextEditingController _buscaClienteController = TextEditingController();
  List<Cliente> _clientesFiltrados = [];
  bool _mostrarSugestoesCliente = false;
  bool _naoTemTelefone = false;

  List<String> _lojas = ["Loja"];
  List<Cliente> _clientes = [];
  List<ItemPedido> _itensPedido = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _horarioController.addListener(_formatarHorario);
    // Adicionar listeners para atualizar a mensagem em tempo real
    _nomeController.addListener(() => setState(() {}));
    _telefoneController.addListener(() => setState(() {}));
    _pedidoController.addListener(() {
      if (_usarItensPorLoja) {
        _itensPedido = _parsearItens(_pedidoController.text);
      } else {
        _itensPedido = [];
      }
      setState(() {});
    });
    _valorController.addListener(() => setState(() {}));
    _enderecoController.addListener(() => setState(() {}));
    _referenciaController.addListener(() => setState(() {}));
    _trocoController.addListener(() => setState(() {}));
    _observacoesController.addListener(() => setState(() {}));
    _buscaClienteController.addListener(_filtrarClientes);
  }

  void _filtrarClientes() {
    final termo = _buscaClienteController.text.toLowerCase();
    setState(() {
      if (termo.isEmpty) {
        _clientesFiltrados = [];
        _mostrarSugestoesCliente = false;
      } else {
        _clientesFiltrados = _clientes
            .where((c) => c.nome.toLowerCase().contains(termo))
            .take(5)
            .toList();
        _mostrarSugestoesCliente = _clientesFiltrados.isNotEmpty;
      }
    });
  }

  void _formatarHorario() {
    final text = _horarioController.text;

    // Se está vazio, deixar livre
    if (text.isEmpty) return;

    // Se tem apenas ":", limpar
    if (text == ":") {
      _horarioController.clear();
      return;
    }

    // Contar apenas dígitos
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Se não há dígitos, deixar o texto como está (pode ser que usuário está apagando)
    if (digits.isEmpty) return;

    // Limitar a 4 dígitos
    final truncatedDigits = digits.length > 4 ? digits.substring(0, 4) : digits;

    // Formatar como HH:MM
    String formatted;
    if (truncatedDigits.length >= 2) {
      formatted =
          '${truncatedDigits.substring(0, 2)}:${truncatedDigits.substring(2)}';
    } else {
      formatted = truncatedDigits;
    }

    // Só atualizar se realmente mudou
    if (formatted != text) {
      _horarioController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _toggleAmanha() {
    setState(() {
      _entregarAmanha = !_entregarAmanha;
    });
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? lojasSalvas = prefs.getStringList('lojas');
    if (lojasSalvas != null && lojasSalvas.isNotEmpty) {
      setState(() => _lojas = lojasSalvas);
    }
    String? clientesSalvos = prefs.getString('clientes');
    if (clientesSalvos != null) {
      List decoded = jsonDecode(clientesSalvos);
      setState(() {
        _clientes = decoded.map((c) => Cliente.fromMap(c)).toList();
      });
    }
  }

  Future<void> _salvarLojas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('lojas', _lojas);
  }

  Future<void> _salvarClientes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'clientes', jsonEncode(_clientes.map((c) => c.toMap()).toList()));
  }

  void _excluirCliente(Cliente cliente) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Excluir Cliente",
            style: TextStyle(color: Colors.white)),
        content: Text("Tem certeza que deseja excluir ${cliente.nome}?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _clientes.removeWhere((c) => c.id == cliente.id);
                _salvarClientes();
                // Se o cliente excluído era o selecionado, limpar campos
                if (_clienteIdSelecionado == cliente.id) {
                  _clienteIdSelecionado = null;
                  _nomeController.clear();
                  _telefoneController.clear();
                  _enderecoController.clear();
                  _referenciaController.clear();
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _gerarId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String? _validarTelefone(String? value) {
    // Se não tem telefone, não precisa validar
    if (_naoTemTelefone) {
      return null;
    }
    if (value == null || value.isEmpty) {
      return "Telefone é obrigatório";
    }
    String numeros = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length < 10) {
      return "Telefone inválido";
    }
    return null;
  }

  String? _validarNome(String? value) {
    if (value == null || value.isEmpty) {
      return "Nome é obrigatório";
    }
    return null;
  }

  String? _validarEndereco(String? value) {
    if (value == null || value.isEmpty) {
      return "Endereço é obrigatório";
    }
    return null;
  }

  String? _validarReferencia(String? value) {
    if (value == null || value.isEmpty) {
      return "Referência é obrigatória";
    }
    return null;
  }

  String? _validarValorTotal(String? value) {
    if (value == null || value.isEmpty) {
      return "Valor Total é obrigatório";
    }
    // Verificar se é um valor numérico válido
    try {
      double.parse(value.replaceAll(',', '.'));
    } catch (e) {
      return "Valor inválido";
    }
    return null;
  }

  String? _validarTroco(String? value) {
    // Só é obrigatório se _precisaTroco == "Sim"
    if (_precisaTroco == "Sim") {
      if (value == null || value.isEmpty) {
        return "Valor do troco é obrigatório";
      }

      // Verificar se é um valor numérico válido
      double troco;
      try {
        troco = double.parse(value.replaceAll(',', '.'));
      } catch (e) {
        return "Valor inválido";
      }

      // Obter o valor total
      double total = 0;
      try {
        total = double.parse(_valorController.text.replaceAll(',', '.'));
      } catch (e) {
        // Se o valor total não for válido, não validar
      }

      // Verificar se o troco é menor que o total
      if (troco < total) {
        return "Troco não pode ser menor que o total";
      }
    }
    return null;
  }

  String? _validarPedido(String? value) {
    if (value == null || value.isEmpty) {
      return "Pedido é obrigatório";
    }
    return null;
  }

  String? _validarHorario(String? value) {
    if (value == null || value.isEmpty) return null;
    List<String> parts = value.split(":");
    if (parts.length < 2) {
      return "Formato inválido (HH:MM)";
    }
    int hora = int.tryParse(parts[0]) ?? -1;
    int minuto = int.tryParse(parts[1]) ?? -1;
    if (hora < 0 || hora > 23) {
      return "Hora deve ser entre 00 e 23";
    }
    if (minuto < 0 || minuto > 59) {
      return "Minuto deve ser entre 00 e 59";
    }
    return null;
  }

  // Gera a mensagem em tempo real baseada nos dados preenchidos
  String _gerarMensagemPreview() {
    String msg = "";
    if (_nomeController.text.isNotEmpty) {
      msg += "👤 Cliente: ${_nomeController.text}\n";
    }
    if (_telefoneController.text.isNotEmpty) {
      msg += "📞 Telefone: ${_telefoneController.text}\n\n";
    }
    if (_pedidoController.text.isNotEmpty) {
      // Se usar itens com loja específica, mostrar cada um com sua loja
      if (_usarItensPorLoja && _itensPedido.isNotEmpty) {
        msg += "📦 Pedido:\n";
        for (int i = 0; i < _itensPedido.length; i++) {
          final item = _itensPedido[i];
          final loja =
              item.lojaRetirada.isNotEmpty ? item.lojaRetirada : _lojas.first;
          msg += "${item.descricao} ($loja)\n";
        }
      } else {
        msg += "📦 Pedido: ${_pedidoController.text}\n";
      }
    }
    if (_localRetirada.isNotEmpty) {
      msg += "📍 Retirada: ${_localRetirada}\n\n";
    }
    if (_valorController.text.isNotEmpty) {
      msg += "💰 Valor: R\$ ${_valorController.text}\n";
    }
    // Mostrar forma de pagamento baseada no checkbox
    if (_pagamentoNaEntrega) {
      msg += "💳 Pagamento: Pagamento na Entrega";
    } else if (_isPagamentoDinheiro) {
      // Para Dinheiro, mostrar se é já pago ou pagar na entrega
      if (_dinheiroJaPago) {
        msg += "💳 Pagamento: Dinheiro - Já Pago";
      } else {
        msg += "💳 Pagamento: Dinheiro - Pagar na Entrega";
      }
    } else if (_formaPagamento == "Dinheiro") {
      // Dinheiro na entrega já é pagamento na entrega
      msg += "💳 Pagamento: $_formaPagamento";
    } else {
      msg += "💳 Pagamento: Já Pago";
    }
    if (_isPagamentoDinheiro &&
        !_dinheiroJaPago &&
        _precisaTroco == "Sim" &&
        _trocoController.text.isNotEmpty) {
      msg += "\n💵 Troco para: R\$ ${_trocoController.text}";
    }
    if (_enderecoController.text.isNotEmpty) {
      msg += "\n\n🏠 Endereço: ${_enderecoController.text}";
    }
    if (_referenciaController.text.isNotEmpty) {
      msg += "\n📍 Referência: ${_referenciaController.text}";
    }
    if (_horarioController.text.isNotEmpty || _entregarAmanha) {
      String horarioMsg = "";
      if (_entregarAmanha) {
        horarioMsg = "entregar amanha";
        if (_horarioController.text.isNotEmpty) {
          horarioMsg += " às ${_horarioController.text}";
        }
      } else {
        horarioMsg = _horarioController.text;
      }
      msg += "\n\n⏰ $horarioMsg";
    }
    if (_observacoesController.text.isNotEmpty) {
      msg += "\n\n📝 Observações: ${_observacoesController.text}";
    }
    return msg;
  }

  // Input formatter para telefone - limita a 9 dígitos após DDD
  List<TextInputFormatter> _telefoneInputFormatters() {
    return [
      _TelefoneInputFormatter(),
    ];
  }

  void _dialogNovaLoja() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Nova Loja", style: TextStyle(color: Colors.white)),
        content: TextField(
            controller: _lojaController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: "Nome da Loja",
                labelStyle: TextStyle(color: Color(0xFF757575)))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (_lojaController.text.isNotEmpty) {
                setState(() {
                  _lojas.add(_lojaController.text);
                  _salvarLojas();
                });
                Navigator.pop(ctx);
                _lojaController.clear();
              }
            },
            child: const Text("SALVAR"),
          ),
        ],
      ),
    );
  }

  void _selecionarCliente(Cliente cliente) {
    setState(() {
      _clienteIdSelecionado = cliente.id;
      _nomeController.text = cliente.nome;
      _telefoneController.text = cliente.telefone;
      _enderecoController.text = cliente.endereco;
      _referenciaController.text = cliente.pontoReferencia;
    });
  }

  void _dialogNovoCliente() {
    final nomeCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final refCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title:
            const Text("Novo Cliente", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: nomeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: "Nome *",
                    labelStyle: TextStyle(color: Colors.green))),
            const SizedBox(height: 10),
            TextField(
                controller: telCtrl,
                style: const TextStyle(color: Colors.white),
                inputFormatters: _telefoneInputFormatters(),
                decoration: const InputDecoration(
                    labelText: "Telefone *",
                    labelStyle: TextStyle(color: Colors.green))),
            const SizedBox(height: 10),
            TextField(
                controller: endCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: "Endereço",
                    labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 10),
            TextField(
                controller: refCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: "Ponto de referência",
                    labelStyle: TextStyle(color: Colors.white70))),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (nomeCtrl.text.isNotEmpty && telCtrl.text.isNotEmpty) {
                final novoCliente = Cliente(
                    id: _gerarId(),
                    nome: nomeCtrl.text,
                    telefone: telCtrl.text,
                    endereco: endCtrl.text,
                    pontoReferencia: refCtrl.text,
                    dataCadastro: DateTime.now());
                setState(() {
                  _clientes.add(novoCliente);
                  _salvarClientes();
                });
                Navigator.pop(ctx);
                _selecionarCliente(novoCliente);
              }
            },
            child: const Text("SALVAR"),
          ),
        ],
      ),
    );
  }

  bool get _isPagamentoDinheiro {
    return _formaPagamento == "Dinheiro";
  }

  // Função para criar título de seção
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            color: Color(0xFF757575),
            fontWeight: FontWeight.bold,
            fontSize: 16),
      ),
    );
  }

  // Função genérica para criar campos de texto
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
      ),
    );
  }

  // Função para criar campo multilinha
  Widget _buildTextFieldMultiline(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: 4,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
      ),
    );
  }

  void _enviarPedido() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      // Salvar/atualizar cliente automaticamente
      String? clientesSalvos = prefs.getString('clientes');
      List<Cliente> clientes = [];
      if (clientesSalvos != null) {
        List decoded = jsonDecode(clientesSalvos);
        clientes = decoded.map((c) => Cliente.fromMap(c)).toList();
      }

      // Verificar se o cliente já existe pelo nome e telefone
      final nomeCliente = _nomeController.text.trim();
      // Se não tem telefone, usa string vazia para busca
      String telefoneCliente;
      if (_naoTemTelefone) {
        telefoneCliente = '';
      } else {
        telefoneCliente =
            _telefoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      }

      Cliente? clienteExistente;
      for (var c in clientes) {
        String cTelefone =
            _naoTemTelefone ? '' : c.telefone.replaceAll(RegExp(r'[^0-9]'), '');
        if (c.nome.toLowerCase() == nomeCliente.toLowerCase() &&
            cTelefone == telefoneCliente) {
          clienteExistente = c;
          break;
        }
      }

      if (clienteExistente != null) {
        // Atualizar cliente existente
        clienteExistente.endereco = _enderecoController.text.trim();
        clienteExistente.pontoReferencia = _referenciaController.text.trim();
        if (!_naoTemTelefone) {
          clienteExistente.telefone = _telefoneController.text.trim();
        }
      } else {
        // Criar novo cliente
        final novoCliente = Cliente(
          id: _gerarId(),
          nome: nomeCliente,
          telefone: _naoTemTelefone ? '' : _telefoneController.text.trim(),
          endereco: _enderecoController.text.trim(),
          pontoReferencia: _referenciaController.text.trim(),
          dataCadastro: DateTime.now(),
        );
        clientes.add(novoCliente);
        clienteExistente = novoCliente;
      }

      // Salvar clientes atualizados
      await prefs.setString(
          'clientes', jsonEncode(clientes.map((c) => c.toMap()).toList()));

      // Recarregar clientes na memória
      setState(() {
        _clientes = clientes;
      });

      String? entregasSalvas = prefs.getString('entregas');

      final novaEntrega = Entrega(
          id: _gerarId(),
          clienteId: clienteExistente.id,
          nomeCliente: _nomeController.text,
          telefone: _telefoneController.text,
          pedido: _pedidoController.text,
          localRetirada: _localRetirada,
          valor: _valorController.text,
          formaPagamento: _isPagamentoDinheiro
              ? (_dinheiroJaPago
                  ? "Dinheiro - Já Pago"
                  : "Dinheiro - Pagar na Entrega")
              : _formaPagamento,
          endereco: _enderecoController.text,
          pontoReferencia: _referenciaController.text,
          horarioEntrega: _horarioController.text,
          precisaTroco: _precisaTroco,
          valorTroco:
              _trocoController.text.isNotEmpty ? _trocoController.text : null,
          observacoes: _observacoesController.text,
          itens: _itensPedido,
          dataCriacao: DateTime.now());

      List<dynamic> entregas = [];
      if (entregasSalvas != null) {
        entregas = jsonDecode(entregasSalvas);
      }
      entregas.insert(0, novaEntrega.toMap());
      await prefs.setString('entregas', jsonEncode(entregas));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Pedido salvo com sucesso!")));
        Navigator.pop(context);
      }
    }
  }

  void _enviarWhatsapp() async {
    String msg = _gerarMensagemPreview();

    // Remove quebras de linha extras e formata para WhatsApp
    msg = msg.replaceAll('\n\n', '\n');

    // Abre o WhatsApp sem número específico - usuário escolhe quem enviar
    String url = "https://wa.me/?text=${Uri.encodeFull(msg)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));

      // Limpar campos após enviar para WhatsApp
      setState(() {
        _nomeController.clear();
        _telefoneController.clear();
        _pedidoController.clear();
        _valorController.clear();
        _enderecoController.clear();
        _referenciaController.clear();
        _horarioController.clear();
        _trocoController.clear();
        _observacoesController.clear();
        _buscaClienteController.clear();
        _clienteIdSelecionado = null;
        _localRetirada = '';
        _itensPedido = [];
        _entregarAmanha = false;
        _pagamentoNaEntrega = false;
        _clientesFiltrados = [];
        _mostrarSugestoesCliente = false;
        _naoTemTelefone = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erro ao abrir WhatsApp")));
      }
    }
  }

  List<String> get _formasPagamento {
    List<String> formas = [
      "PIX",
      "Cartão de Crédito",
      "Cartão de Débito",
      "Dinheiro"
    ];
    // Evitar duplicatas
    return formas.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Novo Pedido"),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle("👤 Cliente"),
            // Campo de busca de cliente
            TextField(
              controller: _buscaClienteController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Colors.white10,
                hintText: "Buscar cliente pelo nome...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onTap: () {
                setState(() {
                  _mostrarSugestoesCliente = _clientesFiltrados.isNotEmpty;
                });
              },
            ),
            // Lista de sugestões de clientes
            if (_mostrarSugestoesCliente) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _clientesFiltrados.length,
                  itemBuilder: (context, index) {
                    final cliente = _clientesFiltrados[index];
                    return ListTile(
                      leading: const Icon(Icons.person, color: Colors.green),
                      title: Text(cliente.nome,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        "${cliente.telefone} - ${cliente.endereco}",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _selecionarCliente(cliente);
                        _buscaClienteController.text = cliente.nome;
                        setState(() {
                          _mostrarSugestoesCliente = false;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(_nomeController, "Nome do Cliente", Icons.person,
                validator: _validarNome),
            const SizedBox(height: 10),
            // Campo telefone com opção "Não tem número"
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                      _telefoneController, "Telefone", Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: _validarTelefone,
                      inputFormatters: _telefoneInputFormatters()),
                ),
              ],
            ),
            // Botão "Não tem número"
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _naoTemTelefone = !_naoTemTelefone;
                  if (_naoTemTelefone) {
                    _telefoneController.clear();
                  }
                });
              },
              icon: Icon(
                _naoTemTelefone
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                color: _naoTemTelefone ? Colors.green : Colors.grey,
              ),
              label: Text(
                "Não tem número",
                style: TextStyle(
                  color: _naoTemTelefone ? Colors.green : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField(_enderecoController, "Endereço *", Icons.home,
                validator: _validarEndereco),
            const SizedBox(height: 10),
            _buildTextField(_referenciaController, "Ponto de Referência *",
                Icons.location_on,
                validator: _validarReferencia),
            _buildSectionTitle("📦 Pedido"),
            _buildTextFieldMultiline(
                _pedidoController, "Descrição do Pedido", Icons.shopping_cart,
                validator: _validarPedido),
            // Mostrar itens identificados com seleção de loja
            if (_itensPedido.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.format_list_numbered,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text("Itens com loja específica",
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Switch(
                          value: _usarItensPorLoja,
                          activeColor: Colors.green,
                          onChanged: (v) {
                            setState(() {
                              _usarItensPorLoja = v;
                              if (v) {
                                _itensPedido =
                                    _parsearItens(_pedidoController.text);
                              } else {
                                _itensPedido = [];
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._itensPedido.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.descricao,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: item.lojaRetirada.isEmpty
                                  ? null
                                  : item.lojaRetirada,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                              hint: const Text("Selecionar loja",
                                  style: TextStyle(fontSize: 12)),
                              items: _lojas
                                  .map((loja) => DropdownMenuItem(
                                      value: loja, child: Text(loja)))
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _itensPedido[index].lojaRetirada = v ?? '';
                                });
                              },
                            ),
                            if (index < _itensPedido.length - 1)
                              const Divider(color: Colors.white24),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
            _buildTextField(
                _valorController, "Valor Total *", Icons.attach_money,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _validarValorTotal),
            _buildSectionTitle("📍 Retirada"),
            DropdownButtonFormField<String>(
              value: _localRetirada.isEmpty ? null : _localRetirada,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_on, color: Colors.green),
                  filled: true,
                  fillColor: Colors.white10),
              hint: const Text("Selecione a loja"),
              items: [
                ..._lojas.map(
                    (loc) => DropdownMenuItem(value: loc, child: Text(loc))),
                const DropdownMenuItem(
                    value: "ADD_NEW",
                    child: Row(children: [
                      Icon(Icons.add, color: Colors.green),
                      SizedBox(width: 8),
                      Text("ADICIONAR LOJA",
                          style: TextStyle(color: Colors.green))
                    ])),
              ],
              onChanged: (v) {
                if (v == "ADD_NEW")
                  _dialogNovaLoja();
                else
                  setState(() => _localRetirada = v!);
              },
            ),
            const SizedBox(height: 16),
            _buildSectionTitle("💰 Pagamento"),
            DropdownButtonFormField<String>(
              value: _formaPagamento,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.payment, color: Colors.green),
                  filled: true,
                  fillColor: Colors.white10),
              items: _formasPagamento
                  .map((fp) => DropdownMenuItem(value: fp, child: Text(fp)))
                  .toList(),
              onChanged: (v) => setState(() => _formaPagamento = v!),
            ),
            // Checkbox para pagamento na entrega - só aparece para PIX e Cartão
            if (_formaPagamento == "PIX" ||
                _formaPagamento == "Cartão de Crédito" ||
                _formaPagamento == "Cartão de Débito") ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  setState(() {
                    _pagamentoNaEntrega = !_pagamentoNaEntrega;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _pagamentoNaEntrega
                              ? Colors.green
                              : Colors.white54,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: _pagamentoNaEntrega
                            ? Colors.green
                            : Colors.transparent,
                      ),
                      child: _pagamentoNaEntrega
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text("Pagamento na Entrega",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            // Para Dinheiro: mostrar opções de Já Pago ou Pagar na Entrega
            if (_isPagamentoDinheiro) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Forma de pagamento:",
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text("Já Pago",
                                style: TextStyle(color: Colors.white)),
                            value: true,
                            groupValue: _dinheiroJaPago,
                            activeColor: Colors.green,
                            onChanged: (v) {
                              setState(() {
                                _dinheiroJaPago = v!;
                              });
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text("Pagar na Entrega",
                                style: TextStyle(color: Colors.white)),
                            value: false,
                            groupValue: _dinheiroJaPago,
                            activeColor: Colors.green,
                            onChanged: (v) {
                              setState(() {
                                _dinheiroJaPago = v!;
                              });
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Só mostrar opção de troco se for "Pagar na Entrega"
              if (!_dinheiroJaPago) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _precisaTroco,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.money, color: Colors.green),
                      filled: true,
                      fillColor: Colors.white10),
                  items: const [
                    DropdownMenuItem(
                        value: "Não", child: Text("Não, não preciso")),
                    DropdownMenuItem(value: "Sim", child: Text("Sim, preciso")),
                  ],
                  onChanged: (v) => setState(() => _precisaTroco = v!),
                ),
                if (_precisaTroco == "Sim") ...[
                  const SizedBox(height: 10),
                  _buildTextField(_trocoController, "Troco para quanto?",
                      Icons.account_balance_wallet,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _validarTroco),
                ],
              ],
            ],
            _buildSectionTitle("⏰ Horário"),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildTextField(_horarioController,
                      "Horário (Opcional)", Icons.access_time,
                      keyboardType: TextInputType.number,
                      validator: _validarHorario),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: _toggleAmanha,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _entregarAmanha
                                ? Colors.orange
                                : Colors.white54,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: _entregarAmanha
                              ? Colors.orange
                              : Colors.transparent,
                        ),
                        child: _entregarAmanha
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text("Amanhã",
                          style: TextStyle(
                              color: _entregarAmanha
                                  ? Colors.orange
                                  : Colors.white,
                              fontWeight: _entregarAmanha
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ],
                  ),
                ),
              ],
            ),
            _buildSectionTitle("📝 Observações"),
            _buildTextFieldMultiline(
                _observacoesController, "Observações", Icons.note),
            const SizedBox(height: 20),
            _buildSectionTitle("👇 Prévia da Mensagem"),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8)),
                child: SelectableText(_gerarMensagemPreview(),
                    style: const TextStyle(color: Colors.white))),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: _enviarPedido,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text("SALVAR",
                          style: TextStyle(color: Colors.white)))),
              const SizedBox(width: 16),
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: _enviarWhatsapp,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text("ENVIAR WhatsApp",
                          style: TextStyle(color: Colors.white))))
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
