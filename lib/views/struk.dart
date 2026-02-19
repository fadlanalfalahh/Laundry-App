import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:share_plus/share_plus.dart';
import '../models/struk.dart';
import '../services/bluetooth_printer_service.dart';

class StrukPage extends StatefulWidget {
  final StrukModel transaksi;
  final String noTransaksi;

  const StrukPage({
    super.key,
    required this.transaksi,
    required this.noTransaksi,
  });

  @override
  State<StrukPage> createState() => _StrukPageState();
}

class _StrukPageState extends State<StrukPage> {
  final GlobalKey _globalKey = GlobalKey();

  static const TextStyle _thermalStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.2,
    color: Colors.black87,
  );

  bool isCapturing = false;
  bool isPrinting = false;

  Future<Uint8List?> _captureStruk() async {
    try {
      final context = _globalKey.currentContext;
      if (context == null) {
        return null;
      }

      final boundary = context.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capture: $e');
      return null;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<BluetoothInfo?> _showPrinterPicker(List<BluetoothInfo> devices) async {
    if (devices.isEmpty) return null;

    return showDialog<BluetoothInfo>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pilih Printer Bluetooth'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (_, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.name.isEmpty ? 'Tanpa Nama' : device.name),
                  subtitle: Text(device.macAdress),
                  onTap: () => Navigator.of(dialogContext).pop(device),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _preparePrinterConnection() async {
    final error = await BluetoothPrinterService.ensureReady();
    if (error != null) {
      _showMessage(error);
      return false;
    }

    String? macAddress = await BluetoothPrinterService.getSavedPrinterMac();
    var isConnected = await PrintBluetoothThermal.connectionStatus;

    if (!isConnected && macAddress != null && macAddress.isNotEmpty) {
      isConnected = await BluetoothPrinterService.connect(macAddress);
      if (!isConnected) {
        await BluetoothPrinterService.clearSavedPrinter();
        macAddress = null;
      }
    }

    if (!isConnected) {
      final devices = await BluetoothPrinterService.getPairedPrinters();
      if (devices.isEmpty) {
        _showMessage(
          'Belum ada printer ter-pairing. Pair dulu printer RPP02 di pengaturan Bluetooth.',
        );
        return false;
      }

      final selected = await _showPrinterPicker(devices);
      if (selected == null) {
        return false;
      }

      await BluetoothPrinterService.saveSelectedPrinter(selected);
      isConnected = await BluetoothPrinterService.connect(selected.macAdress);
    }

    if (!isConnected) {
      _showMessage('Gagal terhubung ke printer.');
      return false;
    }

    return true;
  }

  Future<void> _printViaBluetooth() async {
    if (isPrinting) return;

    setState(() => isPrinting = true);
    try {
      final isReady = await _preparePrinterConnection();
      if (!isReady) return;

      final printed = await BluetoothPrinterService.printReceipt(
        transaksi: widget.transaksi,
        noTransaksi: widget.noTransaksi,
      );

      if (printed) {
        _showMessage('Struk berhasil dicetak.');
      } else {
        _showMessage('Gagal mengirim data ke printer.');
      }
    } catch (e) {
      _showMessage('Gagal print: $e');
    } finally {
      if (mounted) {
        setState(() => isPrinting = false);
      }
    }
  }

  double _paperWidth(BoxConstraints constraints) {
    final sample = 'W' * BluetoothPrinterService.previewColumns;
    final painter = TextPainter(
      text: TextSpan(text: sample, style: _thermalStyle),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: double.infinity);

    return math.min(constraints.maxWidth, painter.size.width + 28);
  }

  Widget _buildThermalPaper(
    String content, {
    required bool includeLogo,
    required bool selectable,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _paperWidth(constraints);

        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: width,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: isCapturing
                  ? []
                  : const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(2, 4),
                      ),
                    ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (includeLogo) ...[
                    Image.asset(
                      'assets/images/logostruk.png',
                      height: 80,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(
                            height: 80,
                            child: Center(
                              child: Text(
                                'LaundryKlin',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: selectable
                        ? SelectionArea(
                            child: Text(
                              content,
                              style: _thermalStyle,
                              softWrap: false,
                            ),
                          )
                        : Text(content, style: _thermalStyle, softWrap: false),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptText = BluetoothPrinterService.buildReceiptPreview(
      transaksi: widget.transaksi,
      noTransaksi: widget.noTransaksi,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text(
          'Struk Laundry',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _globalKey,
          child: _buildThermalPaper(
            receiptText,
            includeLogo: true,
            selectable: false,
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: isPrinting ? null : _printViaBluetooth,
              icon: Icon(isPrinting ? Icons.hourglass_top : Icons.print),
              label: Text(isPrinting ? 'Mencetak...' : 'Print'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() => isCapturing = true);
                final image = await _captureStruk();
                setState(() => isCapturing = false);

                if (image != null) {
                  final directory = await getTemporaryDirectory();
                  final imagePath = '${directory.path}/struk.png';
                  final file = File(imagePath);
                  await file.writeAsBytes(image);

                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(imagePath)],
                      text: 'Struk Laundry',
                    ),
                  );
                }
              },
              icon: const Icon(Icons.share),
              label: const Text('Bagikan'),
            ),
          ],
        ),
      ),
    );
  }
}
