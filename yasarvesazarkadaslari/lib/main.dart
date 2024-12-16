import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

final String targetDeviceName = "ESP32 Tartı";

class _BluetoothAppState extends State<BluetoothApp> {
  FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  bool _isConnected = false;
  String _receivedData = "";

  // Bluetooth cihazlarını tarama ve bağlanma
  void _scanAndConnectToEsp32ByName() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name == targetDeviceName) {
          try {
            await _connectToDevice(r.device);
            FlutterBluePlus.stopScan();
            return;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cihaza bağlanırken hata oluştu!')),
            );
          }
        }
      }
    });
  }

  // Cihaza bağlanma
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
      });

      // Servisleri keşfet
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            _writeCharacteristic = characteristic;
          }
          if (characteristic.properties.notify || characteristic.properties.read) {
            _readCharacteristic = characteristic;
            _listenToCharacteristic(characteristic); // Veriyi dinlemeye başla
          }
        }
      }
    } catch (e) {
      print("Bağlantı hatası: $e");
    }
  }

  // Gelen veriyi dinleme
  void _listenToCharacteristic(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    characteristic.value.listen((value) {
      setState(() {
        _receivedData = String.fromCharCodes(value);
      });
      print("Gelen veri: $_receivedData");
    });
  }

  // Cihazdan bağlantıyı kesme
  Future<void> _disconnectFromDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _isConnected = false;
        _writeCharacteristic = null;
        _readCharacteristic = null;
        _receivedData = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('kedi maması'),
          leading: IconButton(
            icon: Icon(
              _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (_isConnected) {
                _disconnectFromDevice();
              } else {
                _scanAndConnectToEsp32ByName();
              }
            },
          ),
        ),
        body: Column(
          children: [
            if (_isConnected)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Gelen Veri: $_receivedData',
                  style: TextStyle(fontSize: 18, color: Colors.blue),
                ),
              ),
            if (!_isConnected)
              Center(
                child: Text(
                  'Cihaz Bağlı Değil',
                  style: TextStyle(fontSize: 20, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(BluetoothApp());
}
