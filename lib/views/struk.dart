import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/struk.dart';

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({this.color = Colors.black, this.dashWidth = 5, this.dashSpace = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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

String capitalizeSentence(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

class _StrukPageState extends State<StrukPage> {
  final GlobalKey _globalKey = GlobalKey();
  bool isCapturing = false; // flag untuk hilangkan shadow saat print

  Future<Uint8List?> _captureStruk() async {
    try {
      RenderRepaintBoundary boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capture: $e");
    }
    return null;
  }

  // Formatter durasi → Hari/Jam
  String formatDurasi(dynamic durasiRaw) {
    final int d = (durasiRaw is num) ? durasiRaw.toInt()
        : int.tryParse(durasiRaw.toString()) ?? 0;

    if (d >= 24 && d % 24 == 0) {
      final int hari = d ~/ 24;
      return '$hari Hari';
    }
    return '$d Jam';
  }

  // Formatter berat
  String formatBerat(dynamic beratRaw) {
    final double b = (beratRaw is num) ? beratRaw.toDouble()
        : double.tryParse(beratRaw.toString()) ?? 0.0;

    // kalau bulat (contoh 4.0) tampilkan 4
    if (b == b.truncateToDouble()) {
      return b.toInt().toString();
    }

    // kalau ada pecahan tampilkan 1 digit desimal
    return b.toStringAsFixed(1);
  }

  // Helper untuk kapitalisasi huruf pertama tiap kata
  String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat("dd MMMM yyyy, HH:mm", "id_ID").format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text('Struk Laundry', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: RepaintBoundary(
            key: _globalKey,
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isCapturing ? [] : [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(2, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logostruk.png',
                      height: 100,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 100,
                        child: Center(
                          child: Text('LaundryKlin', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "LaundryKlin Tamansari",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text("Gn Kanyere Gobras Tasikmalaya"),
                    const Text("085117006778"),
                    const SizedBox(height: 8),
                    CustomPaint(size: Size(double.infinity, 1), painter: DashedLinePainter()),

                    // Tanggal
                    Text(
                      date,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    CustomPaint(size: Size(double.infinity, 1), painter: DashedLinePainter()),
                    const SizedBox(height: 8),

                    // Info Transaksi
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "No. Transaksi: ${widget.noTransaksi}\n"
                            "Pelanggan: ${widget.transaksi.namaPelanggan}\n"
                            "Kasir: ${widget.transaksi.createdBy}\n"
                            "Status: ${capitalizeWords(widget.transaksi.statusBayar)}",
                      ),
                    ),
                    CustomPaint(size: Size(double.infinity, 1), painter: DashedLinePainter()),
                    const SizedBox(height: 8),

                    // Daftar Layanan
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Daftar Layanan:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ...(widget.transaksi.layananList.isNotEmpty
                              ? widget.transaksi.layananList.map((layanan) {
                            // mapping layanan
                            final String jenis   = capitalizeWords((layanan['jenis_layanan']  ?? '').toString());
                            final String nama    = capitalizeWords((layanan['nama_layanan']   ?? '').toString());
                            final String sJenis  = jenis.toLowerCase();
                            final bool isKiloan  = (sJenis == 'kiloan');
                            final bool isPaket   = (sJenis == 'paket');

                            final int harga = (layanan['harga_layanan'] is num)
                                ? (layanan['harga_layanan'] as num).toInt()
                                : int.tryParse(layanan['harga_layanan']?.toString() ?? '') ?? 0;

                            final double berat = (layanan['berat_layanan'] != null)
                                ? double.tryParse(layanan['berat_layanan'].toString()) ?? 1.0
                                : 1.0;

                            final String durasiTeks = formatDurasi(layanan['durasi_layanan']);
                            final String beratTeks  = isPaket ? '${formatBerat(layanan['berat_layanan'])} kg, ' : '';

                            final int lineTotal = isPaket ? (harga * berat).round() : harga;

                            final String hargaTampil = NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(lineTotal);

                            return Text(
                                  () {
                                final bool isKiloan = sJenis == 'kiloan'; // hapus baris ini nanti
                                final int hargaSatuan = harga; // harga per Kg atau per layanan
                                final double jumlahBerat = isKiloan ? berat : 1.0;
                                final double totalLine = isKiloan ? (hargaSatuan * jumlahBerat) : hargaSatuan.toDouble();

                                final String hargaSatuanTampil = NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(hargaSatuan);

                                final String totalLineTampil = NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(totalLine.toInt());

                                if (isKiloan) {
                                  return "$jenis - $nama ($durasiTeks) : $hargaSatuanTampil x ${formatBerat(jumlahBerat)} Kg";
                                } else {
                                  return "$jenis - $nama ($durasiTeks) : $totalLineTampil";
                                }
                              }(),
                              style: const TextStyle(fontSize: 14),
                            );
                          }).toList()
                              : [const Text("Tidak ada layanan")]),

                          // Catatan
                          if (widget.transaksi.catatan != null &&
                              widget.transaksi.catatan!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            CustomPaint(size: Size(double.infinity, 1), painter: DashedLinePainter()),
                            const SizedBox(height: 6),
                            const Text(
                              "Catatan:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              capitalizeSentence(widget.transaksi.catatan!),
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    CustomPaint(size: Size(double.infinity, 1), painter: DashedLinePainter()),
                    const SizedBox(height: 8),

                    // Grand Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Grand Total", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.transaksi.totalHarga),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    if (widget.transaksi.statusBayar.toLowerCase() == 'lunas') ...[
                      // Bayar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Bayar"),
                          Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.transaksi.uangDiterima)),
                        ],
                      ),

                      // Kembali
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Kembali"),
                          Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.transaksi.kembalian)),
                        ],
                      ),
                    ] else ...[
                      // Sisa (kalau belum lunas)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Sisa", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(widget.transaksi.totalHarga - widget.transaksi.uangDiterima),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],

                    CustomPaint(size: Size(double.infinity, 1), painter: DashedLinePainter()),
                    const SizedBox(height: 8),
                    const Text("Terima Kasih"),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                setState(() => isCapturing = true);
                final image = await _captureStruk();
                setState(() => isCapturing = false);

                if (image != null) {
                  final pdf = pw.Document();
                  final pdfImage = pw.MemoryImage(image);

                  // ambil ukuran asli screenshot
                  final img = await decodeImageFromList(image);
                  final imgWidth = img.width.toDouble();
                  final imgHeight = img.height.toDouble();

                  final pdfWidth = 80 * PdfPageFormat.mm;
                  final pdfHeight = pdfWidth * (imgHeight / imgWidth);

                  pdf.addPage(
                    pw.Page(
                      pageFormat: PdfPageFormat(pdfWidth, pdfHeight),
                      margin: pw.EdgeInsets.zero,
                      build: (pw.Context context) {
                        return pw.FittedBox(
                          fit: pw.BoxFit.contain,
                          child: pw.ClipRRect(
                            horizontalRadius: 8,
                            verticalRadius: 8,
                            child: pw.Image(
                              pdfImage,
                              width: pdfWidth,
                              height: pdfHeight - 5, // crop sedikit biar tidak ada sisa
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  );

                  await Printing.layoutPdf(
                    onLayout: (format) async => pdf.save(),
                  );
                }
              },
              icon: const Icon(Icons.print),
              label: const Text("Print"),
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

                  await Share.shareXFiles([XFile(imagePath)], text: 'Struk Laundry');
                }
              },
              icon: const Icon(Icons.share),
              label: const Text("Bagikan"),
            ),
          ],
        ),
      ),
    );
  }
}
