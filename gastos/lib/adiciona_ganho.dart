import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importação necessária para TextInputFormatter
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart'; // Importando a tela de Home
import 'globals.dart' as globals; // Importando a variável userId do globals.dart
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'; // Importação para máscara de data

class AdicionaGanhoScreen extends StatefulWidget {
  const AdicionaGanhoScreen({super.key});

  @override
  _AdicionaGanhoScreenState createState() => _AdicionaGanhoScreenState();
}

class _AdicionaGanhoScreenState extends State<AdicionaGanhoScreen> {
  final _formKey = GlobalKey<FormState>();
  String _descricao = '';
  String _dataRecebimento = '';
  bool _ehRecorrente = false; // Novo campo para "É um ganho recorrente?"
  String _diaVencimento = ''; // Novo campo para o dia do vencimento

  // Controllers para os campos de texto
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _dataRecebimentoController = TextEditingController();
  final TextEditingController _diaVencimentoController = TextEditingController();

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

  // Máscara para o campo de data (dd/MM/aaaa)
  final dataMask = MaskTextInputFormatter(
    mask: '##/##/####', // Formato dd/MM/aaaa
    filter: {'#': RegExp(r'[0-9]')}, // Apenas números são permitidos
  );

  // Método para enviar o formulário para o servidor
  Future<void> _enviarFormulario() async {
    if (_formKey.currentState!.validate()) {
      // Mantém o valor formatado (com vírgula)
      String valorFormatado = _valorController.text;

      // Converte a data de dd/MM/aaaa para aaaa-MM-dd
      String dataFormatada = _converterDataParaFormatoBanco(_dataRecebimento);

      final response = await http.post(
        Uri.parse('http://192.168.15.114:3000/ganhos'), // Endpoint para adicionar ganhos
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': globals.userId, // Usando a variável userId do globals.dart
          'descricao': _descricao,
          'valor': valorFormatado, // Envia o valor formatado como string
          'data_recebimento': dataFormatada, // Envia a data no formato aaaa-MM-dd
          'eh_recorrente': _ehRecorrente, // Envia se é um ganho recorrente
          'dia_vencimento': _ehRecorrente ? _diaVencimento : null, // Envia o dia do vencimento apenas se for recorrente
        }),
      );

      print('Resposta do servidor: ${response.body}');
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ganho adicionado com sucesso!')));

        // Navegar para a tela HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()), // Substitua HomeScreen pela sua tela de destino
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Erro ao adicionar ganho!')));
      }
    }
  }

  // Método para converter a data de dd/MM/aaaa para aaaa-MM-dd
  String _converterDataParaFormatoBanco(String data) {
    if (data.isEmpty) return '';

    // Divide a data em dia, mês e ano
    List<String> partes = data.split('/');
    if (partes.length != 3) return '';

    String dia = partes[0];
    String mes = partes[1];
    String ano = partes[2];

    // Retorna a data no formato aaaa-MM-dd
    return '$ano-$mes-$dia';
  }

  // Método para preencher a data atual no campo de data de recebimento
  void _preencherDataAtual() {
    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    setState(() {
      _dataRecebimento = formattedDate;
      _dataRecebimentoController.text = formattedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Ganho'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campo Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _descricao = value;
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

              // Campo Data de Recebimento
              TextFormField(
                controller: _dataRecebimentoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Data de Recebimento (dd/MM/aaaa)'),
                inputFormatters: [dataMask], // Aplica a máscara de data
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a data de recebimento';
                  } else {
                    // Valida se a data está no formato correto
                    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                    if (!regex.hasMatch(value)) {
                      return 'Formato de data inválido. Use dd/MM/aaaa.';
                    }
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _dataRecebimento = value;
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

              // Campo "É um ganho recorrente?"
              SwitchListTile(
                title: const Text('É um ganho recorrente?'),
                value: _ehRecorrente,
                onChanged: (bool value) {
                  setState(() {
                    _ehRecorrente = value;
                  });
                },
              ),

              // Se for recorrente, mostrar o campo de dia do vencimento
              if (_ehRecorrente) ...[
                TextFormField(
                  controller: _diaVencimentoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Dia do ganho (1 a 31)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o dia do ganho';
                    } else {
                      int? dia = int.tryParse(value);
                      if (dia == null || dia < 1 || dia > 31) {
                        return 'Dia inválido. Deve ser entre 1 e 31.';
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      // Tenta converter o valor inserido em número
                      int? dia = int.tryParse(value);
                      // Se o valor for maior que 31, automaticamente corrige para 31
                      if (dia != null && dia > 31) {
                        _diaVencimentoController.text = '31';
                      } else {
                        _diaVencimento = value;
                      }
                    });
                  },
                ),
              ],

              // Botão para enviar o formulário
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: _enviarFormulario,
                  child: const Text('Adicionar Ganho'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}   