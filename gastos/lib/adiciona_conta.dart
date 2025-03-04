import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importação necessária para TextInputFormatter
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart'; // Importando a tela de Home
import 'globals.dart'
    as globals; // Importando a variável userId do globals.dart

class AdicionaContaScreen extends StatefulWidget {
  const AdicionaContaScreen({super.key});

  @override
  _AdicionaContaScreenState createState() => _AdicionaContaScreenState();
}

class _AdicionaContaScreenState extends State<AdicionaContaScreen> {
  final _formKey = GlobalKey<FormState>();
  String _titulo = '';
  String _dataVencimento = '';
  bool _ehRecorrente = false;
  String _diaRecorrencia = '';

  // Controllers para os campos de texto
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _valorController =
      TextEditingController(); // Já armazena o valor
  final TextEditingController _dataVencimentoController =
      TextEditingController();
  final TextEditingController _diaRecorrenciaController =
      TextEditingController();

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
        Uri.parse(
            'http://192.168.15.114:3000/contas'), // Endpoint para adicionar contas
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': globals.userId, // Usando a variável userId do globals.dart
          'titulo': _titulo,
          'valor': valorFormatado, // Envia o valor formatado como string
          'data_vencimento': _dataVencimento,
          'eh_recorrente': _ehRecorrente, // Envia se é uma conta recorrente
          'dia_recorrencia': _ehRecorrente
              ? _diaRecorrencia
              : null, // Envia o dia de recorrência apenas se for recorrente
        }),
      );

      print('Resposta do servidor: ${response.body}');
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta adicionada com sucesso!')));

        // Navegar para a tela HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HomeScreen()), // Substitua HomeScreen pela sua tela de destino
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Erro ao adicionar conta!')));
      }
    }
  }

  // Método para preencher a data atual no campo de data de vencimento
  void _preencherDataAtual() {
    final now = DateTime.now();
    final dataAtual =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    setState(() {
      _dataVencimento = dataAtual;
      _dataVencimentoController.text = dataAtual;
    });
  }

  // Método para corrigir o dia de recorrência
  void _corrigirDiaRecorrencia(String value) {
    int? dia = int.tryParse(value);
    if (dia != null) {
      if (dia > 31) {
        dia = 31;
      }
      _diaRecorrenciaController.text = dia.toString();
      _diaRecorrencia = dia.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Conta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campo Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
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

              // Campo Valor
              TextFormField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
                inputFormatters: [valorMask], // Aplica a máscara de valor
                onChanged: (value) {
                  // Não é mais necessário atualizar _valor
                },
              ),

              // Campo Data de Vencimento (dd/mm/aaaa)
              TextFormField(
                controller: _dataVencimentoController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                    labelText: 'Data de Vencimento (dd/mm/aaaa)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a data de vencimento';
                  } else if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
                    return 'Formato inválido. Use dd/mm/aaaa.';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _dataVencimento = value;
                  });
                },
              ),

              // Botão para preencher a data atual
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: _preencherDataAtual,
                  child: const Text('Usar data atual'),
                ),
              ),

              // Campo "É recorrente?"
              SwitchListTile(
                title: const Text('É recorrente?'),
                value: _ehRecorrente,
                onChanged: (bool value) {
                  setState(() {
                    _ehRecorrente = value;
                  });
                },
              ),

              // Campo Dia de Recorrência (visível apenas se "É recorrente" estiver ativo)
              if (_ehRecorrente)
                TextFormField(
                  controller: _diaRecorrenciaController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Dia de Recorrência (1 a 31)'),
                  validator: (value) {
                    if (_ehRecorrente && (value == null || value.isEmpty)) {
                      return 'Por favor, insira o dia de recorrência';
                    } else if (_ehRecorrente) {
                      int? dia = int.tryParse(value!);
                      if (dia == null || dia < 1 || dia > 31) {
                        return 'Dia inválido. Deve ser entre 1 e 31.';
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _corrigirDiaRecorrencia(
                        value); // Corrige o valor do dia de recorrência
                  },
                ),

              // Botão para enviar o formulário
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: _enviarFormulario,
                  child: const Text('Adicionar Conta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
