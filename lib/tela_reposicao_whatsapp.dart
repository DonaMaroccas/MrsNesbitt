import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TelaReposicaoWhatsApp extends StatefulWidget {
  const TelaReposicaoWhatsApp({super.key});

  @override
  State<TelaReposicaoWhatsApp> createState() => _TelaReposicaoWhatsAppState();
}

class _TelaReposicaoWhatsAppState extends State<TelaReposicaoWhatsApp> {
  // Dropdown de lojas
  String _lojaSelecionada = "Marcão";

  // Controle para usar lista anterior
  bool _usarListaAnterior = false;
  bool _temListaAnterior = false;

  // Toggles e controllers para cada categoria
  bool _racaoCachorroAtivo = false;
  final TextEditingController _racaoCachorroController =
      TextEditingController();

  bool _racaoGatoAtivo = false;
  final TextEditingController _racaoGatoController = TextEditingController();

  bool _areiaAtivo = false;
  final TextEditingController _areiaController = TextEditingController();

  bool _passarinhoAtivo = false;
  final TextEditingController _passarinhoController = TextEditingController();

  bool _avulsaAtivo = false;
  final TextEditingController _avulsaController = TextEditingController();

  bool _sacheAtivo = false;
  final TextEditingController _sacheController = TextEditingController();

  bool _remedioAtivo = false;
  final TextEditingController _remedioController = TextEditingController();

  bool _shampooAtivo = false;
  final TextEditingController _shampooController = TextEditingController();

  bool _canaletadoAtivo = false;
  final TextEditingController _canaletadoController = TextEditingController();

  bool _sacoFechadoAtivo = false;
  final TextEditingController _saco15kgController = TextEditingController();
  final TextEditingController _saco10kgController = TextEditingController();

  bool _produtosLojaAtivo = false;
  final TextEditingController _produtosLojaController = TextEditingController();

  final List<String> _lojas = ["Marcão", "CHC", "Lagoas", "Rua H", "Centro"];

  String _gerarMensagem() {
    String msg = "📋 REPOSIÇÃO: $_lojaSelecionada\n\n";

    if (_racaoCachorroAtivo && _racaoCachorroController.text.isNotEmpty) {
      String itens = _formatarItensComBullets(_racaoCachorroController.text);
      msg += "🐶 Ração Cachorro\n$itens\n\n";
    }

    if (_racaoGatoAtivo && _racaoGatoController.text.isNotEmpty) {
      String itens = _formatarItensComBullets(_racaoGatoController.text);
      msg += "🐱 Ração Gato\n$itens\n\n";
    }

    if (_areiaAtivo && _areiaController.text.isNotEmpty) {
      String itens = _formatarItensComBullets(_areiaController.text);
      msg += "🕳️ Areia\n$itens\n\n";
    }

    if (_passarinhoAtivo && _passarinhoController.text.isNotEmpty) {
      String itens = _formatarItensComBullets(_passarinhoController.text);
      msg += "🦜 Passarinho\n$itens\n\n";
    }

    if (_avulsaAtivo && _avulsaController.text.isNotEmpty) {
      String itens = _formatarItensComBullets(_avulsaController.text);
      msg += "📦 Avulsa\n$itens\n\n";
    }

    if (_sacheAtivo && _sacheController.text.isNotEmpty) {
      String itens = _formatarItensComBullets(_sacheController.text);
      msg += "🥩 Sachê\n$itens\n\n";
    }

    if (_remedioAtivo && _remedioController.text.isNotEmpty) {
      String itens = _formatarItensComBullets(_remedioController.text);
      msg += "💊 Remédio\n$itens\n\n";
    }

    if (_shampooAtivo && _shampooController.text.isNotEmpty) {
      String itens = _formatarItensComBullets(_shampooController.text);
      msg += "🧼 Shampoo\n$itens\n\n";
    }

    if (_canaletadoAtivo && _canaletadoController.text.isNotEmpty) {
      String itens = _formatarItensComBullets(_canaletadoController.text);
      msg += "📌 Canaletado\n$itens\n\n";
    }

    if (_sacoFechadoAtivo) {
      bool tem15kg = _saco15kgController.text.isNotEmpty;
      bool tem10kg = _saco10kgController.text.isNotEmpty;
      if (tem15kg || tem10kg) {
        msg += "⚖️ Saco Fechado\n";
        if (tem15kg) {
          msg += "• 15kg: ${_saco15kgController.text}\n";
        }
        if (tem10kg) {
          msg += "• 10kg: ${_saco10kgController.text}\n";
        }
        msg += "\n";
      }
    }

    if (_produtosLojaAtivo && _produtosLojaController.text.isNotEmpty) {
      String itens = _formatarItensComBullets(_produtosLojaController.text);
      msg += "🧹 Produtos para a Loja\n$itens\n\n";
    }

    return msg.trim();
  }

  // Formata os itens com bullets (•)
  String _formatarItensComBullets(String texto) {
    // Divide o texto em linhas
    List<String> linhas = texto.split('\n');
    String resultado = "";

    for (String linha in linhas) {
      String linhaTrimada = linha.trim();
      if (linhaTrimada.isNotEmpty) {
        // Se a linha já começa com bullet ou tracinho, mantém
        if (linhaTrimada.startsWith('•') || linhaTrimada.startsWith('-')) {
          resultado += "$linha\n";
        } else {
          resultado += "• $linha\n";
        }
      }
    }

    return resultado.trim();
  }

  void _copiarMensagem() {
    String msg = _gerarMensagem();
    if (msg == "📋 REPOSIÇÃO: $_lojaSelecionada") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum item preenchido!")),
      );
      return;
    }
    _salvarListaAtual();
    Clipboard.setData(ClipboardData(text: msg));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mensagem copiada!")),
    );
  }

  void _enviarWhatsApp() async {
    String msg = _gerarMensagem();
    if (msg == "📋 REPOSIÇÃO: $_lojaSelecionada") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum item preenchido!")),
      );
      return;
    }

    _salvarListaAtual();

    String url = "https://wa.me/?text=${Uri.encodeFull(msg)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao abrir WhatsApp")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarListaAnterior();
  }

  Future<void> _carregarListaAnterior() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? dados = prefs.getString('reposicao_anterior');
      if (dados != null && dados.isNotEmpty) {
        setState(() => _temListaAnterior = true);
      }
    } catch (e) {
      // Silencioso
    }
  }

  Future<void> _salvarListaAtual() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> dados = {
        'loja': _lojaSelecionada,
        'racaoCachorroAtivo': _racaoCachorroAtivo,
        'racaoCachorro': _racaoCachorroController.text,
        'racaoGatoAtivo': _racaoGatoAtivo,
        'racaoGato': _racaoGatoController.text,
        'areiaAtivo': _areiaAtivo,
        'areia': _areiaController.text,
        'passarinhoAtivo': _passarinhoAtivo,
        'passarinho': _passarinhoController.text,
        'avulsaAtivo': _avulsaAtivo,
        'avulsa': _avulsaController.text,
        'sacheAtivo': _sacheAtivo,
        'sache': _sacheController.text,
        'remedioAtivo': _remedioAtivo,
        'remedio': _remedioController.text,
        'shampooAtivo': _shampooAtivo,
        'shampoo': _shampooController.text,
        'canaletadoAtivo': _canaletadoAtivo,
        'canaletado': _canaletadoController.text,
        'sacoFechadoAtivo': _sacoFechadoAtivo,
        'saco15kg': _saco15kgController.text,
        'saco10kg': _saco10kgController.text,
        'produtosLojaAtivo': _produtosLojaAtivo,
        'produtosLoja': _produtosLojaController.text,
      };
      await prefs.setString('reposicao_anterior', jsonEncode(dados));
      if (mounted) {
        setState(() => _temListaAnterior = true);
      }
    } catch (e) {
      // Silencioso
    }
  }

  Future<void> _carregarDadosListaAnterior() async {
    if (!_usarListaAnterior) {
      // Limpar campos se desativou
      setState(() {
        _racaoCachorroAtivo = false;
        _racaoCachorroController.clear();
        _racaoGatoAtivo = false;
        _racaoGatoController.clear();
        _areiaAtivo = false;
        _areiaController.clear();
        _passarinhoAtivo = false;
        _passarinhoController.clear();
        _avulsaAtivo = false;
        _avulsaController.clear();
        _sacheAtivo = false;
        _sacheController.clear();
        _remedioAtivo = false;
        _remedioController.clear();
        _shampooAtivo = false;
        _shampooController.clear();
        _canaletadoAtivo = false;
        _canaletadoController.clear();
        _sacoFechadoAtivo = false;
        _saco15kgController.clear();
        _saco10kgController.clear();
        _produtosLojaAtivo = false;
        _produtosLojaController.clear();
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? dados = prefs.getString('reposicao_anterior');
      if (dados != null) {
        Map<String, dynamic> map = jsonDecode(dados);
        setState(() {
          _lojaSelecionada = map['loja'] ?? "Marcão";
          _racaoCachorroAtivo = map['racaoCachorroAtivo'] ?? false;
          _racaoCachorroController.text = map['racaoCachorro'] ?? '';
          _racaoGatoAtivo = map['racaoGatoAtivo'] ?? false;
          _racaoGatoController.text = map['racaoGato'] ?? '';
          _areiaAtivo = map['areiaAtivo'] ?? false;
          _areiaController.text = map['areia'] ?? '';
          _passarinhoAtivo = map['passarinhoAtivo'] ?? false;
          _passarinhoController.text = map['passarinho'] ?? '';
          _avulsaAtivo = map['avulsaAtivo'] ?? false;
          _avulsaController.text = map['avulsa'] ?? '';
          _sacheAtivo = map['sacheAtivo'] ?? false;
          _sacheController.text = map['sache'] ?? '';
          _remedioAtivo = map['remedioAtivo'] ?? false;
          _remedioController.text = map['remedio'] ?? '';
          _shampooAtivo = map['shampooAtivo'] ?? false;
          _shampooController.text = map['shampoo'] ?? '';
          _canaletadoAtivo = map['canaletadoAtivo'] ?? false;
          _canaletadoController.text = map['canaletado'] ?? '';
          _sacoFechadoAtivo = map['sacoFechadoAtivo'] ?? false;
          _saco15kgController.text = map['saco15kg'] ?? '';
          _saco10kgController.text = map['saco10kg'] ?? '';
          _produtosLojaAtivo = map['produtosLojaAtivo'] ?? false;
          _produtosLojaController.text = map['produtosLoja'] ?? '';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lista anterior carregada!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao carregar lista anterior")),
        );
      }
    }
  }

  void _toggleListaAnterior() {
    setState(() {
      _usarListaAnterior = !_usarListaAnterior;
    });
    _carregarDadosListaAnterior();
  }

  @override
  void dispose() {
    _racaoCachorroController.dispose();
    _racaoGatoController.dispose();
    _areiaController.dispose();
    _passarinhoController.dispose();
    _avulsaController.dispose();
    _sacheController.dispose();
    _remedioController.dispose();
    _shampooController.dispose();
    _canaletadoController.dispose();
    _saco15kgController.dispose();
    _saco10kgController.dispose();
    _produtosLojaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Reposição WhatsApp"),
        backgroundColor: const Color(0xFF2C2C2C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_temListaAnterior)
            IconButton(
              icon: Icon(
                _usarListaAnterior ? Icons.visibility : Icons.visibility_off,
                color: _usarListaAnterior ? Colors.green : Colors.white70,
              ),
              onPressed: _toggleListaAnterior,
              tooltip: _usarListaAnterior
                  ? "Lista anterior ativa"
                  : "Usar lista anterior",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown de Loja
            _buildSectionTitle("Selecione a Loja"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _lojaSelecionada,
                isExpanded: true,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                underline: const SizedBox(),
                items: _lojas.map((loja) {
                  return DropdownMenuItem(
                    value: loja,
                    child: Text(loja),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _lojaSelecionada = value!;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // Ração Cachorro
            _buildToggleField(
              "🐶 Ração Cachorro",
              _racaoCachorroAtivo,
              (value) => setState(() => _racaoCachorroAtivo = value),
              _racaoCachorroController,
              placeholder: "Digite cada item em uma linha...",
            ),

            // Ração Gato
            _buildToggleField(
              "🐱 Ração Gato",
              _racaoGatoAtivo,
              (value) => setState(() => _racaoGatoAtivo = value),
              _racaoGatoController,
              placeholder: "Digite cada item em uma linha...",
            ),

            // Areia
            _buildToggleField(
              "🕳️ Areia",
              _areiaAtivo,
              (value) => setState(() => _areiaAtivo = value),
              _areiaController,
              placeholder: "Digite cada item em uma linha...",
            ),

            // Passarinho
            _buildToggleField(
              "🦜 Passarinho",
              _passarinhoAtivo,
              (value) => setState(() => _passarinhoAtivo = value),
              _passarinhoController,
              placeholder: "Digite cada item em uma linha...",
            ),

            // Avulsa
            _buildToggleField(
              "📦 Avulsa",
              _avulsaAtivo,
              (value) => setState(() => _avulsaAtivo = value),
              _avulsaController,
              placeholder: "Digite cada item em uma linha...",
            ),

            // Sachê
            _buildToggleField(
              "🥩 Sachê",
              _sacheAtivo,
              (value) => setState(() => _sacheAtivo = value),
              _sacheController,
              placeholder: "Digite cada item em uma linha...",
            ),

            // Remédio
            _buildToggleField(
              "💊 Remédio",
              _remedioAtivo,
              (value) => setState(() => _remedioAtivo = value),
              _remedioController,
              placeholder: "Digite cada item em uma linha...",
            ),

            // Shampoo
            _buildToggleField(
              "🧼 Shampoo",
              _shampooAtivo,
              (value) => setState(() => _shampooAtivo = value),
              _shampooController,
              placeholder: "Digite cada item em uma linha...",
            ),

            // Canaletado
            _buildToggleField(
              "📌 Canaletado",
              _canaletadoAtivo,
              (value) => setState(() => _canaletadoAtivo = value),
              _canaletadoController,
              placeholder: "Digite cada item em uma linha...",
            ),

            // Saco Fechado (especial com subcampos)
            _buildSacoFechadoField(),

            // Produtos para a Loja
            _buildToggleField(
              "🧹 Produtos para a Loja",
              _produtosLojaAtivo,
              (value) => setState(() => _produtosLojaAtivo = value),
              _produtosLojaController,
              placeholder: "Digite cada item em uma linha...",
            ),

            const SizedBox(height: 32),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _copiarMensagem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF424242),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.copy),
                    label: const Text("COPIAR"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _enviarWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.message),
                    label: const Text("WHATSAPP"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Preview da mensagem
            _buildPreviewSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    String msg = _gerarMensagem();
    bool temConteudo = msg != "📋 REPOSIÇÃO: $_lojaSelecionada";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: temConteudo ? const Color(0xFF757575) : Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Pré-visualização",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!temConteudo)
                const Text(
                  "Nenhum item adicionado",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildToggleField(
    String label,
    bool isActive,
    Function(bool) onToggle,
    TextEditingController controller, {
    String placeholder = "Digite os itens...",
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Switch(
                value: isActive,
                onChanged: onToggle,
                activeColor: const Color(0xFF757575),
              ),
            ],
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onSubmitted: (value) {
                  // Ao pressionar Enter, adiciona "- " para novo item
                  String currentText = controller.text;
                  if (!currentText.endsWith("\n") && currentText.isNotEmpty) {
                    controller.text = "$currentText\n- ";
                  } else if (currentText.isEmpty) {
                    controller.text = "- ";
                  } else {
                    controller.text = "$currentText- ";
                  }
                  // Mantém o cursor no final
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSacoFechadoField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "⚖️ Saco Fechado",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Switch(
                value: _sacoFechadoAtivo,
                onChanged: (value) => setState(() => _sacoFechadoAtivo = value),
                activeColor: const Color(0xFF757575),
              ),
            ],
          ),
          if (_sacoFechadoAtivo) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Itens de 15kg",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _saco15kgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Digite os itens de 15kg...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF757575)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Itens de 10kg",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _saco10kgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Digite os itens de 10kg...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF757575)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
