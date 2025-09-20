import 'package:flutter/material.dart';
import '../models/group.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  NaGroup? _selectedGroup;
  double _radius = 1.0;
  int _quantity = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NA Posters'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<NaGroup>(
              decoration: const InputDecoration(
                labelText: 'Grupo NA',
              ),
              initialValue: _selectedGroup,
              items: naGroups.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGroup = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Raio de busca: ${_radius.toStringAsFixed(2)} km'),
            Slider(
              value: _radius,
              min: 0.5,
              max: 10.0,
              divisions: 95,
              label: _radius.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _radius = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Quantidade de cartazes: $_quantity'),
            Slider(
              value: _quantity.toDouble(),
              min: 1,
              max: 50,
              divisions: 49,
              label: '$_quantity',
              onChanged: (value) {
                setState(() {
                  _quantity = value.round();
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Funcionalidade em desenvolvimento')),
                  );
                },
                child: const Text('Gerar Recomendações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
