// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class ScanScreen extends StatelessWidget {
  final Function() onScan;

  // ignore: use_key_in_widget_constructors
  const ScanScreen({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onScan,
        child: const Text('Scan'),
      ),
    );
  }
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  String _csvFilePath = "";

  Future<void> _loadCsvFilePath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _csvFilePath = prefs.getString('csvFilePath')!;
    });
  }

  Future<void> _saveCsvFilePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('csvFilePath', path);
  }

  @override
  void initState() {
    super.initState();
    _loadCsvFilePath();
  }

  final List<Map<String, String>> _scannedBarcodes = [];

  void _scanBarcode() async {
    try {
      String barcode = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.BARCODE);
      if (barcode != "-1") {
        var csvContent = await File(_csvFilePath).readAsString();
        var lines = csvContent.split('\n');
        for (var line in lines) {
          var values = line.split(';');
          if (values[0].trim() == barcode.trim()) {
            setState(() {
              _scannedBarcodes.add(
                  {'barcode': barcode, 'result': 'Found', 'name': values[1]});
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
      final file = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      setState(() {
        _csvFilePath = file!.files.first.path!;
      });
      await _saveCsvFilePath(_csvFilePath);
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
              filePath: _csvFilePath,
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
          items: const <BottomNavigationBarItem>[
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
  final String filePath;
  const SelectCsvScreen(
      {super.key, required this.onSelect, required this.filePath});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Center(
          child: ElevatedButton(
            onPressed: onSelect,
            child: const Text('Select CSV File'),
          ),
        ),
        filePath == null || filePath.isEmpty
            ? Container()
            : Center(
                child: Text("Selected file: $filePath"),
              ),
      ],
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(scannedBarcodes[index]['result']!),
                const SizedBox(height: 5),
                Text(scannedBarcodes[index]['name']!),
              ],
            ),
          );
        });
  }
}
