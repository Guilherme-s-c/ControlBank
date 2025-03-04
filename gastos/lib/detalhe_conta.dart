import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Para decodificar o JSON
import 'globals.dart' as globals; // Importando a variável userId

class DetalheContaScreen extends StatefulWidget {
  final int contaId;

  const DetalheContaScreen({super.key, required this.contaId});

  @override
  _DetalheContaScreenState createState() => _DetalheContaScreenState();
}

class _DetalheContaScreenState extends State<DetalheContaScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _conta = {};
  String _error = '';
  String? _mesSelecionado;
  String? _anoSelecionado;

  @override
  void initState() {
    super.initState();
    DateTime agora = DateTime.now();
    _mesSelecionado = agora.month.toString().padLeft(2, '0'); // Mês atual (ex: "02")
    _anoSelecionado = agora.year.toString(); // Ano atual (ex: "2025")
    fetchDetalhesConta();
  }

  // Método para gerar meses
  List<String> gerarMeses() {
    return List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  }

  List<String> gerarAnos(int quantidade) {
    DateTime agora = DateTime.now();
    return List.generate(quantidade, (index) => (agora.year + index).toString());
  }

  // Método para formatar o valor com duas casas decimais
  String _formatarValor(String valor) {
    // Substituir vírgula por ponto para que o valor seja interpretado corretamente como double
    double valorDouble = double.tryParse(valor.replaceAll(',', '.')) ?? 0.0;
    return valorDouble.toStringAsFixed(2); // Formatar o valor para 2 casas decimais
  }

  // Método para buscar os detalhes da conta
  Future<void> fetchDetalhesConta() async {
  setState(() {
    _isLoading = true;
    _error = '';
  });

  try {
    final userId = globals.userId;
    String url = 'http://192.168.15.114:3000/contas/${widget.contaId}?user_id=$userId';

    // Adiciona mes e ano corretamente na URL
    if (_mesSelecionado != null && _anoSelecionado != null) {
      url += '&mes=$_mesSelecionado&ano=$_anoSelecionado';
    }

    print("URL: $url"); // Adicionando um print para verificar a URL gerada.

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      print("Resposta da API: $data");

      setState(() {
        if (data is Map<String, dynamic>) {
          _conta = data;
        } else if (data is List) {
          _conta = data.isNotEmpty ? data[0] : {};
        } else {
          _conta = {};
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Erro ao carregar detalhes da conta: ${response.statusCode}';
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


  @override
  Widget build(BuildContext context) {
    List<String> meses = gerarMeses();
    List<String> anos = gerarAnos(5); // Mostra 5 anos para frente

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Conta'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Seletor de Mês
                          Expanded(
                            child: DropdownButton<String>(
                              value: _mesSelecionado,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _mesSelecionado = newValue;
                                });
                                fetchDetalhesConta();
                              },
                              items: meses.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(width: 16), // Espaço entre os campos

                          // Seletor de Ano
                          Expanded(
                            child: DropdownButton<String>(
                              value: _anoSelecionado,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _anoSelecionado = newValue;
                                });
                                fetchDetalhesConta();
                              },
                              items: anos.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Acessar dados da conta
                      Text(
                        'Título: ${_conta['titulo']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Aqui estamos formatando o valor com duas casas decimais
                      Text('Valor: R\$ ${_formatarValor(_conta['valor'] ?? '0,00')}'),
                      Text('Data de Vencimento: ${_conta['data_conta']}'),
                      Text('É Mensal: ${(_conta['eh_mensal'] == '1' || _conta['eh_mensal'] == 1) ? 'Sim' : 'Não'}'),
                      Text('Dia do Vencimento: ${_conta['dia_conta']}'),
                    ],
                  ),
                ),
    );
  }
}
