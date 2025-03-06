import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditarGastoScreen extends StatefulWidget {
  final dynamic gasto;

  const EditarGastoScreen({super.key, required this.gasto});

  @override
  _EditarGastoScreenState createState() => _EditarGastoScreenState();
}

class _EditarGastoScreenState extends State<EditarGastoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _valorController;
  late TextEditingController _dataController;
  late TextEditingController _parcelaController;
  String _categoriaSelecionada = '';
  String _formaPagamentoSelecionada = '';

  final List<String> formasDePagamento = [
    'Boleto',
    'Cartão débito',
    'Cartão crédito',
    'Dinheiro'
  ];

  final valorMask = TextInputFormatter.withFunction((oldValue, newValue) {
    String cleanedText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedText.isEmpty) {
      cleanedText = '00';
    } else if (cleanedText.length == 1) {
      cleanedText = '0$cleanedText';
    }
    String formattedText =
        '${cleanedText.substring(0, cleanedText.length - 2)},${cleanedText.substring(cleanedText.length - 2)}';
    formattedText = formattedText.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  });

  final _dataMask = MaskTextInputFormatter(mask: '##/##/####');

  @override
  void initState() {
    super.initState();
    print("Parcela Atual: ${widget.gasto['parcela_atual']}"); // Verifique aqui
    _tituloController = TextEditingController(text: widget.gasto['titulo']);
    _valorController =
        TextEditingController(text: widget.gasto['valor'].toString());

    // Formatar a data para dd/MM/yyyy
    DateTime data = DateTime.parse(widget.gasto['data']);
    _dataController =
        TextEditingController(text: DateFormat('dd/MM/yyyy').format(data));

    // Verificar e ajustar o número da parcela
    String parcelaAtual = widget.gasto['parcela_atual'] ?? '';
    print("Parcela Atual extraída: $parcelaAtual"); // Verifique aqui
    if (parcelaAtual.contains('/')) {
      // Exibe apenas o número antes da barra
      _parcelaController =
          TextEditingController(text: parcelaAtual.split('/')[0]);
    } else {
      // Se não houver '/', só exibe o valor atual
      _parcelaController = TextEditingController(text: parcelaAtual);
    }

    _categoriaSelecionada = widget.gasto['categoria'];
    _formaPagamentoSelecionada =
        widget.gasto['forma_pagamento']; // Definir a forma de pagamento atual
  }

  Future<void> atualizarGasto() async {
    final updatedGasto = {
      'id': widget.gasto['id'],
      'titulo': _tituloController.text,
      'categoria': _categoriaSelecionada,
      'valor': _valorController.text,
      'data': _dataController.text,
      'forma_pagamento': _formaPagamentoSelecionada,
      'parcela_atual':
          _parcelaController.text.isEmpty ? '1' : _parcelaController.text,
    };

    try {
      final response = await http.put(
        Uri.parse('http://192.168.15.114:3000/gastos/${widget.gasto['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedGasto),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        _showError('Erro ao atualizar o gasto. Código: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Erro de conexão: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  IconData _getFormaPagamentoIcon(String forma) {
    switch (forma) {
      case 'Boleto':
        return Icons.picture_as_pdf; // Ícone para boleto
      case 'Cartão débito':
        return Icons.credit_card; // Ícone para cartão de débito
      case 'Cartão crédito':
        return Icons.credit_card; // Ícone para cartão de crédito
      case 'Dinheiro':
        return Icons.money; // Ícone para dinheiro
      default:
        return Icons.payment; // Ícone padrão
    }
  }

  Widget _buildCategoriaCard(String categoria, IconData icone) {
    bool isSelected = _categoriaSelecionada == categoria;
    return GestureDetector(
      onTap: () {
        setState(() {
          _categoriaSelecionada = categoria;
        });
      },
      child: SizedBox(
        width: 110,
        height: 120,
        child: Card(
          color: isSelected ? const Color(0xFF6200EE) : Colors.white,
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icone,
                    size: 30, color: isSelected ? Colors.white : Colors.black),
                const SizedBox(height: 5),
                Text(categoria,
                    style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Gasto'),
      ),
      body: SingleChildScrollView(
        // Torna o corpo rolável
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoriaCard('Casa', Icons.home),
                    _buildCategoriaCard('Comida', Icons.restaurant),
                    _buildCategoriaCard('Compra', Icons.shopping_cart),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoriaCard('Transporte', Icons.directions_car),
                    _buildCategoriaCard('Presente', Icons.card_giftcard),
                    _buildCategoriaCard('Outros', Icons.apps),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(), // Adicionando borda
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'O título é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorController,
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    border: OutlineInputBorder(), // Adicionando borda
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [valorMask],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'O valor é obrigatório';
                    }
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return 'Informe um valor válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dataController,
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    border: OutlineInputBorder(), // Adicionando borda
                  ),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [_dataMask], // Aplicando a máscara
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'A data é obrigatória';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _parcelaController,
                  decoration: const InputDecoration(
                    labelText: 'Parcela Atual (opcional)',
                    border: OutlineInputBorder(), // Adicionando borda
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _formaPagamentoSelecionada.isEmpty
                      ? null
                      : _formaPagamentoSelecionada,
                  items: formasDePagamento.map((forma) {
                    return DropdownMenuItem(
                      value: forma,
                      child: Row(
                        children: [
                          Icon(
                            _getFormaPagamentoIcon(forma),
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          Text(forma),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _formaPagamentoSelecionada = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Forma de Pagamento',
                    border: OutlineInputBorder(), // Adicionando borda
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecione uma forma de pagamento';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      atualizarGasto();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF6200EE), // Cor de fundo do botão
                    foregroundColor: Colors.white, // Cor do texto
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
