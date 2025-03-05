import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para TextInputFormatter
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditarContaScreen extends StatefulWidget {
  final int contaId;

  const EditarContaScreen({super.key, required this.contaId});

  @override
  _EditarContaScreenState createState() => _EditarContaScreenState();
}

class _EditarContaScreenState extends State<EditarContaScreen> {
  final _formKey = GlobalKey<FormState>(); // Chave para o formulário
  bool _isLoading = true; // Indicador de carregamento
  String _error = ''; // Mensagem de erro

  // Controladores para os campos de texto
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  // Máscara para o campo de valor
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

  @override
  void initState() {
    super.initState();
    fetchConta(); // Busca os dados da conta ao inicializar a tela
  }

  // Função para buscar os dados da conta
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

        // Preenche os campos com os dados da conta
        _tituloController.text = data['titulo'];
        _valorController.text = _formatarValor(data['valor'].toString());
        _dataController.text = data['data_conta'];

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

  // Função para formatar o valor com vírgula
  String _formatarValor(String valor) {
    if (valor.isEmpty) return '0,00';

    // Remove pontos e vírgulas existentes
    valor = valor.replaceAll(RegExp(r'[^0-9]'), '');

    // Adiciona zeros à esquerda para garantir dois dígitos após a vírgula
    if (valor.length == 1) {
      valor = '0$valor';
    }

    // Insere a vírgula na posição correta
    return '${valor.substring(0, valor.length - 2)},${valor.substring(valor.length - 2)}';
  }

  // Função para salvar as alterações
  Future<void> salvarAlteracoes() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Remove a vírgula e converte o valor para double
        final valorSemVirgula = _valorController.text.replaceAll(',', '');
        final valorDouble = double.parse(valorSemVirgula) / 100;

        final response = await http.put(
          Uri.parse('http://192.168.15.114:3000/contas/${widget.contaId}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'titulo': _tituloController.text,
            'valor': valorDouble,
            'data_conta': _dataController.text,
          }),
        );

        if (response.statusCode == 200) {
          // Retorna para a tela anterior após salvar
          Navigator.pop(context, true); // Passa `true` para indicar sucesso
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
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editando a conta com ID: ${widget.contaId}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        // Campo para o título
                        TextFormField(
                          controller: _tituloController,
                          decoration: const InputDecoration(labelText: 'Título'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira um título';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        // Campo para o valor
                        TextFormField(
                          controller: _valorController,
                          decoration: const InputDecoration(labelText: 'Valor'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [valorMask], // Aplica a máscara
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira um valor';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        // Campo para a data
                        TextFormField(
                          controller: _dataController,
                          decoration: const InputDecoration(labelText: 'Data'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira uma data';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Botão para salvar
                        ElevatedButton(
                          onPressed: salvarAlteracoes,
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}