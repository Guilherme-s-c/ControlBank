import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart' as globals;

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
    _mesSelecionado = agora.month.toString().padLeft(2, '0'); // Mês atual (ex: "02")
    _anoSelecionado = agora.year.toString(); // Ano atual (ex: "2025")
    fetchGastos();
  }

  List<String> gerarMeses() {
    return List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'));
  }

  List<String> gerarAnos(int quantidade) {
    DateTime agora = DateTime.now();
    return List.generate(quantidade, (index) => (agora.year + index).toString());
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
                          return ListTile(
                            title: Text(gasto['titulo']),
                            subtitle: Text(
                              "${gasto['categoria']} - R\$ ${gasto['valor']} - ${gasto['parcela_atual'] ?? ''}",
                            ),
                            trailing: Text(gasto['data']),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
