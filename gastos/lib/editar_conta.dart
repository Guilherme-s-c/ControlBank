import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; // Para TextInputFormatter

class EditarContaScreen extends StatefulWidget {
  final int contaId;

  const EditarContaScreen({super.key, required this.contaId});

  @override
  _EditarContaScreenState createState() => _EditarContaScreenState();
}

class _EditarContaScreenState extends State<EditarContaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String _error = '';
  bool _isContaMensal = false; // Controle do botão "Conta Mensal"
  TextEditingController _tituloController = TextEditingController();
  TextEditingController _valorController = TextEditingController();
  TextEditingController _dataController = TextEditingController();
  TextEditingController _dataVencimentoController =
      TextEditingController(); // Campo de vencimento

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

  final dataMask = TextInputFormatter.withFunction((oldValue, newValue) {
    String cleanedText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedText.length > 2) {
      cleanedText =
          cleanedText.substring(0, 2) + '/' + cleanedText.substring(2);
    }
    if (cleanedText.length > 5) {
      cleanedText =
          cleanedText.substring(0, 5) + '/' + cleanedText.substring(5);
    }
    return TextEditingValue(
      text: cleanedText,
      selection: TextSelection.collapsed(offset: cleanedText.length),
    );
  });

  @override
  void initState() {
    super.initState();
    fetchConta();
  }

  // Função para converter a data de yyyy-MM-dd para dd/MM/yyyy
  String converterData(String data) {
    final partes = data.split('-');
    return '${partes[2]}/${partes[1]}/${partes[0]}'; // dd/MM/yyyy
  }

  Future<void> fetchConta() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.15.114:3000/contas/${widget.contaId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _tituloController.text = data['titulo'];
        _valorController.text = _formatarValor(data['valor'].toString());

        // Converte a data de yyyy-MM-dd para dd/MM/yyyy
        _dataController.text = converterData(data['data_conta']);

        _isContaMensal = data['is_conta_mensal'] ??
            false; // Definindo um valor padrão 'false' caso seja null

        if (_isContaMensal) {
          // Converte a data de vencimento também
          _dataVencimentoController.text =
              converterData(data['data_vencimento']);
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erro ao carregar conta: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão: $e';
        _isLoading = false;
      });
    }
  }

  String _formatarValor(String valor) {
    if (valor.isEmpty) return '0,00';

    valor = valor.replaceAll(RegExp(r'[^0-9]'), '');

    if (valor.length == 1) {
      valor = '0$valor';
    }

    return '${valor.substring(0, valor.length - 2)},${valor.substring(valor.length - 2)}';
  }

  // Função para salvar as alterações
// Função para salvar as alterações
Future<void> salvarAlteracoes() async {
  if (_formKey.currentState!.validate()) {
    try {
      // Obtém o valor exatamente como está na máscara
      final valorComMascara = _valorController.text;

      String dataVencimento = '';
      if (_isContaMensal) {
        // Mantém o formato dd/MM/yyyy, sem conversão
        dataVencimento = _dataVencimentoController.text;
      }

      // Ajusta o valor de 'is_conta_mensal' para 1 (sim) ou 0 (não)
      final isContaMensalValue = _isContaMensal ? 1 : 0;

      final response = await http.put(
        Uri.parse('http://192.168.15.114:3000/contas/${widget.contaId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'titulo': _tituloController.text,
          'valor': valorComMascara,  // Envia exatamente o que está na máscara
          'data_conta': _dataController.text, // Envia no formato dd/MM/yyyy
          'is_conta_mensal': isContaMensalValue, // Envia como 1 ou 0
          'data_vencimento': dataVencimento, // Envia no formato dd/MM/yyyy
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = 'Erro ao salvar alterações: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão: $e';
      });
    }
  }
}




  // Função para validar e ajustar o dia de vencimento
  void _ajustarDiaVencimento(String text) {
    String cleanedText = text.replaceAll(RegExp(r'[^0-9]'), '');
    int dia = int.tryParse(cleanedText) ?? 0;

    // Se o dia for maior que 31, ajusta para 31
    if (dia > 31) {
      dia = 31;
    }

    // Formata o dia para sempre ter dois dígitos
    cleanedText = dia.toString().padLeft(2, '0');

    // Se o dia for menor que 1, ajusta para 01
    if (dia < 1) {
      cleanedText = '01';
    }

    _dataVencimentoController.text =
        cleanedText; // Atualiza o valor do campo de vencimento
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Conta'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _tituloController,
                            decoration: const InputDecoration(
                              labelText: 'Título',
                              border: OutlineInputBorder(), // Borda adicionada
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira um título';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _valorController,
                            decoration: const InputDecoration(
                              labelText: 'Valor',
                              border: OutlineInputBorder(), // Borda adicionada
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [valorMask],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira um valor';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _dataController,
                            decoration: const InputDecoration(
                              labelText: 'Data',
                              border: OutlineInputBorder(), // Borda adicionada
                            ),
                            keyboardType: TextInputType.datetime,
                            inputFormatters: [dataMask],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira uma data';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            title: const Text('Conta Mensal'),
                            value: _isContaMensal,
                            onChanged: (value) {
                              setState(() {
                                _isContaMensal = value;
                              });
                            },
                          ),
                          if (_isContaMensal) ...[
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _dataVencimentoController,
                              decoration: const InputDecoration(
                                labelText: 'Dia de Vencimento',
                                border:
                                    OutlineInputBorder(), // Borda adicionada
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira uma data de vencimento';
                                }
                                return null;
                              },
                              onChanged: (text) {
                                _ajustarDiaVencimento(
                                    text); // Chama a função para ajustar o dia
                              },
                            ),
                          ],
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: salvarAlteracoes,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6200EE),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Salvar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
