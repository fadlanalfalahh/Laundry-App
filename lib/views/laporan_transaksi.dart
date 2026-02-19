import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/laporan_transaksi.dart';
import '../models/laporan_transaksi.dart';

class LaporanTransaksiPage extends StatefulWidget {
  const LaporanTransaksiPage({super.key});

  @override
  State<LaporanTransaksiPage> createState() => _LaporanTransaksiPageState();
}

class _LaporanTransaksiPageState extends State<LaporanTransaksiPage> {
  List<LaporanModel> _laporan = [];
  bool _loading = false;

  DateTime? _tglAwal;
  DateTime? _tglAkhir;

  final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dfDate = DateFormat('dd MMM yyyy', 'id_ID');
  final _dfTanggalFull = DateFormat('dd MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _tglAwal = today;
    _tglAkhir = today;
    _fetchLaporan();
  }

  Future<void> _fetchLaporan() async {
    setState(() => _loading = true);

    final data = await LaporanService.getLaporan(
      tglAwal: _tglAwal!.toIso8601String().substring(0, 10),
      tglAkhir: _tglAkhir!.toIso8601String().substring(0, 10),
    );

    setState(() {
      _laporan = data;
      _loading = false;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _tglAwal != null && _tglAkhir != null
          ? DateTimeRange(start: _tglAwal!, end: _tglAkhir!)
          : DateTimeRange(start: now, end: now),
    );

    if (picked != null) {
      setState(() {
        _tglAwal = picked.start;
        _tglAkhir = picked.end;
      });
      _fetchLaporan();
    }
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final totalKeseluruhan = _laporan.fold<int>(0, (sum, item) {
      if (item.statusBayar.toLowerCase() == 'batal') return sum;
      return sum + item.totalHarga;
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text(
                'Laporan Transaksi',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              _tglAwal == _tglAkhir
                  ? 'Tanggal: ${_dfTanggalFull.format(_tglAwal!)}'
                  : 'Tanggal: ${_dfTanggalFull.format(_tglAwal!)} s/d ${_dfTanggalFull.format(_tglAkhir!)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),

            // Tabel laporan
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
              defaultColumnWidth: const pw.IntrinsicColumnWidth(),
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    for (final h in [
                      'No',
                      'No Transaksi',
                      'Pelanggan',
                      'Kasir',
                      'Tanggal Transaksi',
                      'Status',
                      'Layanan',
                      'Total',
                    ])
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                  ],
                ),

                // Data rows
                ...List.generate(_laporan.length, (i) {
                  final lap = _laporan[i];
                  final kasirDepan = lap.createdBy.split(' ').first;
                  final namaDepanPelanggan = lap.namaPelanggan.split(' ').first;
                  final isBatal = lap.statusBayar.toLowerCase() == 'batal';

                  return pw.TableRow(
                    decoration: isBatal
                        ? const pw.BoxDecoration(color: PdfColors.red100)
                        : null,
                    children: [
                      // No
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          '${i + 1}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      // No Transaksi
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          lap.noTransaksi,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      // Pelanggan
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          namaDepanPelanggan,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      // Kasir
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          kasirDepan,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      // Tanggal Transaksi
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          _dfDate.format(
                            DateFormat('dd-MM-yyyy').parse(lap.createdAt),
                          ),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      // Status
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          capitalizeWords(lap.statusBayar),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      // Layanan
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          capitalizeWords(lap.jenisLayanan),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      // Total
                      pw.Container(
                        alignment: pw.Alignment.centerRight,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          isBatal ? '-' : _rupiah.format(lap.totalHarga),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 12),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  "Grand Total: ${_rupiah.format(totalKeseluruhan)}",
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildCellLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final rangeLabel = (_tglAwal == null || _tglAkhir == null)
        ? 'Semua Tanggal'
        : '${_dfDate.format(_tglAwal!)} - ${_dfDate.format(_tglAkhir!)}';

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          "Laporan Transaksi",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Pilih Tanggal',
            onPressed: _pickDateRange,
            icon: const Icon(Icons.calendar_today, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_tglAwal != null && _tglAkhir != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _tglAwal == _tglAkhir
                    ? 'Tanggal Transaksi ${_dfTanggalFull.format(_tglAwal!)}'
                    : 'Tanggal Transaksi ${_dfTanggalFull.format(_tglAwal!)} sampai ${_dfTanggalFull.format(_tglAkhir!)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

          // Isi laporan
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchLaporan,
                    child: _laporan.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 40),
                              Center(child: Text('Tidak ada transaksi.')),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _laporan.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final lap = _laporan[i];
                              final isBatal =
                                  lap.statusBayar.toLowerCase() == 'batal';

                              return Card(
                                color: isBatal ? Colors.red[100] : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "No. ${i + 1}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            lap.noTransaksi,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 12, thickness: 1),

                                      // Detail
                                      Table(
                                        columnWidths: const {
                                          0: IntrinsicColumnWidth(),
                                          1: FixedColumnWidth(12),
                                          2: FlexColumnWidth(),
                                        },
                                        defaultVerticalAlignment:
                                            TableCellVerticalAlignment.middle,
                                        children: [
                                          TableRow(
                                            children: [
                                              buildCellLabel("Kasir"),
                                              const Text(":"),
                                              Text(lap.createdBy),
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              buildCellLabel(
                                                "Tanggal Transaksi",
                                              ),
                                              const Text(":"),
                                              Text(
                                                _dfTanggalFull.format(
                                                  DateFormat(
                                                    'dd-MM-yyyy',
                                                  ).parse(lap.createdAt),
                                                ),
                                              ),
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              buildCellLabel("Nama Pelanggan"),
                                              const Text(":"),
                                              Text(lap.namaPelanggan),
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              buildCellLabel("Nomor Pelanggan"),
                                              const Text(":"),
                                              Text(lap.nomorPelanggan),
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              buildCellLabel("Total"),
                                              const Text(":"),
                                              Text(
                                                isBatal
                                                    ? '-'
                                                    : _rupiah.format(
                                                        lap.totalHarga,
                                                      ),
                                                style: TextStyle(
                                                  color: isBatal
                                                      ? Colors.red
                                                      : Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              buildCellLabel("Status"),
                                              const Text(":"),
                                              Text(
                                                capitalizeWords(
                                                  lap.statusBayar,
                                                ),
                                                style: TextStyle(
                                                  color: isBatal
                                                      ? Colors.red
                                                      : Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TableRow(
                                            children: [
                                              buildCellLabel("Layanan"),
                                              const Text(":"),
                                              Text(
                                                capitalizeWords(
                                                  lap.jenisLayanan,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (lap.detail.isNotEmpty)
                                            TableRow(
                                              children: [
                                                buildCellLabel(
                                                  "Detail Layanan",
                                                ),
                                                const Text(":"),
                                                Text(
                                                  lap.detail
                                                      .map((d) => d.namaLayanan)
                                                      .join(', '),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final pdfBytes = await _generatePdf();
          await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text(
          'Download PDF',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
