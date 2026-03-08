import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model_reposicao.dart';
import 'tela_nova_reposicao.dart';

class TelaListaReposicao extends StatefulWidget {
  const TelaListaReposicao({super.key});

  @override
  State<TelaListaReposicao> createState() => _TelaListaReposicaoState();
}

class _TelaListaReposicaoState extends State<TelaListaReposicao> {
  // Cache em memória para evitar recarregamentos
  List<Reposicao>? _cachedReposicoes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarReposicoes();
  }

  Future<void> _carregarReposicoes() async {
    if (_cachedReposicoes != null) {
      // Dados já estão em cache
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? dados = prefs.getString('reposicoes');
      if (dados != null) {
        List decoded = jsonDecode(dados);
        _cachedReposicoes = decoded.map((e) => Reposicao.fromMap(e)).toList();
      } else {
        _cachedReposicoes = [];
      }
    } catch (e) {
      _cachedReposicoes = [];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarReposicoes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reposicoes',
        jsonEncode(_cachedReposicoes!.map((e) => e.toMap()).toList()));
  }

  String _gerarId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  void _adicionarReposicao(Reposicao reposicao) {
    setState(() {
      reposicao.id = _gerarId();
      _cachedReposicoes!.insert(0, reposicao);
    });
    _salvarReposicoes();
  }

  void _removerReposicao(String id) {
    setState(() {
      _cachedReposicoes!.removeWhere((e) => e.id == id);
    });
    _salvarReposicoes();
  }

  void _toggleConcluida(String id) {
    setState(() {
      int index = _cachedReposicoes!.indexWhere((e) => e.id == id);
      if (index != -1) {
        _cachedReposicoes![index].concluida =
            !_cachedReposicoes![index].concluida;
      }
    });
    _salvarReposicoes();
  }

  void _confirmarExclusao(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Confirmar", style: TextStyle(color: Colors.white)),
        content: const Text("Deseja excluir esta reposição?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _removerReposicao(id);
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
        title: const Text("Lista de Reposição",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final reposicao = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TelaNovaReposicao()));
                if (reposicao != null && reposicao is Reposicao)
                  _adicionarReposicao(reposicao);
              }),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final reposicao = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TelaNovaReposicao()));
          if (reposicao != null && reposicao is Reposicao)
            _adicionarReposicao(reposicao);
        },
        icon: const Icon(Icons.add),
        label: const Text("Nova Reposição"),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (_cachedReposicoes == null || _cachedReposicoes!.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.inventory, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("Nenhum item na lista",
              style: TextStyle(fontSize: 20, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final reposicao = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TelaNovaReposicao()));
              if (reposicao != null && reposicao is Reposicao)
                _adicionarReposicao(reposicao);
            },
            icon: const Icon(Icons.add),
            label: const Text("NOVA REPOSIÇÃO"),
          ),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _cachedReposicoes!.length,
      itemBuilder: (context, index) {
        final reposicao = _cachedReposicoes![index];
        return Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => _toggleConcluida(reposicao.id!),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  // Checkbox
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reposicao.concluida
                          ? Colors.green
                          : Colors.transparent,
                      border: Border.all(
                        color: reposicao.concluida ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: reposicao.concluida
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 15),
                  // Conteúdo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reposicao.produto,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: reposicao.concluida
                                    ? Colors.grey
                                    : Colors.white,
                                decoration: reposicao.concluida
                                    ? TextDecoration.lineThrough
                                    : null)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.numbers,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 5),
                            Text(reposicao.quantidade,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7))),
                          ],
                        ),
                        if (reposicao.observacao.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.note,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(reposicao.observacao,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Botão excluir
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmarExclusao(reposicao.id!),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
