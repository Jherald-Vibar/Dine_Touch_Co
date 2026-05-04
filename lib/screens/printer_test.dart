import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() => runApp(const MaterialApp(home: PrinterTest()));

class PrinterTest extends StatefulWidget {
  const PrinterTest({super.key});
  @override
  State<PrinterTest> createState() => _PrinterTestState();
}

class _PrinterTestState extends State<PrinterTest> {
  String _status = 'Idle';
  List<BluetoothDevice> _devices = [];
  BluetoothConnection? _connection;

  Future<void> _scan() async {
    setState(() => _status = 'Getting paired devices...');
    try {
      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devices = devices;
        _status = 'Found ${devices.length} paired device(s)';
      });
    } catch (e) {
      setState(() => _status = '❌ Scan error: $e');
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _status = 'Connecting to ${device.name}...');
    try {
      // Close existing connection first
      if (_connection != null && _connection!.isConnected) {
        await _connection!.close();
        _connection = null;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);

      setState(() {
        _connection = connection;
        _status = '✅ Connected to ${device.name}';
      });

      // Listen for disconnection
      connection.input!.listen(null).onDone(() {
        setState(() => _status = '⚠️ Printer disconnected');
        _connection = null;
      });
    } catch (e) {
      setState(() => _status = '❌ Connect error: $e');
    }
  }

  /// Send raw string as bytes
  Future<void> _send(String data) async {
    if (_connection == null || !_connection!.isConnected) {
      setState(() => _status = '❌ Not connected!');
      return;
    }
    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode(data)));
      await _connection!.output.allSent;
    } catch (e) {
      setState(() => _status = '❌ Send error: $e');
    }
  }

  Future<void> _printTSPL() async {
    if (_connection == null || !_connection!.isConnected) {
      setState(() => _status = '❌ Not connected!');
      return;
    }
    setState(() => _status = 'Sending TSPL commands...');
    try {
      // Send each command with a small delay
      await _send('SIZE 40 mm, 149 mm\r\n');
      await Future.delayed(const Duration(milliseconds: 100));
      await _send('GAP 0 mm, 0 mm\r\n');
      await Future.delayed(const Duration(milliseconds: 100));
      await _send('DIRECTION 0\r\n');
      await Future.delayed(const Duration(milliseconds: 100));
      await _send('CLS\r\n');
      await Future.delayed(const Duration(milliseconds: 200));

      await _send('TEXT 10,10,"3",0,1,1,"DINE TOUCH CO."\r\n');
      await Future.delayed(const Duration(milliseconds: 100));
      await _send('TEXT 10,60,"2",0,1,1,"------------------------"\r\n');
      await Future.delayed(const Duration(milliseconds: 100));
      await _send('TEXT 10,90,"2",0,1,1,"TEST RECEIPT"\r\n');
      await Future.delayed(const Duration(milliseconds: 100));
      await _send('TEXT 10,130,"2",0,1,1,"------------------------"\r\n');
      await Future.delayed(const Duration(milliseconds: 100));
      await _send('TEXT 10,160,"1",0,1,1,"1x Chicken Adobo   P185"\r\n');
      await Future.delayed(const Duration(milliseconds: 100));
      await _send('TEXT 10,190,"1",0,1,1,"1x Halo-Halo       P120"\r\n');
      await Future.delayed(const Duration(milliseconds: 100));
      await _send('TEXT 10,230,"2",0,1,1,"TOTAL:         P305"\r\n');
      await Future.delayed(const Duration(milliseconds: 100));
      await _send('TEXT 10,280,"1",0,1,1,"Thank you for dining!"\r\n');
      await Future.delayed(const Duration(milliseconds: 100));
      await _send('PRINT 1,1\r\n');
      await Future.delayed(const Duration(milliseconds: 200));

      await Future.delayed(const Duration(seconds: 2));
      setState(() => _status = '✅ TSPL sent! Did it print?');
    } catch (e) {
      setState(() => _status = '❌ Print error: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      await _connection?.close();
    } catch (_) {}
    setState(() {
      _connection = null;
      _status = 'Disconnected';
    });
  }

  bool get _isConnected => _connection != null && _connection!.isConnected;

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('XP-460B TSPL Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _status,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Scan Paired Devices'),
            ),
            const SizedBox(height: 8),

            // Device list
            ..._devices.map((d) => Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.print,
                      color: _isConnected ? Colors.green : Colors.grey,
                    ),
                    title: Text(d.name ?? 'Unknown'),
                    subtitle: Text(d.address),
                    trailing: ElevatedButton(
                      onPressed: () => _connect(d),
                      child: const Text('Connect'),
                    ),
                  ),
                )),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isConnected ? _printTSPL : null,
              icon: const Icon(Icons.print),
              label: const Text('Print TSPL Test Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _disconnect,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Disconnect'),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                '⚠️ Before testing:\n'
                '1. Xprinter app → Device Settings → Command Switch = TSPL\n'
                '2. Xprinter app → Paper Settings → Paper Type = Continuous\n'
                '3. Restart the printer after changing settings\n'
                '4. XP-460B must be paired in Android Bluetooth settings',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}