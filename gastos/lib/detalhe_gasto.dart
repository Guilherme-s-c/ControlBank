import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart' as globals;
import 'editar_gasto.dart'; // Supondo que você tenha uma tela para editar o gasto
import 'package:intl/intl.dart';


class DetalheGastoScreen extends StatefulWidget {
  const DetalheGastoScreen({super.key});

  @override
  _DetalheGastoScreenState createState() => _DetalheGastoScreenState();
}

class _DetalheGastoScreenState extends State<DetalheGastoScreen> {
  bool _isLoading = true;
  List<dynamic> _gastos = [];
  String _error = '';
  String? _mesSelecionado;
  String? _anoSelecionado;
  bool _mostrarParcelados = false;

  @override
  void initState() {
    super.initState();
    DateTime agora = DateTime.now();
    _mesSelecionado =
        agora.month.toString().padLeft(2, '0'); // Mês atual (ex: "02")
    _anoSelecionado = agora.year.toString(); // Ano atual (ex: "2025")
    fetchGastos();
  }

  List<String> gerarMeses() {
    return List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  }

  List<String> gerarAnos(int quantidade) {
    DateTime agora = DateTime.now();
    return List.generate(
        quantidade, (index) => (agora.year + index).toString());
  }

  Future<void> fetchGastos() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final userId = globals.userId;
      String url = 'http://192.168.15.114:3000/gastos?user_id=$userId';

      if (_mesSelecionado != null && _anoSelecionado != null) {
        url += '&mes=$_anoSelecionado-$_mesSelecionado';
      }

      if (_mostrarParcelados) {
        url += '&parcelado=true';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _gastos = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erro ao carregar gastos: ${response.statusCode}';
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

  // Função para excluir o gasto
  Future<void> excluirGasto(String idGasto) async {
    final response = await http.delete(
      Uri.parse('http://192.168.15.114:3000/gastos/$idGasto'),
    );

    if (response.statusCode == 200) {
      // Atualizar a lista de gastos após excluir
      fetchGastos();
    } else {
      setState(() {
        _error = 'Erro ao excluir gasto: ${response.statusCode}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> meses = gerarMeses();
    List<String> anos = gerarAnos(5); // Mostra 5 anos para frente

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Gastos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
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
                      fetchGastos();
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
                      fetchGastos();
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
          ),

          // Filtro de parcelados
          SwitchListTile(
            title: const Text("Mostrar apenas parcelados"),
            value: _mostrarParcelados,
            onChanged: (bool value) {
              setState(() {
                _mostrarParcelados = value;
              });
              fetchGastos();
            },
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error))
                    : ListView.builder(
                        itemCount: _gastos.length,
                        itemBuilder: (context, index) {
                          final gasto = _gastos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
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
                                    title: Text(gasto['titulo']),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "${gasto['categoria']} - R\$ ${gasto['valor']}"),
                                        if (gasto['parcela_atual'] != null)
                                          Text(
                                              "Parcela: ${gasto['parcela_atual']}"),
                                          Text("Data: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(gasto['data']))}"),

                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Botão Editar
                                      OutlinedButton(
                                        onPressed: () {
                                          // Editar: Navega para a tela de edição
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditarGastoScreen(
                                                      gasto: gasto),
                                            ),
                                          ).then((updated) {
                                            if (updated == true) {
                                              // A atualização foi bem-sucedida, então vamos recarregar os dados
                                              fetchGastos();
                                            }
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(
                                            color: const Color.fromARGB(255, 29,
                                                138, 226), // Cor da borda
                                          ),
                                          backgroundColor: Color.fromARGB(255,
                                              29, 138, 226), // Cor de fundo
                                        ),
                                        child: const Text('Editar'),
                                      ),

                                      const SizedBox(width: 8),
                                      // Botão Excluir
                                      OutlinedButton(
                                        onPressed: () {
                                          // Excluir: Exclui o gasto
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title:
                                                    const Text('Excluir Gasto'),
                                                content: const Text(
                                                    'Tem certeza de que deseja excluir este gasto?'),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child:
                                                        const Text('Cancelar'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      excluirGasto(gasto['id']
                                                          .toString());
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child:
                                                        const Text('Excluir'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(
                                              color: const Color.fromARGB(255,
                                                  212, 8, 8)), // Cor da borda
                                          backgroundColor: Color.fromARGB(
                                              255, 212, 8, 8), // Cor de fundo
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
