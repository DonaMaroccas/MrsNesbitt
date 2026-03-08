import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'model_entrega.dart';
import 'tela_nova_entrega.dart';

class TelaListaEntregas extends StatefulWidget {
  const TelaListaEntregas({super.key});

  @override
  State<TelaListaEntregas> createState() => _TelaListaEntregasState();
}

class _TelaListaEntregasState extends State<TelaListaEntregas> {
  // Cache em memória para evitar recarregamentos
  List<Entrega>? _cachedEntregas;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarEntregas();
  }

  Future<void> _carregarEntregas() async {
    if (_cachedEntregas != null) {
      // Dados já estão em cache
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? dados = prefs.getString('entregas');
      if (dados != null) {
        List decoded = jsonDecode(dados);
        _cachedEntregas = decoded.map((e) => Entrega.fromMap(e)).toList();
      } else {
        _cachedEntregas = [];
      }
    } catch (e) {
      _cachedEntregas = [];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarEntregas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('entregas',
        jsonEncode(_cachedEntregas!.map((e) => e.toMap()).toList()));
  }

  String _gerarId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  void _adicionarEntrega(Entrega entrega) {
    setState(() {
      entrega.id = _gerarId();
      _cachedEntregas!.insert(0, entrega);
    });
    _salvarEntregas();
  }

  void _removerEntrega(String id) {
    setState(() {
      _cachedEntregas!.removeWhere((e) => e.id == id);
    });
    _salvarEntregas();
  }

  void _verMensagem(Entrega entrega) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Mensagem", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: SelectableText(entrega.gerarMensagem(),
              style: const TextStyle(color: Colors.white70)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("FECHAR")),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _compartilhar(entrega);
            },
            icon: const Icon(Icons.share),
            label: const Text("COMPARTILHAR"),
          ),
        ],
      ),
    );
  }

  void _compartilhar(Entrega entrega) {
    String mensagem = entrega.gerarMensagem();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Enviar via", style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.green),
            title:
                const Text("WhatsApp", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              String url =
                  "https://wa.me/?text=${Uri.encodeComponent(mensagem)}";
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sms, color: Colors.blue),
            title: const Text("SMS", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              String telefone =
                  entrega.telefone.replaceAll(RegExp(r'[^0-9]'), '');
              String url =
                  "sms:$telefone?body=${Uri.encodeComponent(mensagem)}";
              launchUrl(Uri.parse(url));
            },
          ),
        ]),
      ),
    );
  }

  void _confirmarExclusao(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Confirmar", style: TextStyle(color: Colors.white)),
        content: const Text("Deseja excluir esta entrega?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _removerEntrega(id);
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text("Delivery Pets",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final entrega = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TelaNovaEntrega()));
                if (entrega != null && entrega is Entrega)
                  _adicionarEntrega(entrega);
              }),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final entrega = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TelaNovaEntrega()));
          if (entrega != null && entrega is Entrega) _adicionarEntrega(entrega);
        },
        icon: const Icon(Icons.add),
        label: const Text("Nova Entrega"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (_cachedEntregas == null || _cachedEntregas!.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.local_shipping, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("Nenhuma entrega hoje",
              style: TextStyle(fontSize: 20, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final entrega = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TelaNovaEntrega()));
              if (entrega != null && entrega is Entrega)
                _adicionarEntrega(entrega);
            },
            icon: const Icon(Icons.add),
            label: const Text("NOVA ENTREGA"),
          ),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _cachedEntregas!.length,
      itemBuilder: (context, index) {
        final entrega = _cachedEntregas![index];
        return Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => _verMensagem(entrega),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entrega.nomeCliente,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          entrega.valor.isNotEmpty
                              ? Text("R\$ ${entrega.valor}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green))
                              : const SizedBox(),
                        ]),
                    const SizedBox(height: 5),
                    Text(entrega.endereco,
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          entrega.horarioEntrega.isNotEmpty
                              ? Text(entrega.horarioEntrega,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5)))
                              : const SizedBox(),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                color: Colors.white.withOpacity(0.5)),
                            onSelected: (value) {
                              if (value == 'ver')
                                _verMensagem(entrega);
                              else if (value == 'excluir')
                                _confirmarExclusao(entrega.id);
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                  value: 'ver', child: Text("Ver Mensagem")),
                              const PopupMenuItem(
                                  value: 'excluir',
                                  child: Text("Excluir",
                                      style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ]),
                  ]),
            ),
          ),
        );
      },
    );
  }
}
