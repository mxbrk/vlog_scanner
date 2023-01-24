/*import 'package:flutter/material.dart';
import 'app.dart';

main() {
  runApp(App());
}
*/
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  late String _csvFilePath;
  final List<Map<String, String>> _scannedBarcodes = [];

  void _scanBarcode() async {
    try {
      String barcode = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.BARCODE);
      if (barcode != null) {
        var csvContent = await File(_csvFilePath).readAsString();
        var lines = csvContent.split('\n');
        for (var line in lines) {
          var values = line.split(',');
          if (values[0] == barcode) {
            setState(() {
              _scannedBarcodes.add({'barcode': barcode, 'result': 'Found'});
            });
            return;
          }
        }
        setState(() {
          _scannedBarcodes.add({'barcode': barcode, 'result': 'Not found'});
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void _selectCsvFile() async {
    try {
      var file = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      setState(() {
        _csvFilePath = file as String;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            ScanScreen(
              onScan: _scanBarcode,
            ),
            SelectCsvScreen(
              onSelect: _selectCsvFile,
            ),
            ResultScreen(
              scannedBarcodes: _scannedBarcodes,
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: 'Select CSV',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Results',
            ),
          ],
        ),
      ),
    );
  }
}

class SelectCsvScreen extends StatelessWidget {
  final void Function() onSelect;
  const SelectCsvScreen({super.key, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onSelect,
        child: const Text('Select CSV File'),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final List<Map<String, String>> scannedBarcodes;

  const ResultScreen({super.key, required this.scannedBarcodes});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: scannedBarcodes.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(scannedBarcodes[index]['barcode']!),
          subtitle: Text(scannedBarcodes[index]['result']!),
        );
      },
    );
  }
}

class ScanScreen extends StatelessWidget {
  final void Function() onScan;
  const ScanScreen({super.key, required this.onScan});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onScan,
        child: const Text('Scan Barcode'),
      ),
    );
  }
}
