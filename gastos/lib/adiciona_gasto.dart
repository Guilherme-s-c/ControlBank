import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importação necessária para TextInputFormatter
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart';
import 'home.dart';

class AdicionarGastoScreen extends StatefulWidget {
  const AdicionarGastoScreen({super.key});

  @override
  _AdicionarGastoScreenState createState() => _AdicionarGastoScreenState();
}

final dateMask =
    MaskTextInputFormatter(mask: '##/##/####', filter: {'#': RegExp(r'[0-9]')});

class _AdicionarGastoScreenState extends State<AdicionarGastoScreen> {
  final _formKey = GlobalKey<FormState>();
  String _categoria = 'Casa'; // Categoria inicial
  String _titulo = '';
  double _valor = 0.0;
  String _data = '';
  String _formaPagamento = 'Boleto';
  bool _ehParcelado = false;
  int _quantidadeParcelas = 1;

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  // Máscara personalizada para o campo de valor
  final valorMask = TextInputFormatter.withFunction((oldValue, newValue) {
    // Remove todos os caracteres não numéricos
    String cleanedText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Adiciona zeros à esquerda para garantir dois dígitos após a vírgula
    if (cleanedText.isEmpty) {
      cleanedText = '00'; // Valor padrão para evitar erros
    } else if (cleanedText.length == 1) {
      cleanedText = '0$cleanedText'; // Adiciona um zero à esquerda
    }

    // Insere a vírgula na posição correta
    String formattedText =
        '${cleanedText.substring(0, cleanedText.length - 2)},${cleanedText.substring(cleanedText.length - 2)}';

    // Remove zeros à esquerda antes da vírgula
    formattedText = formattedText.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  });

  // Método para enviar o formulário para o servidor
  Future<void> _enviarFormulario() async {
    if (_formKey.currentState!.validate()) {
      // Mantém o valor formatado (com vírgula)
      String valorFormatado = _valorController.text;

      final response = await http.post(
        Uri.parse('http://192.168.15.114:3000/gastos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'categoria': _categoria,
          'titulo': _titulo,
          'valor': valorFormatado, // Envia o valor formatado como string
          'data': _data,
          'forma_pagamento': _formaPagamento,
          'eh_parcelado': _ehParcelado.toString(),
          'quantidade_parcelas': _quantidadeParcelas.toString(),
        }),
      );

      print('Resposta do servidor: ${response.body}');
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta adicionada com sucesso!')));

        // Navegar para a tela HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao adicionar gasto!')));
      }
    }
  }

  // Função para selecionar ícones de categoria
  IconData getCategoriaIcon(String categoria) {
    switch (categoria) {
      case 'Casa':
        return Icons.home;
      case 'Comida':
        return Icons.fastfood;
      case 'Compra':
        return Icons.shopping_cart;
      case 'Transporte':
        return Icons.directions_car;
      case 'Presente':
        return Icons.card_giftcard;
      case 'Carro':
        return Icons.directions_car;
      default:
        return Icons.help;
    }
  }

  // Função para retornar o nome da categoria de ícones
  String getCategoriaNome(String categoria) {
    switch (categoria) {
      case 'Casa':
        return 'Casa';
      case 'Comida':
        return 'Comida';
      case 'Compra':
        return 'Compra';
      case 'Transporte':
        return 'Transporte';
      case 'Presente':
        return 'Presente';
      case 'Carro':
        return 'Carro';
      default:
        return 'Categoria';
    }
  }

  // Função para calcular o valor das parcelas
  double getValorParcelado() {
    return _valor / _quantidadeParcelas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Gasto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Linha de Cards para Categorias
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoriaCard('Casa'),
                  _buildCategoriaCard('Comida'),
                  _buildCategoriaCard('Compra'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoriaCard('Transporte'),
                  _buildCategoriaCard('Presente'),
                  _buildCategoriaCard('Carro'),
                ],
              ),

              SizedBox(height: 16),
              // Campo Título
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _titulo = value;
                  });
                },
              ),
              SizedBox(height: 16), // Espaçamento entre os campos

              // Campo Valor
              TextFormField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Valor total da compra',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                inputFormatters: [valorMask], // Aplica a máscara de valor
                onChanged: (value) {
                  setState(() {
                    // Atualiza o valor sem formatação
                    String valorSemMascara = value.replaceAll(',', '');
                    _valor = double.parse(valorSemMascara) / 100;
                  });
                },
              ),
              SizedBox(height: 16), // Espaçamento entre os campos

              // Campo Data
              TextFormField(
                controller: _dataController,
                keyboardType: TextInputType.datetime,
                inputFormatters: [dateMask], // Aplica a máscara de data
                decoration: InputDecoration(
                  labelText: 'Data (dd/mm/yyyy)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a data';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _data = value;
                  });
                },
              ),
              SizedBox(height: 16), // Espaçamento entre os campos

              // Campo Forma de Pagamento com ícones
              DropdownButtonFormField<String>(
                value: _formaPagamento,
                decoration: InputDecoration(
                  labelText: 'Forma de Pagamento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (newValue) {
                  setState(() {
                    _formaPagamento = newValue!;
                  });
                },
                items: ['Boleto', 'Cartão débito', 'Cartão crédito', 'Dinheiro']
                    .map((forma) => DropdownMenuItem(
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
                        ))
                    .toList(),
              ),
              SizedBox(height: 2), // Espaçamento entre os campos

              // Campo Parcelado
              SwitchListTile(
                title: const Text('Parcelado'),
                value: _ehParcelado,
                onChanged: (bool value) {
                  setState(() {
                    _ehParcelado = value;
                  });
                },
              ),

              // Se for parcelado, mostrar os campos de quantidade de parcelas e data de vencimento
              if (_ehParcelado) ...[
                // Quantidade de Parcelas
                TextFormField(
                  initialValue: _quantidadeParcelas.toString(),
                  decoration: InputDecoration(
                    labelText: 'Quantidade de Parcelas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _quantidadeParcelas = int.tryParse(value) ?? 1;
                    });
                  },
                ),
              ],
              SizedBox(height: 10), // Espaçamento entre os campos

              // Botão para enviar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: _enviarFormulario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6200EE), // Cor de fundo
                    foregroundColor: Colors.white, // Cor do texto
                  ),
                  child: const Text('Adicionar Gasto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Função para construir o Card de Categoria
  Widget _buildCategoriaCard(String categoria) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _categoria = categoria;
        });
      },
      child: SizedBox(
        width: 110,
        height: 120,
        child: Card(
          color:
              _categoria == categoria ? const Color(0xFF6200EE) : Colors.white,
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  getCategoriaIcon(categoria),
                  size: 40,
                  color: _categoria == categoria
                      ? Colors.white
                      : Colors.black, // Cor condicional
                ),
                const SizedBox(height: 8),
                Text(
                  getCategoriaNome(categoria),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _categoria == categoria
                        ? Colors.white
                        : Colors.black, // Cor condicional
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Função para obter o ícone da forma de pagamento
  IconData _getFormaPagamentoIcon(String formaPagamento) {
    switch (formaPagamento) {
      case 'Boleto':
        return Icons.payment;
      case 'Cartão':
        return Icons.credit_card;
      case 'Dinheiro':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }
}
