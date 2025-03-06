import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'gasto.dart';
import 'adiciona_ganho.dart';
import 'globals.dart' as globals;
import 'detalhe_gasto.dart';
import 'detalhe_conta.dart'; // Importe a tela de detalhes das contas

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _error = '';

  // Variáveis para armazenar os valores
  double _totalContas = 0.0;
  double _totalGastos = 0.0;
  double _totalGanhos = 0.0;

  // Listas para armazenar os últimos gastos, contas, contas recorrentes e gastos parcelados
  List<dynamic> _ultimosGastos = [];
  List<dynamic> _ultimasContas = [];
  List<dynamic> _contasRecorrentes = [];
  List<dynamic> _gastosParcelados = [];

  // Variável para controlar o filtro de parcelas do mês atual
  bool _mostrarApenasMesAtual = false;

  // Método para parsear datas no formato DD/MM/YYYY
  DateTime parseCustomDate(String dateString) {
    if (dateString.contains('-')) {
      return DateTime.parse(dateString);
    } else if (dateString.contains('/')) {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    }
    throw FormatException('Formato de data inválido: $dateString');
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchUltimosGastos();
    fetchUltimasContas();
    fetchContasRecorrentes();
    fetchGastosParcelados();
  }

  // Método para buscar os dados do servidor
  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final userId = globals.userId;
      final response = await http.get(
        Uri.parse('http://192.168.15.114:3000/totais/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalContas = (data['total_contas'] ?? 0).toDouble();
          _totalGastos = (data['total_gastos'] ?? 0).toDouble();
          _totalGanhos = (data['total_ganhos'] ?? 0).toDouble();
        });
      } else {
        setState(() {
          _error = 'Erro ao carregar dados: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro de conexão: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para buscar os últimos 5 gastos
  Future<void> fetchUltimosGastos() async {
    try {
      final userId = globals.userId;
      final response = await http.get(
        Uri.parse('http://192.168.15.114:3000/ultimos-gastos/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ultimosGastos = data;
        });
      }
    } catch (e) {
      print('Erro ao buscar últimos gastos: $e');
    }
  }

  // Método para buscar as últimas 5 contas
  Future<void> fetchUltimasContas() async {
    try {
      final userId = globals.userId;
      final response = await http.get(
        Uri.parse('http://192.168.15.114:3000/ultimas-contas/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ultimasContas = data;
        });
      }
    } catch (e) {
      print('Erro ao buscar últimas contas: $e');
    }
  }

  // Método para buscar as contas recorrentes
  Future<void> fetchContasRecorrentes() async {
    try {
      final userId = globals.userId;
      final response = await http.get(
        Uri.parse('http://192.168.15.114:3000/contas-recorrentes/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _contasRecorrentes = data;
        });
      }
    } catch (e) {
      print('Erro ao buscar contas recorrentes: $e');
    }
  }

  // Método para buscar os gastos parcelados
  Future<void> fetchGastosParcelados() async {
    try {
      final userId = globals.userId;
      final response = await http.get(
        Uri.parse('http://192.168.15.114:3000/gastos-parcelados/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _gastosParcelados = data;
        });
      }
    } catch (e) {
      print('Erro ao buscar gastos parcelados: $e');
    }
  }

  // Método para calcular o saldo final
  double _calcularSaldo() {
    return _totalGanhos - _totalGastos - _totalContas;
  }

  // Método para gerar os dados do gráfico
  List<PieChartSectionData> _gerarDadosGrafico() {
    return [
      PieChartSectionData(
        value: _totalContas,
        color: Colors.blue,
        title: 'Contas\n${_totalContas.toStringAsFixed(2)}',
        radius: 50,
        titlePositionPercentageOffset: 0.8,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ),
      PieChartSectionData(
        value: _totalGastos,
        color: Colors.red,
        title: 'Gastos\n${_totalGastos.toStringAsFixed(2)}',
        radius: 50,
        titlePositionPercentageOffset: 0.8,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ),
      PieChartSectionData(
        value: _totalGanhos,
        color: Colors.green,
        title: 'Ganhos\n${_totalGanhos.toStringAsFixed(2)}',
        radius: 50,
        titlePositionPercentageOffset: 0.8,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Gastos'),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5), // Fundo cinza claro
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => GastoScreen()),
                        ).then((_) {
                          fetchData();
                          fetchUltimosGastos();
                          fetchGastosParcelados();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE), // Ciano
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Adicionar Gasto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AdicionaGanhoScreen()),
                        ).then((_) {
                          fetchData();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE), // Ciano
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Adicionar Ganho',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Gráfico de Pizza
              Container(
                height: 200,
                padding: const EdgeInsets.all(16.0),
                child: PieChart(
                  PieChartData(
                    sections: _gerarDadosGrafico(),
                  ),
                ),
              ),

              // Card para exibir o resumo financeiro
              _buildCard(
                title: 'Resumo Financeiro',
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : _error.isNotEmpty
                        ? Text('Erro: $_error')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildResumoItem('Total Contas', _totalContas),
                              _buildResumoItem('Total Gastos', _totalGastos),
                              _buildResumoItem('Total Ganhos', _totalGanhos),
                              _buildResumoItem(
                                'Saldo Final',
                                _calcularSaldo(),
                                isSaldo: true,
                              ),
                            ],
                          ),
              ),

              // Card para exibir os últimos gastos
              _buildCard(
                title: 'Últimos Gastos',
                child: _ultimosGastos.isEmpty
                    ? const Text('Nenhum gasto recente')
                    : Column(
                        children: _ultimosGastos.map<Widget>((gasto) {
                          final dataGasto = DateTime.parse(gasto['data']);
                          final dataFormatada =
                              '${dataGasto.day.toString().padLeft(2, '0')}/${dataGasto.month.toString().padLeft(2, '0')}/${dataGasto.year}';

                          return _buildListItem(
                            gasto['titulo'],
                            'R\$ ${double.parse(gasto['valor'].replaceAll(',', '.')).toStringAsFixed(2)} - $dataFormatada',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetalheGastoScreen(),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
              ),

              // Card para exibir as últimas contas
              _buildCard(
                title: 'Últimas Contas',
                child: _ultimasContas.isEmpty
                    ? const Text('Nenhuma conta recente')
                    : Column(
                        children: _ultimasContas.map<Widget>((conta) {
                          final dataConta = DateTime.parse(conta['data_conta']);
                          final dataFormatada =
                              '${dataConta.day.toString().padLeft(2, '0')}/${dataConta.month.toString().padLeft(2, '0')}/${dataConta.year}';

                          return _buildListItem(
                            conta['titulo'],
                            'R\$ ${double.parse(conta['valor'].replaceAll(',', '.')).toStringAsFixed(2)} - $dataFormatada',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetalheContaScreen(),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
              ),

              // Card para exibir as contas recorrentes
              _buildCard(
                title: 'Contas Recorrentes',
                child: _contasRecorrentes.isEmpty
                    ? const Text('Nenhuma conta recorrente')
                    : Column(
                        children: _contasRecorrentes.map((conta) {
                          return _buildListItem(
                            conta['titulo'],
                            'R\$ ${double.parse(conta['valor'].replaceAll(',', '.')).toStringAsFixed(2)} - Dia ${conta['dia_conta']}',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetalheContaScreen(),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
              ),

              // Card para exibir os gastos parcelados
              _buildCard(
                title: 'Gastos Parcelados',
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Mostrar apenas parcelas do mês atual',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: _mostrarApenasMesAtual,
                      onChanged: (value) {
                        setState(() {
                          _mostrarApenasMesAtual = value;
                        });
                      },
                    ),
                    _gastosParcelados.isEmpty
                        ? const Text('Nenhum gasto parcelado')
                        : Column(
                            children: _gastosParcelados.expand<Widget>((gasto) {
                              return gasto['parcelas'].where((parcela) {
                                if (_mostrarApenasMesAtual) {
                                  final hoje = DateTime.now();
                                  final mesAtual = hoje.month;
                                  final anoAtual = hoje.year;

                                  final dataParcela =
                                      parseCustomDate(parcela['data']);
                                  return dataParcela.month == mesAtual &&
                                      dataParcela.year == anoAtual;
                                } else {
                                  return true;
                                }
                              }).map<Widget>((parcela) {
                                final dataParcela =
                                    parseCustomDate(parcela['data']);
                                final dataFormatada =
                                    '${dataParcela.day.toString().padLeft(2, '0')}/${dataParcela.month.toString().padLeft(2, '0')}/${dataParcela.year}';

                                return _buildListItem(
                                  parcela['titulo'],
                                  'R\$ ${double.parse(parcela['valor'].replaceAll(',', '.')).toStringAsFixed(2)} - $dataFormatada',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetalheGastoScreen(),
                                      ),
                                    );
                                  },
                                );
                              }).toList();
                            }).toList(),
                          ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Método para construir um card
  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6200EE), // Roxo escuro
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  // Método para construir um item de resumo
  Widget _buildResumoItem(String label, double value, {bool isSaldo = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'R\$ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSaldo
                  ? (value >= 0 ? Colors.green : Colors.red)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir um item de lista
  Widget _buildListItem(String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
    );
  }
}
