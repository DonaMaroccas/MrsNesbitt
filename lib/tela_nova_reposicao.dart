import 'package:flutter/material.dart';
import 'model_reposicao.dart';

class TelaNovaReposicao extends StatefulWidget {
  const TelaNovaReposicao({super.key});

  @override
  State<TelaNovaReposicao> createState() => _TelaNovaReposicaoState();
}

class _TelaNovaReposicaoState extends State<TelaNovaReposicao> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _produtoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();

  @override
  void dispose() {
    _produtoController.dispose();
    _quantidadeController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  String? _validarProduto(String? value) {
    if (value == null || value.isEmpty) {
      return "Produto é obrigatório";
    }
    return null;
  }

  String? _validarQuantidade(String? value) {
    if (value == null || value.isEmpty) {
      return "Quantidade é obrigatória";
    }
    return null;
  }

  void _salvarReposicao() {
    if (_formKey.currentState!.validate()) {
      final reposicao = Reposicao(
        produto: _produtoController.text.trim(),
        quantidade: _quantidadeController.text.trim(),
        observacao: _observacaoController.text.trim(),
      );
      Navigator.pop(context, reposicao);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text("Nova Reposição",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo Produto
              TextFormField(
                controller: _produtoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Produto",
                  labelStyle: const TextStyle(color: Colors.green),
                  prefixIcon: const Icon(Icons.inventory, color: Colors.green),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: _validarProduto,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              // Campo Quantidade
              TextFormField(
                controller: _quantidadeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Quantidade",
                  labelStyle: const TextStyle(color: Colors.green),
                  prefixIcon: const Icon(Icons.numbers, color: Colors.green),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: _validarQuantidade,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              // Campo Observação
              TextFormField(
                controller: _observacaoController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Observação (opcional)",
                  labelStyle: const TextStyle(color: Colors.green),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 50),
                    child: Icon(Icons.note, color: Colors.green),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 30),
              // Botão Salvar
              ElevatedButton(
                onPressed: _salvarReposicao,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "ADICIONAR À LISTA",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
