import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/struk.dart';

class BluetoothPrinterService {
  static const String _savedMacKey = 'saved_printer_mac';
  static const String _savedNameKey = 'saved_printer_name';

  static const int _paperCharWidth58 = 32;
  static const int _fieldLabelWidth = 13;

  static int get previewColumns => _paperCharWidth58;

  static Future<String?> ensureReady() async {
    final hasPermission = await _ensureBluetoothPermissions();
    if (!hasPermission) {
      return 'Izin bluetooth belum diberikan. Aktifkan Nearby devices.';
    }

    final isBluetoothOn = await PrintBluetoothThermal.bluetoothEnabled;
    if (!isBluetoothOn) {
      return 'Bluetooth belum aktif. Aktifkan bluetooth lalu coba lagi.';
    }

    return null;
  }

  static Future<bool> _ensureBluetoothPermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final connectStatus = await Permission.bluetoothConnect.status;
    final scanStatus = await Permission.bluetoothScan.status;
    if (connectStatus.isGranted && scanStatus.isGranted) {
      return true;
    }

    final requestedConnect = await Permission.bluetoothConnect.request();
    final requestedScan = await Permission.bluetoothScan.request();

    return requestedConnect.isGranted && requestedScan.isGranted;
  }

  static Future<List<BluetoothInfo>> getPairedPrinters() async {
    final list = await PrintBluetoothThermal.pairedBluetooths;
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  static Future<bool> connect(String macAddress) async {
    final connected = await PrintBluetoothThermal.connectionStatus;
    if (connected) {
      return true;
    }
    return PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  static Future<String?> getSavedPrinterMac() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedMacKey);
  }

  static Future<String?> getSavedPrinterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedNameKey);
  }

  static Future<void> saveSelectedPrinter(BluetoothInfo printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedMacKey, printer.macAdress);
    await prefs.setString(_savedNameKey, printer.name);
  }

  static Future<void> clearSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedMacKey);
    await prefs.remove(_savedNameKey);
  }

  static Future<bool> printReceipt({
    required StrukModel transaksi,
    required String noTransaksi,
  }) async {
    try {
      final bytes = await _buildReceiptBytes(
        transaksi: transaksi,
        noTransaksi: noTransaksi,
      );
      return PrintBluetoothThermal.writeBytes(bytes);
    } catch (_) {
      return false;
    }
  }

  static String buildReceiptPreview({
    required StrukModel transaksi,
    required String noTransaksi,
  }) {
    final lines = _buildReceiptLines(
      transaksi: transaksi,
      noTransaksi: noTransaksi,
    );
    return lines.join('\n');
  }

  static Future<List<int>> _buildReceiptBytes({
    required StrukModel transaksi,
    required String noTransaksi,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    final lines = _buildReceiptLines(
      transaksi: transaksi,
      noTransaksi: noTransaksi,
    );

    List<int> bytes = <int>[];
    bytes += generator.reset();

    for (final line in lines) {
      if (line.isEmpty) {
        bytes += generator.feed(1);
      } else {
        bytes += generator.text(
          line,
          styles: const PosStyles(align: PosAlign.left),
        );
      }
    }

    bytes += generator.feed(3);
    return bytes;
  }

  static List<String> _buildReceiptLines({
    required StrukModel transaksi,
    required String noTransaksi,
  }) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final now = DateFormat(
      'dd MMM yyyy, HH:mm',
      'id_ID',
    ).format(DateTime.now());
    final normalizedStatus = transaksi.statusBayar.trim().toLowerCase();
    final statusBayar = _capitalizeWords(transaksi.statusBayar.trim());
    final isLunas = normalizedStatus == 'lunas';
    final sisaRaw = transaksi.totalHarga - transaksi.uangDiterima;
    final sisa = sisaRaw > 0 ? sisaRaw : 0;

    final lines = <String>[
      _centerText('LaundryKlin Tamansari'),
      _centerText('Gn Kanyere Gobras Tasikmalaya'),
      _centerText('085117006778'),
      '',
      _divider(),
      _centerText(now),
      _divider(),
      '',
    ];

    lines.addAll(_fieldLines(label: 'No. Transaksi', value: noTransaksi));
    lines.addAll(
      _fieldLines(label: 'Pelanggan', value: transaksi.namaPelanggan),
    );
    lines.addAll(_fieldLines(label: 'Kasir', value: transaksi.createdBy));
    lines.addAll(_fieldLines(label: 'Status', value: statusBayar));

    lines.add(_divider());
    lines.add('');
    lines.add('Daftar Layanan');
    lines.add('');

    if (transaksi.layananList.isEmpty) {
      lines.add('Tidak ada layanan');
    } else {
      for (var i = 0; i < transaksi.layananList.length; i++) {
        final layanan = transaksi.layananList[i];

        final jenis = _capitalizeWords(
          (layanan['jenis_layanan'] ?? '').toString(),
        );
        final nama = _capitalizeWords(
          (layanan['nama_layanan'] ?? '').toString(),
        );
        final isKiloan = jenis.toLowerCase() == 'kiloan';

        final harga = (layanan['harga_layanan'] is num)
            ? (layanan['harga_layanan'] as num).toInt()
            : int.tryParse(layanan['harga_layanan']?.toString() ?? '') ?? 0;
        final berat = (layanan['berat_layanan'] is num)
            ? (layanan['berat_layanan'] as num).toDouble()
            : double.tryParse(layanan['berat_layanan']?.toString() ?? '') ??
                  1.0;

        final durasi = _formatDurasi(layanan['durasi_layanan']);
        final totalLine = isKiloan ? (harga * berat).round() : harga;

        final itemTitle = '${i + 1}. $jenis - $nama';
        lines.addAll(_wrapText(itemTitle, _paperCharWidth58));

        final detailLine = isKiloan
            ? '$durasi | ${_formatBerat(berat)} Kg x ${currency.format(harga)}'
            : '$durasi | ${currency.format(harga)}';

        lines.addAll(_wrapText(detailLine, _paperCharWidth58));
        lines.addAll(
          _fieldLines(label: 'Subtotal', value: currency.format(totalLine)),
        );
        lines.add('');
      }
    }

    lines.add(_divider());
    lines.add('');
    lines.add('Catatan:');
    if (transaksi.catatan != null && transaksi.catatan!.trim().isNotEmpty) {
      lines.addAll(_wrapText(transaksi.catatan!.trim(), _paperCharWidth58));
    } else {
      lines.add('-');
    }

    lines.add(_divider());
    lines.add('');
    lines.addAll(
      _fieldLines(
        label: 'Grand Total',
        value: currency.format(transaksi.totalHarga),
      ),
    );
    if (isLunas) {
      lines.addAll(
        _fieldLines(
          label: 'Bayar',
          value: currency.format(transaksi.uangDiterima),
        ),
      );
      lines.addAll(
        _fieldLines(
          label: 'Kembali',
          value: currency.format(transaksi.kembalian),
        ),
      );
    } else {
      lines.addAll(_fieldLines(label: 'Sisa', value: currency.format(sisa)));
    }

    lines.add(_divider());
    lines.add('');
    lines.add(_centerText('Terima kasih'));

    return lines;
  }

  static List<String> _fieldLines({
    required String label,
    required String value,
  }) {
    final normalizedLabel = _padRight(label, _fieldLabelWidth);
    final prefix = '$normalizedLabel : ';
    final availableWidth = _paperCharWidth58 - prefix.length;

    if (value.trim().isEmpty || availableWidth <= 4) {
      return [prefix.trimRight()];
    }

    final wrappedValue = _wrapText(value, availableWidth);
    final lines = <String>[];
    for (var i = 0; i < wrappedValue.length; i++) {
      final segment = wrappedValue[i];
      if (i == 0) {
        final spacing = availableWidth - segment.length;
        lines.add('$prefix${_spaces(spacing)}$segment');
      } else {
        final spacing = _paperCharWidth58 - segment.length;
        lines.add('${_spaces(spacing)}$segment');
      }
    }

    return lines;
  }

  static List<String> _wrapText(String text, int width) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) {
      return [''];
    }

    final words = cleaned.split(' ');
    final lines = <String>[];
    var current = '';

    for (final word in words) {
      if (word.length > width) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }

        var start = 0;
        while (start < word.length) {
          final end = (start + width < word.length)
              ? start + width
              : word.length;
          lines.add(word.substring(start, end));
          start = end;
        }
        continue;
      }

      if (current.isEmpty) {
        current = word;
        continue;
      }

      final candidate = '$current $word';
      if (candidate.length <= width) {
        current = candidate;
      } else {
        lines.add(current);
        current = word;
      }
    }

    if (current.isNotEmpty) {
      lines.add(current);
    }

    return lines;
  }

  static String _divider() {
    return List.filled(_paperCharWidth58, '-').join();
  }

  static String _centerText(String text) {
    final normalized = text.trim();
    if (normalized.length >= _paperCharWidth58) {
      return normalized;
    }

    final leftPadding = ((_paperCharWidth58 - normalized.length) / 2).floor();
    return '${_spaces(leftPadding)}$normalized';
  }

  static String _spaces(int count) {
    if (count <= 0) {
      return '';
    }
    return List.filled(count, ' ').join();
  }

  static String _padRight(String text, int width) {
    final normalized = text.trim();
    if (normalized.length >= width) {
      return normalized.substring(0, width);
    }
    return '$normalized${_spaces(width - normalized.length)}';
  }

  static String _capitalizeWords(String text) {
    if (text.isEmpty) {
      return text;
    }

    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return word;
          }
          final first = word.substring(0, 1).toUpperCase();
          final remaining = word.substring(1).toLowerCase();
          return '$first$remaining';
        })
        .join(' ');
  }

  static String _formatDurasi(dynamic durasiRaw) {
    final durasi = (durasiRaw is num)
        ? durasiRaw.toInt()
        : int.tryParse(durasiRaw.toString()) ?? 0;

    if (durasi >= 24 && durasi % 24 == 0) {
      final hari = durasi ~/ 24;
      return '$hari Hari';
    }
    return '$durasi Jam';
  }

  static String _formatBerat(dynamic beratRaw) {
    final berat = (beratRaw is num)
        ? beratRaw.toDouble()
        : double.tryParse(beratRaw.toString()) ?? 0.0;

    if (berat == berat.truncateToDouble()) {
      return berat.toInt().toString();
    }
    return berat.toStringAsFixed(1);
  }
}
