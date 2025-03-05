import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart' as globals;
import 'editar_conta.dart'; // Importe a tela de edição

class DetalheContaScreen extends StatefulWidget {
  const DetalheContaScreen({super.key});

  @override
  _DetalheContaScreenState createState() => _DetalheContaScreenState();
}

class _DetalheContaScreenState extends State<DetalheContaScreen> {
  bool _isLoading = true;
  List<dynamic> _contas = [];
  String _error = '';
  String? _mesSelecionado;
  String? _anoSelecionado;
  bool _mostrarRecorrentes = false;

  @override
  void initState() {
    super.initState();
    DateTime agora = DateTime.now();
    _mesSelecionado =
        agora.month.toString().padLeft(2, '0'); // Mês atual (ex: "02")
    _anoSelecionado = agora.year.toString(); // Ano atual (ex: "2025")
    fetchContas();
  }

  List<String> gerarMeses() {
    return List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  }

  List<String> gerarAnos(int quantidade) {
    DateTime agora = DateTime.now();
    return List.generate(
        quantidade, (index) => (agora.year + index).toString());
  }

  Future<void> fetchContas() async {
  setState(() {
    _isLoading = true;
    _error = '';
  });

  try {
    final userId = globals.userId;
    String url = 'http://192.168.15.114:3000/contas?user_id=$userId';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final contasFiltradas = data.where((conta) {
        final bool isRecorrente = conta['eh_mensal'] == 1;
        final dataConta = DateTime.parse(conta['data_conta']);
        final mesSelecionado = int.parse(_mesSelecionado!);
        final anoSelecionado = int.parse(_anoSelecionado!);

        // Filtra contas recorrentes ou todas as contas conforme _mostrarRecorrentes
        if (_mostrarRecorrentes) {
          return isRecorrente; // Filtra apenas as recorrentes
        } else {
          if (isRecorrente) {
            return dataConta.month <= mesSelecionado && dataConta.year <= anoSelecionado;
          } else {
            return dataConta.month == mesSelecionado && dataConta.year == anoSelecionado;
          }
        }
      }).toList();

      // Verifica se a conta foi paga
      for (var conta in contasFiltradas) {
        final bool isPago =
            await verificarSeContaFoiPagaNoMesAtual(conta['id']);
        conta['status'] = isPago ? 'Pago' : 'A pagar';
      }

      setState(() {
        _contas = contasFiltradas;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Erro ao carregar contas: ${response.statusCode}';
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


  Future<bool> verificarSeContaFoiPagaNoMesAtual(int contaId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.15.114:3000/conta_paga?conta_id=$contaId&mes=$_mesSelecionado&ano=$_anoSelecionado'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data.isNotEmpty;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> marcarComoPago(int contaId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.15.114:3000/conta_paga'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conta_id': contaId,
          'data_pagamento': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        fetchContas();
      } else {
        setState(() {
          _error = 'Erro ao marcar como pago: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão: $e';
      });
    }
  }

  Future<void> excluirConta(int contaId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.15.114:3000/contas/$contaId'),
      );

      if (response.statusCode == 200) {
        fetchContas();
      } else {
        setState(() {
          _error = 'Erro ao excluir conta: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> meses = gerarMeses();
    List<String> anos = gerarAnos(5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Contas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _mesSelecionado,
                    onChanged: (String? newValue) {
                      setState(() {
                        _mesSelecionado = newValue;
                      });
                      fetchContas();
                    },
                    items: meses.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                    // O parâmetro "decoration" não existe em DropdownButton.
                    // Para modificar o campo, você pode usar "decoration" dentro de um TextField ou similar.
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _anoSelecionado,
                    onChanged: (String? newValue) {
                      setState(() {
                        _anoSelecionado = newValue;
                      });
                      fetchContas();
                    },
                    items: anos.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                    // O parâmetro "decoration" não existe em DropdownButton.
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text("Mostrar apenas contas recorrentes"),
            value: _mostrarRecorrentes,
            onChanged: (bool value) {
              setState(() {
                _mostrarRecorrentes = value;
              });
              fetchContas();
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchContas,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _contas.length,
                        itemBuilder: (context, index) {
                          final conta = _contas[index];
                          final bool isRecorrente = conta['eh_mensal'] == 1;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text(conta['titulo']),
                                    subtitle: Text(
                                      isRecorrente
                                          ? "Vencimento dia: ${conta['dia_conta'] ?? ''} - Valor: R\$ ${double.tryParse(conta['valor']?.replaceAll(',', '.') ?? '0')?.toStringAsFixed(2) ?? '0.00'}"
                                          : "${conta['data_conta'] ?? ''} - Valor: R\$ ${double.tryParse(conta['valor']?.replaceAll(',', '.') ?? '0')?.toStringAsFixed(2) ?? '0.00'}",
                                    ),
                                    trailing: Text(
                                      conta['status'] ?? 'A pagar',
                                      style: TextStyle(
                                        color: conta['status'] == 'Pago'
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          marcarComoPago(conta['id']);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white, side: BorderSide(
                                              color: const Color.fromARGB(255, 34, 156, 10)), // Borda azul
                                          backgroundColor:
                                              Color.fromARGB(255, 34, 156, 10), // Texto branco
                                        ),
                                        child: const Text('Pago'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () async {
                                          final resultado =
                                              await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditarContaScreen(
                                                      contaId: conta['id']),
                                            ),
                                          );

                                          if (resultado == true) {
                                            setState(() {
                                              fetchContas();
                                            });
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
                                          side: BorderSide(color: const Color.fromARGB(255, 29, 138, 226)),backgroundColor:
                                              Color.fromARGB(255, 29, 138, 226),
                                        ),
                                        child: const Text('Editar'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () {
                                          excluirConta(conta['id']);
                                        },
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
                                          side: BorderSide(color: const Color.fromARGB(255, 212, 8, 8)),backgroundColor:
                                              Color.fromARGB(255, 212, 8, 8),
                                        ),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
