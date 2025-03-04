import 'package:flutter/material.dart';

class DataProvider with ChangeNotifier {
  String _someData = 'Dados iniciais';

  String get someData => _someData;

  void updateData(String newData) {
    _someData = newData;
    notifyListeners(); // Notifica os listeners para atualizar a UI
  }
}
