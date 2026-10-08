import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// PACKAGE SYNCFUSION STABIL
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:syncfusion_officechart/officechart.dart' as oc;

// --- NOTIFIER TEMA GLOBAL ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const AplikasiBukuKas());
}

class AplikasiBukuKas extends StatelessWidget {
  const AplikasiBukuKas({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'FauzanPay',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0083B0), brightness: Brightness.light),
            scaffoldBackgroundColor: Colors.grey.shade50,
            useMaterial3: true,
            fontFamily: 'Roboto',
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey.shade50,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              systemOverlayStyle: const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark),
            ),
          ),
          
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0083B0), brightness: Brightness.dark),
            scaffoldBackgroundColor: const Color(0xFF121212),
            useMaterial3: true,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              systemOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
            ),
          ),
          home: const HalamanUtama(),
        );
      },
    );
  }
}

class Catatan {
  String id;
  String judul;
  double jumlah;
  bool isPemasukan;
  DateTime tanggal;

  Catatan({
    required this.id,
    required this.judul,
    required this.jumlah,
    required this.isPemasukan,
    required this.tanggal,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'judul': judul,
        'jumlah': jumlah,
        'isPemasukan': isPemasukan,
        'tanggal': tanggal.toIso8601String(),
      };

  factory Catatan.fromJson(Map<String, dynamic> json) => Catatan(
        id: json['id'],
        judul: json['judul'],
        jumlah: json['jumlah'],
        isPemasukan: json['isPemasukan'],
        tanggal: DateTime.parse(json['tanggal']),
      );

  String get tanggalTanpaJam {
    return DateFormat('yyyy-MM-dd').format(tanggal);
  }
}

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');
    double value = double.parse(cleanText);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    String newText = formatter.format(value);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  List<Catatan> _daftarCatatan = [];
  double _totalSaldo = 0;
  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  
  DateTime? _batasWaktuReset;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString('data_keuangan');
    final String? resetString = prefs.getString('batas_waktu_reset');
    
    if (resetString != null) _batasWaktuReset = DateTime.parse(resetString);

    if (dataString != null) {
      final List<dynamic> dataJson = json.decode(dataString);
      setState(() {
        _daftarCatatan = dataJson.map((item) => Catatan.fromJson(item)).toList();
      });
    }
    _hitungTotal();
  }

  Future<void> _simpanData() async {
    final prefs = await SharedPreferences.getInstance();
    final String dataString = json.encode(_daftarCatatan.map((e) => e.toJson()).toList());
    prefs.setString('data_keuangan', dataString);
  }

  Future<void> _simpanWaktuReset() async {
    final prefs = await SharedPreferences.getInstance();
    if (_batasWaktuReset != null) prefs.setString('batas_waktu_reset', _batasWaktuReset!.toIso8601String());
    else prefs.remove('batas_waktu_reset');
  }

  Future<void> _pindahkanKeSampah(List<Catatan> daftarDihapus) async {
    if (daftarDihapus.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final String? sampahString = prefs.getString('data_keuangan_sampah');
    List<Catatan> sampah = [];
    if (sampahString != null) {
      final List<dynamic> dataJson = json.decode(sampahString);
      sampah = dataJson.map((item) => Catatan.fromJson(item)).toList();
    }
    sampah.addAll(daftarDihapus);
    prefs.setString('data_keuangan_sampah', json.encode(sampah.map((e) => e.toJson()).toList()));
  }

  void _hitungTotal() {
    _totalPemasukan = 0;
    _totalPengeluaran = 0;
    for (var catatan in _daftarCatatan) {
      if (_batasWaktuReset == null || catatan.tanggal.isAfter(_batasWaktuReset!)) {
        if (catatan.isPemasukan) _totalPemasukan += catatan.jumlah;
        else _totalPengeluaran += catatan.jumlah;
      }
    }
    setState(() {
      _totalSaldo = _totalPemasukan - _totalPengeluaran;
      _daftarCatatan.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    });
  }

  void _tambahCatatan(String judul, double jumlah, bool isPemasukan) {
    final catatanBaru = Catatan(
      id: DateTime.now().toString(),
      judul: judul,
      jumlah: jumlah,
      isPemasukan: isPemasukan,
      tanggal: DateTime.now(),
    );
    setState(() {
      _daftarCatatan.add(catatanBaru);
    });
    _hitungTotal();
    _simpanData();
  }

  void _hapusCatatan(String id) {
    final catatanHapus = _daftarCatatan.firstWhere((c) => c.id == id);
    _pindahkanKeSampah([catatanHapus]);
    setState(() {
      _daftarCatatan.removeWhere((catatan) => catatan.id == id);
    });
    _hitungTotal();
    _simpanData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catatan dipindahkan ke histori sampah'), duration: Duration(seconds: 1)),
    );
  }

  void _tampilkanFormExport(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool exportAktif = true;
    bool exportSampah = false;
    bool exportPermanen = false;
    
    DateTime? filterMulai;
    DateTime? filterSelesai;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24, left: 24, right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Text('Pengaturan Export Excel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  const Text('Pilih Sumber Data:', style: TextStyle(fontWeight: FontWeight.w600)),
                  CheckboxListTile(
                    title: const Text('Transaksi Aktif'),
                    value: exportAktif,
                    onChanged: (val) => setModalState(() => exportAktif = val ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFF00B4DB),
                  ),
                  CheckboxListTile(
                    title: const Text('Histori Sampah'),
                    value: exportSampah,
                    onChanged: (val) => setModalState(() => exportSampah = val ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFF00B4DB),
                  ),
                  CheckboxListTile(
                    title: const Text('Sampah Permanen'),
                    value: exportPermanen,
                    onChanged: (val) => setModalState(() => exportPermanen = val ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFF00B4DB),
                  ),
                  
                  const SizedBox(height: 16),
                  const Text('Rentang Waktu (Opsional):', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(filterMulai == null ? 'Batas Awal' : DateFormat('dd MMM yyyy, HH:mm').format(filterMulai!)),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                            if (pickedDate != null && context.mounted) {
                              TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 0, minute: 0));
                              if (pickedTime != null) {
                                setModalState(() => filterMulai = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute));
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event_available, size: 18),
                          label: Text(filterSelesai == null ? 'Batas Akhir' : DateFormat('dd MMM yyyy, HH:mm').format(filterSelesai!)),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                            if (pickedDate != null && context.mounted) {
                              TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 23, minute: 59));
                              if (pickedTime != null) {
                                setModalState(() => filterSelesai = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute, 59));
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (filterMulai != null || filterSelesai != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setModalState(() { filterMulai = null; filterSelesai = null; }), 
                        child: const Text('Reset Waktu', style: TextStyle(color: Colors.redAccent))
                      ),
                    ),
                    
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (!exportAktif && !exportSampah && !exportPermanen) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal satu sumber data!')));
                        return;
                      }
                      Navigator.pop(context);
                      _prosesExportExcel(exportAktif, exportSampah, exportPermanen, filterMulai, filterSelesai);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Generate Excel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  // --- LOGIKA EXCEL DENGAN GRAFIK YANG SELALU MUNCUL ---
  Future<void> _prosesExportExcel(bool reqAktif, bool reqSampah, bool reqPermanen, DateTime? start, DateTime? end) async {
    final prefs = await SharedPreferences.getInstance();
    
    bool isDalamRentang(DateTime tgl) {
      if (start != null && tgl.isBefore(start)) return false;
      if (end != null && tgl.isAfter(end)) return false;
      return true;
    }

    List<Catatan> daftarAktif = [];
    if (reqAktif) {
      daftarAktif = List<Catatan>.from(_daftarCatatan)..sort((a, b) => a.tanggal.compareTo(b.tanggal));
      daftarAktif = daftarAktif.where((c) => isDalamRentang(c.tanggal)).toList();
    }
    
    List<Catatan> daftarSampah = [];
    if (reqSampah) {
      final String? sampahString = prefs.getString('data_keuangan_sampah');
      if (sampahString != null) {
        daftarSampah = (json.decode(sampahString) as List).map((i) => Catatan.fromJson(i)).toList();
        daftarSampah.sort((a, b) => a.tanggal.compareTo(b.tanggal));
        daftarSampah = daftarSampah.where((c) => isDalamRentang(c.tanggal)).toList();
      }
    }

    List<Catatan> daftarPermanen = [];
    if (reqPermanen) {
      final String? permanenString = prefs.getString('data_keuangan_sampah_permanen');
      if (permanenString != null) {
        daftarPermanen = (json.decode(permanenString) as List).map((i) => Catatan.fromJson(i)).toList();
        daftarPermanen.sort((a, b) => a.tanggal.compareTo(b.tanggal));
        daftarPermanen = daftarPermanen.where((c) => isDalamRentang(c.tanggal)).toList();
      }
    }

    if (daftarAktif.isEmpty && daftarSampah.isEmpty && daftarPermanen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada data pada rentang waktu tersebut!')));
      return;
    }

    final xlsio.Workbook workbook = xlsio.Workbook();
    int sheetCount = 0;

    void buatSheet(String namaSheet, List<Catatan> daftar) {
      xlsio.Worksheet sheet;
      if (sheetCount == 0) {
        sheet = workbook.worksheets[0];
        sheet.name = namaSheet;
      } else {
        sheet = workbook.worksheets.addWithName(namaSheet);
      }
      sheetCount++;

      // HILANGKAN GARIS LATAR BELAKANG OTOMATIS!
      sheet.showGridlines = false;

      // LEBAR KOLOM
      sheet.setColumnWidthInPixels(1, 100);
      sheet.setColumnWidthInPixels(2, 80);
      sheet.setColumnWidthInPixels(3, 200);
      sheet.setColumnWidthInPixels(4, 100);
      sheet.setColumnWidthInPixels(5, 150);

      // JUDUL LAPORAN 
      sheet.getRangeByIndex(1, 1).setText('Laporan Keuangan FauzanPay');
      sheet.getRangeByIndex(1, 1, 1, 5).merge();
      sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 14;
      sheet.getRangeByIndex(1, 1).cellStyle.hAlign = xlsio.HAlignType.center;

      sheet.getRangeByIndex(2, 1).setText('Tabel $namaSheet');
      sheet.getRangeByIndex(2, 1, 2, 5).merge();
      sheet.getRangeByIndex(2, 1).cellStyle.fontSize = 12;
      sheet.getRangeByIndex(2, 1).cellStyle.hAlign = xlsio.HAlignType.center;

      int rowIndex = 4;

      // HEADER TABEL 
      final headerRange = sheet.getRangeByIndex(rowIndex, 1, rowIndex, 5);
      sheet.getRangeByIndex(rowIndex, 1).setText('Tanggal');
      sheet.getRangeByIndex(rowIndex, 2).setText('Waktu');
      sheet.getRangeByIndex(rowIndex, 3).setText('Keterangan');
      sheet.getRangeByIndex(rowIndex, 4).setText('Kategori');
      sheet.getRangeByIndex(rowIndex, 5).setText('Nominal (Rp)');

      headerRange.cellStyle.bold = true;
      headerRange.cellStyle.hAlign = xlsio.HAlignType.center;
      headerRange.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      rowIndex++;

      if (daftar.isEmpty) {
        sheet.getRangeByIndex(rowIndex, 1).setText('Tidak Ada Data');
        sheet.getRangeByIndex(rowIndex, 1, rowIndex, 5).merge();
        sheet.getRangeByIndex(rowIndex, 1, rowIndex, 5).cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
        sheet.getRangeByIndex(rowIndex, 1, rowIndex, 5).cellStyle.hAlign = xlsio.HAlignType.center;
        return;
      }

      double totalMasuk = 0;
      double totalKeluar = 0;

      // TULIS DATA 
      for (var c in daftar) {
        String tanggal = DateFormat('dd/MM/yyyy').format(c.tanggal);
        String waktu = DateFormat('HH:mm').format(c.tanggal);
        String kategori = c.isPemasukan ? "Masuk" : "Keluar";

        sheet.getRangeByIndex(rowIndex, 1).setText(tanggal);
        sheet.getRangeByIndex(rowIndex, 2).setText(waktu);
        sheet.getRangeByIndex(rowIndex, 3).setText(c.judul);
        
        final katCell = sheet.getRangeByIndex(rowIndex, 4);
        katCell.setText(kategori);
        katCell.cellStyle.bold = true;
        katCell.cellStyle.fontColor = c.isPemasukan ? '#008000' : '#FF0000';

        final nomCell = sheet.getRangeByIndex(rowIndex, 5);
        nomCell.setNumber(c.jumlah); 
        nomCell.numberFormat = '"Rp"#,##0'; 
        nomCell.cellStyle.bold = true;
        nomCell.cellStyle.fontColor = c.isPemasukan ? '#008000' : '#FF0000';

        sheet.getRangeByIndex(rowIndex, 1, rowIndex, 5).cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

        if (c.isPemasukan) totalMasuk += c.jumlah;
        else totalKeluar += c.jumlah;
        rowIndex++;
      }

      int endDataRow = rowIndex - 1;

      // RINGKASAN BAWAH 
      sheet.getRangeByIndex(rowIndex, 1).setText('TOTAL PEMASUKAN');
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).merge();
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).cellStyle.bold = true;
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).cellStyle.hAlign = xlsio.HAlignType.right;
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      
      final tmCell = sheet.getRangeByIndex(rowIndex, 5);
      tmCell.setNumber(totalMasuk);
      tmCell.numberFormat = '"Rp"#,##0';
      tmCell.cellStyle.bold = true;
      tmCell.cellStyle.fontColor = '#008000';
      tmCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      rowIndex++;

      sheet.getRangeByIndex(rowIndex, 1).setText('TOTAL PENGELUARAN');
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).merge();
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).cellStyle.bold = true;
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).cellStyle.hAlign = xlsio.HAlignType.right;
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      
      final tkCell = sheet.getRangeByIndex(rowIndex, 5);
      tkCell.setNumber(totalKeluar);
      tkCell.numberFormat = '"Rp"#,##0';
      tkCell.cellStyle.bold = true;
      tkCell.cellStyle.fontColor = '#FF0000';
      tkCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      rowIndex++;

      sheet.getRangeByIndex(rowIndex, 1).setText('SISA SALDO KESELURUHAN');
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).merge();
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).cellStyle.bold = true;
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).cellStyle.hAlign = xlsio.HAlignType.right;
      sheet.getRangeByIndex(rowIndex, 1, rowIndex, 4).cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      
      final tsCell = sheet.getRangeByIndex(rowIndex, 5);
      tsCell.setNumber(totalMasuk - totalKeluar);
      tsCell.numberFormat = '"Rp"#,##0';
      tsCell.cellStyle.bold = true;
      tsCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

      // ========================================================
      // MENGGAMBAR GRAFIK GARIS (DIPAKSA MUNCUL MESKI 1 DATA)
      // ========================================================
      if (daftar.isNotEmpty) { // <-- INI YANG SAYA UBAH (Dari > 1 menjadi isNotEmpty)
        final oc.ChartCollection charts = oc.ChartCollection(sheet);
        final oc.Chart chart = charts.add();
        
        chart.chartType = oc.ExcelChartType.lineMarkers; 
        
        chart.dataRange = sheet.getRangeByName('E4:E$endDataRow'); 
        
        chart.chartTitle = 'Grafik Transaksi Harian';
        
        chart.topRow = rowIndex + 2;
        chart.bottomRow = rowIndex + 20; 
        chart.leftColumn = 1;
        chart.rightColumn = 7; 

        sheet.charts = charts;
      }
    }

    if (reqAktif) buatSheet('Transaksi Aktif', daftarAktif);
    if (reqSampah) buatSheet('Histori Sampah', daftarSampah);
    if (reqPermanen) buatSheet('Sampah Permanen', daftarPermanen);

    try {
      final List<int> fileBytes = workbook.saveAsStream();
      workbook.dispose(); 

      final direktori = await getTemporaryDirectory();
      final pathFile = "${direktori.path}/Laporan_FauzanPay_${DateFormat('MMM_yyyy').format(DateTime.now())}.xlsx";
      final file = File(pathFile);
      
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([XFile(pathFile)], text: 'Berikut laporan khusus FauzanPay beserta grafiknya.');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengekspor data: $e')));
    }
  }

  void _konfirmasiReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pilih Opsi Reset', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('1. Reset Kartu Saldo: Mengembalikan saldo ke Rp 0, riwayat di bawah tersimpan.\n\n2. Hapus Semua Data: Memindahkan SEMUA riwayat transaksi ke Histori Sampah.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              setState(() { _batasWaktuReset = DateTime.now(); });
              _hitungTotal(); _simpanWaktuReset(); Navigator.pop(context);
            },
            child: const Text('Reset Kartu', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              _pindahkanKeSampah(List.from(_daftarCatatan)); 
              setState(() { _daftarCatatan.clear(); _batasWaktuReset = null; });
              _hitungTotal(); _simpanData(); _simpanWaktuReset(); Navigator.pop(context);
            },
            child: const Text('Hapus Semua', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _tampilkanFormTambah(BuildContext context, bool isPemasukan) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final judulController = TextEditingController();
    final jumlahController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 24, left: 24, right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
              ),
              Text(
                isPemasukan ? 'Tambah Pemasukan' : 'Catat Pengeluaran',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: judulController,
                decoration: InputDecoration(
                  labelText: 'Keterangan Transaksi',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: jumlahController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, RupiahInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  prefixText: 'Rp ',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (judulController.text.isEmpty || jumlahController.text.isEmpty) return;
                  String angkaBersih = jumlahController.text.replaceAll('.', '');
                  double? jumlah = double.tryParse(angkaBersih);
                  if (jumlah != null && jumlah > 0) {
                    _tambahCatatan(judulController.text, jumlah, isPemasukan);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPemasukan ? const Color(0xFF00B4DB) : Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Simpan Catatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatRupiah(double angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(angka);
  }

  Widget _buildDaftarRiwayat() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_daftarCatatan.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Belum ada catatan hari ini.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }

    final groupedData = groupBy(_daftarCatatan, (Catatan c) => c.tanggalTanpaJam);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: groupedData.keys.length,
      itemBuilder: (context, index) {
        String tanggalGroup = groupedData.keys.elementAt(index);
        List<Catatan> catatanHariIni = groupedData[tanggalGroup]!;
        
        double masukHariIni = catatanHariIni.where((c) => c.isPemasukan).fold(0, (sum, item) => sum + item.jumlah);
        double keluarHariIni = catatanHariIni.where((c) => !c.isPemasukan).fold(0, (sum, item) => sum + item.jumlah);

        DateTime dt = DateTime.parse(tanggalGroup);
        String tanggalHeader = DateFormat('dd MMM yyyy').format(dt);
        String labelHari = tanggalHeader;
        DateTime now = DateTime.now();
        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) labelHari = "Hari Ini";
        else if (dt.year == now.year && dt.month == now.month && dt.day == now.day - 1) labelHari = "Kemarin";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(labelHari, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade500)),
                  Row(
                    children: [
                      if (masukHariIni > 0) Text('+${_formatRupiah(masukHariIni)} ', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      if (keluarHariIni > 0) Text('-${_formatRupiah(keluarHariIni)}', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            
            ...catatanHariIni.map((catatan) {
              bool isReset = _batasWaktuReset != null && catatan.tanggal.isBefore(_batasWaktuReset!);
              String jamTransaksi = DateFormat('HH:mm').format(catatan.tanggal);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.06),
                      spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isReset ? Colors.grey.withOpacity(0.15) : (catatan.isPemasukan ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      catatan.isPemasukan ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isReset ? Colors.grey : (catatan.isPemasukan ? Colors.green : Colors.redAccent),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    catatan.judul,
                    style: TextStyle(color: isReset ? Colors.grey : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.w600, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(jamTransaksi, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatRupiah(catatan.jumlah),
                        style: TextStyle(
                          color: isReset ? Colors.grey : (catatan.isPemasukan ? Colors.green : Colors.redAccent),
                          fontWeight: FontWeight.bold, fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _hapusCatatan(catatan.id),
                        child: Icon(Icons.close_rounded, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, size: 20),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FauzanPay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: isDark ? Colors.orangeAccent : Colors.grey.shade600),
            tooltip: 'Ubah Tema',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              if (isDark) {
                themeNotifier.value = ThemeMode.light;
                prefs.setBool('isDarkMode', false);
              } else {
                themeNotifier.value = ThemeMode.dark;
                prefs.setBool('isDarkMode', true);
              }
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.table_chart_rounded, color: Colors.green, size: 20),
            ),
            tooltip: 'Export ke Excel',
            onPressed: () => _tampilkanFormExport(context),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.black87),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'reset') _konfirmasiReset();
              else if (value == 'sampah') Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanSampah())).then((_) => _muatData());
              else if (value == 'sampah_permanen') Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanSampahPermanen()));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'reset', child: Row(children: [Icon(Icons.restart_alt, color: Colors.grey), SizedBox(width: 12), Text('Reset Data')])),
              const PopupMenuItem(value: 'sampah', child: Row(children: [Icon(Icons.delete_outline, color: Colors.grey), SizedBox(width: 12), Text('Histori Sampah')])),
              const PopupMenuItem(value: 'sampah_permanen', child: Row(children: [Icon(Icons.delete_forever, color: Colors.redAccent), SizedBox(width: 12), Text('Sampah Permanen')])),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0083B0).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8), size: 20),
                    const SizedBox(width: 8),
                    Text('Total Saldo Tersedia', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatRupiah(_totalSaldo),
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.arrow_downward, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 6),
                            Text('Pemasukan', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(_formatRupiah(_totalPemasukan), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 6),
                            Text('Pengeluaran', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(_formatRupiah(_totalPengeluaran), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(child: _buildDaftarRiwayat()),
          const SizedBox(height: 90),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: "btnKeluar",
                onPressed: () => _tampilkanFormTambah(context, false),
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                foregroundColor: Colors.redAccent,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: "btnMasuk",
                onPressed: () => _tampilkanFormTambah(context, true),
                backgroundColor: const Color(0xFF00B4DB),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Pemasukan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// --- LEVEL 1: HAL উভয় HISTORI SAMPAH ---
// ==========================================
class HalamanSampah extends StatefulWidget {
  const HalamanSampah({super.key});

  @override
  State<HalamanSampah> createState() => _HalamanSampahState();
}

class _HalamanSampahState extends State<HalamanSampah> {
  List<Catatan> _daftarSampah = [];
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _muatSampah();
  }

  Future<void> _muatSampah() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString('data_keuangan_sampah');
    if (dataString != null) {
      final List<dynamic> dataJson = json.decode(dataString);
      setState(() {
        _daftarSampah = dataJson.map((item) => Catatan.fromJson(item)).toList();
        _daftarSampah.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      });
    }
  }

  Future<void> _pindahkanKeSampahPermanen(List<Catatan> daftar) async {
    if (daftar.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString('data_keuangan_sampah_permanen');
    List<Catatan> sampahPermanen = [];
    if (dataString != null) sampahPermanen = (json.decode(dataString) as List).map((i) => Catatan.fromJson(i)).toList();
    sampahPermanen.addAll(daftar);
    prefs.setString('data_keuangan_sampah_permanen', json.encode(sampahPermanen.map((e) => e.toJson()).toList()));
  }

  Future<void> _kosongkanSampahPermanen() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
        title: const Text('Buang ke Sampah Permanen?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Semua data di histori sampah ini akan dipindahkan ke folder Sampah Permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              await _pindahkanKeSampahPermanen(List.from(_daftarSampah)); 
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('data_keuangan_sampah');
              setState(() => _daftarSampah.clear());
              if(context.mounted) Navigator.pop(context);
            },
            child: const Text('Ya, Pindahkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _pulihkanCatatan(Catatan catatan) async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataUtamaString = prefs.getString('data_keuangan');
    List<Catatan> dataUtama = [];
    if (dataUtamaString != null) dataUtama = (json.decode(dataUtamaString) as List).map((i) => Catatan.fromJson(i)).toList();
    dataUtama.add(catatan);
    prefs.setString('data_keuangan', json.encode(dataUtama.map((e) => e.toJson()).toList()));
    setState(() => _daftarSampah.removeWhere((c) => c.id == catatan.id));
    prefs.setString('data_keuangan_sampah', json.encode(_daftarSampah.map((e) => e.toJson()).toList()));
    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${catatan.judul}" dipulihkan')));
  }

  Future<void> _hapusCatatanKePermanen(Catatan catatan) async {
    await _pindahkanKeSampahPermanen([catatan]); 
    setState(() => _daftarSampah.removeWhere((c) => c.id == catatan.id));
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('data_keuangan_sampah', json.encode(_daftarSampah.map((e) => e.toJson()).toList()));
    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dipindah ke Sampah Permanen')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histori Sampah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        actions: [
          if (_daftarSampah.isNotEmpty)
            TextButton.icon(
              onPressed: _kosongkanSampahPermanen,
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              label: const Text('Kosongkan', style: TextStyle(color: Colors.redAccent)),
            )
        ],
      ),
      body: _daftarSampah.isEmpty
          ? Center(child: Text('Histori sampah bersih', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: _daftarSampah.length,
              itemBuilder: (context, index) {
                final catatan = _daftarSampah[index];
                String waktu = DateFormat('dd MMM yyyy, HH:mm').format(catatan.tanggal);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  child: ListTile(
                    title: Text(catatan.judul, style: TextStyle(fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough, color: Colors.grey.shade500)),
                    subtitle: Text(waktu, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatter.format(catatan.jumlah), style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.restore, color: Colors.blueAccent), onPressed: () => _pulihkanCatatan(catatan)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _hapusCatatanKePermanen(catatan)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// --- LEVEL 2: HALAMAN SAMPAH PERMANEN ---
// ==========================================
class HalamanSampahPermanen extends StatefulWidget {
  const HalamanSampahPermanen({super.key});

  @override
  State<HalamanSampahPermanen> createState() => _HalamanSampahPermanenState();
}

class _HalamanSampahPermanenState extends State<HalamanSampahPermanen> {
  List<Catatan> _daftarSampahPermanen = [];
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _muatSampahPermanen();
  }

  Future<void> _muatSampahPermanen() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataString = prefs.getString('data_keuangan_sampah_permanen');
    if (dataString != null) {
      final List<dynamic> dataJson = json.decode(dataString);
      setState(() {
        _daftarSampahPermanen = dataJson.map((item) => Catatan.fromJson(item)).toList();
        _daftarSampahPermanen.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      });
    }
  }

  Future<void> _musnahkanData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
        title: const Text('Musnahkan Selamanya?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Peringatan: Data yang dimusnahkan dari sini tidak akan pernah bisa dikembalikan lagi dari memori HP.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('data_keuangan_sampah_permanen');
              setState(() => _daftarSampahPermanen.clear());
              if(context.mounted) Navigator.pop(context);
            },
            child: const Text('Musnahkan Semua', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1111) : Colors.red.shade50,
      appBar: AppBar(
        title: const Text('Sampah Permanen', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.redAccent),
        actions: [
          if (_daftarSampahPermanen.isNotEmpty)
            TextButton.icon(
              onPressed: _musnahkanData,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Musnahkan', style: TextStyle(color: Colors.red)),
            )
        ],
      ),
      body: _daftarSampahPermanen.isEmpty
          ? Center(child: Text('Tidak ada tumpukan sampah.', style: TextStyle(color: Colors.red.shade200, fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: _daftarSampahPermanen.length,
              itemBuilder: (context, index) {
                final catatan = _daftarSampahPermanen[index];
                String waktu = DateFormat('dd MMM yyyy, HH:mm').format(catatan.tanggal);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF251818) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade100), 
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    ),
                    title: Text(catatan.judul, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                    subtitle: Text(waktu, style: const TextStyle(fontSize: 12)),
                    trailing: Text(formatter.format(catatan.jumlah), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
    );
  }
}