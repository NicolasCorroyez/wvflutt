import 'package:flutter/material.dart';

class HidBarcode extends StatefulWidget {
  const HidBarcode({super.key});

  @override
  State<HidBarcode> createState() => _HidBarcodeState();
}

class _HidBarcodeState extends State<HidBarcode> {
  String _barcode = '';

  @override
  void initState() {
    super.initState();
  }

  /* String _cleanBarcode(List<int> byteList) {
    String decodedString = String.fromCharCodes(byteList);
    final cleanedValue = decodedString.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanedValue;
  } */

  void _onBarcodeEntered(value) {
    print("hello app");
    setState(() {
      _barcode = value.replaceAll(RegExp(r'[^0-9]'), '');
      print("Code-barres scanné : $_barcode");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan un code-barres')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Code-barres scanné :"),
              Text(
                _barcode.isEmpty ? "Aucun code-barres scanné." : _barcode,
                style: TextStyle(fontSize: 12),
              ),
              TextField(
                autofocus: true,
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  print("Code-barres scanné : $value");
                  /* List<int> byteList = value.codeUnits; */
                  _onBarcodeEntered(value);
                  print("byteList: $value");
                },
                decoration: const InputDecoration(
                  labelText: 'Scanner code-barres...',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
