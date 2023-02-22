// ignore_for_file: avoid_print, unnecessary_null_comparison
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'const.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

// BRANCH TEST TEST
//begin app
void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  String _csvFilePath = "";

  //loading the csv file
  Future<void> _loadCsvFilePath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _csvFilePath = prefs.getString('csvFilePath')!;
    });
  }

  //saving the csv-select filepath
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

  //function for scanning a barcode and check against the selected csv
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
              _scannedBarcodes.add({
                'barcode': barcode,
                'resultText': 'Barcode ist in der CSV-Datei vorhanden',
                'result': 'true',
                'name': values[1]
              });
            });
            return;
          }
        }
        setState(() {
          _scannedBarcodes.add({
            'barcode': barcode,
            'result': 'false',
            'resultText': 'Not found',
            'name': ''
          });
        });
      }
    } catch (e) {
      print(e);
    }
  }

  //functionn for selecting the csv file
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
                result: Result(_scannedBarcodes)),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: vlogGreen,
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

//scan screen
class ScanScreen extends StatelessWidget {
  final Function() onScan;

  // ignore: use_key_in_widget_constructors
  const ScanScreen({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onScan,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(vlogGreen),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(200.0),
            ),
          ),
          fixedSize: MaterialStateProperty.all<Size>(
            const Size(200, 200),
          ),
        ),
        child: const Text('Scan',
            style: TextStyle(
              fontSize: 28.0,
            )),
      ),
    );
  }
}

//select CSV-screen
class SelectCsvScreen extends StatelessWidget {
  final void Function() onSelect;
  final String filePath;
  const SelectCsvScreen(
      {super.key, required this.onSelect, required this.filePath});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center, // Zentrieren der Column vertikal
      children: <Widget>[
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: ElevatedButton(
            onPressed: onSelect,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(vlogGreen),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              fixedSize: MaterialStateProperty.all<Size>(
                const Size(200, 40),
              ),
            ),
            child: const Text('Select a CSV file',
                style: TextStyle(
                  fontSize: 18.0,
                )),
          ),
        ),
        filePath == null || filePath.isEmpty
            ? Container()
            : Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16.0, color: Colors.black),
                    children: [
                      const TextSpan(
                        text: '\nSelected file:\n',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: filePath,
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }
}

//result class (barcode -> csv exp)
class Result {
  final List<Map<String, String>> scannedBarcodes;

  Result(this.scannedBarcodes);

  List<List<dynamic>> get csvData {
    List<List<dynamic>> data = [];

    //add headers to data
    data.add(["Barcode", "Name", "Result"]);

    //add rows to data
    for (var barcode in scannedBarcodes) {
      data.add([barcode['barcode'], barcode['name'], barcode['result']]);
    }
    return data;
  }
}

//result screen definition
class ResultScreen extends StatelessWidget {
  final List<Map<String, String>> scannedBarcodes;
  final Result result;

  const ResultScreen(
      {Key? key, required this.scannedBarcodes, required this.result})
      : super(key: key);
  List<List<dynamic>> get csvData {
    List<List<dynamic>> data = [];

    //add headers to data
    data.add(["Barcode", "Name", "Result"]);

    //add rows to data
    for (var barcode in scannedBarcodes) {
      data.add([barcode['barcode'], barcode['name'], barcode['result']]);
    }

    return data;
  }

  //export to csv
  Future<void> exportToCsv() async {
    List<List<dynamic>> csvData = this.csvData;

    //get external storage directory
    Directory? directory = await getExternalStorageDirectory();
    String filePath = '${directory!.path}/scanned_barcodes.csv';

    //write csv file
    File file = File(filePath);
    String csv = const ListToCsvConverter().convert(csvData);
    await file.writeAsString(csv);
  }

  //result widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: result.scannedBarcodes.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(result.scannedBarcodes[index]['barcode']!,
                      style: TextStyle(
                        color: result.scannedBarcodes[index]['result'] == 'true'
                            ? Colors.green
                            : Colors.red,
                      )),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(result.scannedBarcodes[index]['resultText']!),
                      const SizedBox(height: 5),
                      Text(result.scannedBarcodes[index]['name']!),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 16, right: 16),
            child: ElevatedButton(
              onPressed: () {
                if (result != null) {
                  //FIX THIS!!! --> man sagt bitte
                  exportToCsv();
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(vlogGreen),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              child: const Text('Export to CSV'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
