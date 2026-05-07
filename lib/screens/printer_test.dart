import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

void main() => runApp(const MaterialApp(home: PrinterTest()));

class PrinterTest extends StatefulWidget {
  const PrinterTest({super.key});
  @override
  State<PrinterTest> createState() => _PrinterTestState();
}

class _PrinterTestState extends State<PrinterTest> {
  String _status = 'Idle';
  List<BluetoothInfo> _devices = [];
  bool _isConnected = false;

  Future<void> _scan() async {
    setState(() => _status = 'Getting paired devices...');
    try {
      List<BluetoothInfo> devices =
          await PrintBluetoothThermal.pairedBluetooths;
      setState(() {
        _devices = devices;
        _status = 'Found ${devices.length} paired device(s)';
      });
    } catch (e) {
      setState(() => _status = '❌ Scan error: $e');
    }
  }

  Future<void> _connect(BluetoothInfo device) async {
    setState(() => _status = 'Connecting to ${device.name}...');
    try {
      bool result = await PrintBluetoothThermal.connect(
          macPrinterAddress: device.macAdress);
      setState(() {
        _isConnected = result;
        _status = result
            ? '✅ Connected to ${device.name}'
            : '❌ Failed to connect to ${device.name}';
      });
    } catch (e) {
      setState(() => _status = '❌ Connect error: $e');
    }
  }

Future<void> _send(String data) async {
  await PrintBluetoothThermal.writeBytes(data.codeUnits);
  await Future.delayed(const Duration(milliseconds: 100));
}

  Future<void> _printTSPL() async {
    if (!_isConnected) {
      setState(() => _status = '❌ Not connected!');
      return;
    }
    setState(() => _status = 'Sending TSPL commands...');
    try {
      await _send('SIZE 40 mm, 149 mm\r\n');
      await _send('GAP 0 mm, 0 mm\r\n');
      await _send('DIRECTION 1\r\n');
      await _send('CLS\r\n');

      await _send('TEXT 10,10,"3",0,1,1,"DINE TOUCH CO."\r\n');
      await _send('TEXT 10,60,"2",0,1,1,"------------------------"\r\n');
      await _send('TEXT 10,90,"2",0,1,1,"TEST RECEIPT"\r\n');
      await _send('TEXT 10,130,"2",0,1,1,"------------------------"\r\n');
      await _send('TEXT 10,160,"1",0,1,1,"1x Chicken Adobo   P185"\r\n');
      await _send('TEXT 10,190,"1",0,1,1,"1x Halo-Halo       P120"\r\n');
      await _send('TEXT 10,230,"2",0,1,1,"TOTAL:         P305"\r\n');
      await _send('TEXT 10,280,"1",0,1,1,"Thank you for dining!"\r\n');
      await _send('PRINT 1,1\r\n');
      await _send('EOP\r\n');

      await Future.delayed(const Duration(seconds: 3));
      setState(() => _status = '✅ TSPL sent! Did it print?');
    } catch (e) {
      setState(() => _status = '❌ Print error: $e');
    }
  }

  Future<void> _disconnect() async {
    await PrintBluetoothThermal.disconnect;
    setState(() {
      _isConnected = false;
      _status = 'Disconnected';
    });
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_status,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Scan Paired Devices'),
            ),
            const SizedBox(height: 8),

            ..._devices.map((d) => Card(
                  child: ListTile(
                    leading: Icon(Icons.print,
                        color: _isConnected ? Colors.green : Colors.grey),
                    title: Text(d.name),
                    subtitle: Text(d.macAdress),
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