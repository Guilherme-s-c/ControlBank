import 'package:flutter/material.dart';
import 'adiciona_conta.dart';  // Importando a tela de Adicionar Conta
import 'adiciona_gasto.dart'; // Importando a tela de Adicionar Gasto

class GastoScreen extends StatelessWidget {
  const GastoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Gasto'),
      ),
      body: Column(
        children: [
          // Botões para "Gastos" e "Conta"
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navegar para a tela de adicionar gasto
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdicionarGastoScreen()),
                    );
                  },
                  child: const Text('Gastos'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navegar para a tela de adicionar conta
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdicionaContaScreen()),
                    );
                  },
                  child: const Text('Conta'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
