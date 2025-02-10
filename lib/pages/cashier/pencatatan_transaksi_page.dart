import 'dart:async';

import 'package:ace_rental/components/my_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PencatatanTransaksiPage extends StatefulWidget {
  @override
  State<PencatatanTransaksiPage> createState() => _PencatatanTransaksiPageState();
}

class _PencatatanTransaksiPageState extends State<PencatatanTransaksiPage> {
  // Collection untuk transaksi (data yang sudah selesai)
  final CollectionReference transactionCollection =
      FirebaseFirestore.instance.collection('transaction');
  // Collection untuk sesi bermain yang sedang berlangsung
  final CollectionReference playstationCollection =
      FirebaseFirestore.instance.collection('playstation');
  // Collection untuk rekap pemasukan per hari (shift)
  final CollectionReference monthlyTransactionCollection =
      FirebaseFirestore.instance.collection('monthlyTransaction');

  int? selectedPlayStation;

  // Variabel untuk sesi bermain
  String kategoriBermain = "Tetap"; // Pilihan: "Tetap" atau "Personal"
  int durasiTetap = 60; // Durasi bermain untuk kategori Tetap (dalam menit)

  Timer? _timer;

  // Variabel untuk manajemen shift
  bool shiftActive = false;
  String? currentShiftType; // "Pagi" atau "Malam"
  DateTime? shiftStartTime;

  @override
  void initState() {
    super.initState();
    _loadShiftState(); // Memuat status shift dari SharedPreferences
    // Timer untuk memicu rebuild widget setiap 30 detik (agar perhitungan warna selalu update)
    _timer = Timer.periodic(Duration(seconds: 30), (Timer t) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Fungsi SharedPreferences untuk menyimpan status shift ---

  Future<void> _loadShiftState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? storedShiftActive = prefs.getBool('shiftActive');
    if (storedShiftActive != null && storedShiftActive) {
      String? storedShiftType = prefs.getString('currentShiftType');
      String? storedShiftStartTime = prefs.getString('shiftStartTime');
      if (storedShiftType != null && storedShiftStartTime != null) {
        setState(() {
          shiftActive = true;
          currentShiftType = storedShiftType;
          shiftStartTime = DateTime.parse(storedShiftStartTime);
        });
      }
    }
  }

  Future<void> _saveShiftState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shiftActive', shiftActive);
    if (currentShiftType != null) {
      await prefs.setString('currentShiftType', currentShiftType!);
    }
    if (shiftStartTime != null) {
      await prefs.setString('shiftStartTime', shiftStartTime!.toIso8601String());
    }
  }

  Future<void> _clearShiftState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('shiftActive');
    await prefs.remove('currentShiftType');
    await prefs.remove('shiftStartTime');
  }

  // --- Fungsi Shift Management ---

  // Fungsi untuk memulai shift
  void startShift() async {
    if (shiftActive) return;
    // Tampilkan dialog untuk memilih shift
    String? selectedShift = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pilih Shift"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, "Pagi");
                },
                child: Text("Shift Pagi (10:00-19:00)"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, "Malam");
                },
                child: Text("Shift Malam (19:00-06:00)"),
              ),
            ],
          ),
        );
      },
    );

    if (selectedShift != null) {
      setState(() {
        shiftActive = true;
        currentShiftType = selectedShift;
        shiftStartTime = DateTime.now();
      });
      await _saveShiftState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Shift $selectedShift dimulai pada ${DateFormat("yyyy-MM-dd HH:mm").format(shiftStartTime!)}",
          ),
        ),
      );
    }
  }

  // Fungsi untuk mengakhiri shift
  void endShift() async {
    if (!shiftActive || shiftStartTime == null || currentShiftType == null) return;
    DateTime shiftEndTime = DateTime.now();

    // Query transaksi yang terjadi selama periode shift
    QuerySnapshot snapshot = await transactionCollection
        .where('waktuMulai', isGreaterThanOrEqualTo: shiftStartTime)
        .where('waktuMulai', isLessThanOrEqualTo: shiftEndTime)
        .get();

    int totalRevenue = 0;
    for (var doc in snapshot.docs) {
      totalRevenue += (doc['jumlahHarga'] as int);
    }

    // Format tanggal sebagai id dokumen (misal: "2025-02-10")
    String dateId = DateFormat("yyyy-MM-dd").format(shiftStartTime!);
    DocumentReference docRef = monthlyTransactionCollection.doc(dateId);
    DocumentSnapshot docSnap = await docRef.get();

    if (docSnap.exists) {
      // Jika dokumen sudah ada, perbarui field yang sesuai
      if (currentShiftType == "Pagi") {
        int currentValue = docSnap.get("pemasukan_shift_1") ?? 0;
        await docRef.update({"pemasukan_shift_1": currentValue + totalRevenue});
      } else {
        int currentValue = docSnap.get("pemasukan_shift_2") ?? 0;
        await docRef.update({"pemasukan_shift_2": currentValue + totalRevenue});
      }
    } else {
      // Jika belum ada, buat dokumen baru
      await docRef.set({
        "tanggal": dateId,
        "pemasukan_shift_1": currentShiftType == "Pagi" ? totalRevenue : 0,
        "pemasukan_shift_2": currentShiftType == "Malam" ? totalRevenue : 0,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Shift $currentShiftType berakhir. Total pemasukan: Rp $totalRevenue")),
    );

    setState(() {
      shiftActive = false;
      currentShiftType = null;
      shiftStartTime = null;
    });
    await _clearShiftState();
  }

  // --- Fungsi untuk Sesi Bermain PlayStation ---

  /// Fungsi untuk memulai sesi bermain per PlayStation
  Future<void> mulaiBermain() async {
    if (selectedPlayStation == null) return;
    DateTime now = DateTime.now();

    Map<String, dynamic> data = {
      "nomor": selectedPlayStation,
      "waktu_mulai": now,
      "status": "not_ready",
      "kategori_bermain": kategoriBermain,
    };

    if (kategoriBermain == "Tetap") {
      data["durasi"] = durasiTetap;
    } else {
      data["durasi"] = null;
    }

    try {
      await playstationCollection.add(data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Permainan PS $selectedPlayStation dimulai pada ${DateFormat("yyyy-MM-dd HH:mm").format(now)}",
          ),
        ),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error mulai bermain: $e")),
      );
    }
  }

  /// Fungsi untuk mengakhiri sesi bermain per PlayStation
  Future<void> akhiriPermainan(DocumentSnapshot psDoc) async {
    DateTime waktuMulai = (psDoc['waktu_mulai'] as Timestamp).toDate();
    String kategori = psDoc['kategori_bermain'] ?? "Personal";
    DateTime waktuSelesai;
    int jumlahHarga;

    if (kategori == "Tetap") {
      int durasiMenit = psDoc['durasi'] ?? 0;
      // Untuk kategori Tetap, waktu selesai sudah ditentukan (predet.)
      waktuSelesai = waktuMulai.add(Duration(minutes: durasiMenit));
      double jam = durasiMenit / 60.0;
      jumlahHarga = (jam * 9000).ceil();
    } else {
      // Untuk kategori Personal, waktu selesai diambil saat tombol ditekan
      waktuSelesai = DateTime.now();
      Duration diff = waktuSelesai.difference(waktuMulai);
      double jam = diff.inMinutes / 60.0;
      jumlahHarga = (jam * 9000).ceil();
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Akhiri Permainan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Waktu Mulai: ${DateFormat("yyyy-MM-dd HH:mm").format(waktuMulai)}"),
            Text("Waktu Selesai: ${DateFormat("yyyy-MM-dd HH:mm").format(waktuSelesai)}"),
            Text("Harga: Rp $jumlahHarga"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Konfirmasi"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await transactionCollection.add({
        "nomorPlaystation": selectedPlayStation,
        "waktuMulai": waktuMulai,
        "waktuSelesai": waktuSelesai,
        "jumlahHarga": jumlahHarga,
        "kategoriBermain": kategori,
        "status": "selesai"
      });

      await playstationCollection.doc(psDoc.id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaksi berhasil disimpan")),
      );
      setState(() {
        selectedPlayStation = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error menyimpan transaksi: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatatan Transaksi PlayStation'),
        actions: [
          // Tombol Shift: jika shift aktif, tampilkan tombol Akhiri Shift; jika tidak, tombol Mulai Shift
          shiftActive
              ? IconButton(
                  icon: Icon(Icons.stop),
                  tooltip: "Akhiri Shift",
                  onPressed: endShift,
                )
              : IconButton(
                  icon: Icon(Icons.play_arrow),
                  tooltip: "Mulai Shift",
                  onPressed: startShift,
                ),
        ],
      ),
      drawer: MyDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Tampilan info shift (jika shift aktif)
              if (shiftActive && currentShiftType != null && shiftStartTime != null)
                Card(
                  color: Colors.lightBlue[50],
                  child: ListTile(
                    title: Text("Shift $currentShiftType aktif"),
                    subtitle: Text("Dimulai: ${DateFormat("yyyy-MM-dd HH:mm").format(shiftStartTime!)}"),
                  ),
                ),
              // Daftar PlayStation (nomor 1-10) secara realtime
              StreamBuilder<QuerySnapshot>(
                stream: playstationCollection.snapshots(),
                builder: (context, snapshot) {
                  List<DocumentSnapshot> psDocs = [];
                  if (snapshot.hasData) {
                    psDocs = snapshot.data!.docs;
                  }
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(10, (index) {
                      int nomorPS = index + 1;
                      DocumentSnapshot? psDoc;
                      for (var doc in psDocs) {
                        if (doc['nomor'] == nomorPS) {
                          psDoc = doc;
                          break;
                        }
                      }
                      // Warna default hijau (PS ready)
                      Color avatarColor = Colors.green;
                      if (psDoc != null) {
                        String kategori = psDoc['kategori_bermain'] ?? "Personal";
                        if (kategori == "Tetap") {
                          DateTime waktuMulai = (psDoc['waktu_mulai'] as Timestamp).toDate();
                          int durasiMenit = psDoc['durasi'] ?? 0;
                          DateTime waktuSelesaiPred = waktuMulai.add(Duration(minutes: durasiMenit));
                          // Jika waktu saat ini sudah melebihi waktu predet (tetap), tampilkan kuning
                          if (DateTime.now().isAfter(waktuSelesaiPred)) {
                            avatarColor = Colors.yellow;
                          } else {
                            avatarColor = Colors.red;
                          }
                        } else {
                          // Untuk kategori Personal, langsung merah
                          avatarColor = Colors.red;
                        }
                      }
                      return GestureDetector(
                        onTap: () {
                          // Pastikan shift sudah aktif sebelum bisa memilih PlayStation
                          if (!shiftActive) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Mulai shift terlebih dahulu!")),
                            );
                            return;
                          }
                          setState(() {
                            selectedPlayStation = nomorPS;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: avatarColor,
                          radius: 30,
                          child: Text(
                            '$nomorPS',
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 20),
              // Jika ada PlayStation yang dipilih, tampilkan form/detail sesi
              if (selectedPlayStation != null)
                FutureBuilder<QuerySnapshot>(
                  future: playstationCollection
                      .where('nomor', isEqualTo: selectedPlayStation)
                      .limit(1)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    bool inUse = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    if (!inUse) {
                      // Jika PS ready, tampilkan form untuk memulai sesi
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("PlayStation Nomor: $selectedPlayStation"),
                              const SizedBox(height: 10),
                              // Dropdown untuk memilih kategori bermain
                              DropdownButton<String>(
                                value: kategoriBermain,
                                onChanged: (value) {
                                  setState(() {
                                    kategoriBermain = value!;
                                  });
                                },
                                items: const [
                                  DropdownMenuItem(
                                    value: "Tetap",
                                    child: Text("Tetap"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Personal",
                                    child: Text("Personal"),
                                  ),
                                ],
                              ),
                              // Jika kategori Tetap, tampilkan input durasi (menit)
                              if (kategoriBermain == "Tetap")
                                TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Durasi Bermain (menit)",
                                  ),
                                  onChanged: (value) {
                                    durasiTetap = int.tryParse(value) ?? 60;
                                  },
                                ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: mulaiBermain,
                                child: const Text("Mulai"),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Jika PS sedang dipakai, tampilkan detail sesi dan tombol "Akhiri Permainan"
                      DocumentSnapshot psDoc = snapshot.data!.docs.first;
                      DateTime waktuMulai =
                          (psDoc['waktu_mulai'] as Timestamp).toDate();
                      String kategori = psDoc['kategori_bermain'] ?? "Personal";
                      String detail =
                          "Waktu Mulai: ${DateFormat("yyyy-MM-dd HH:mm").format(waktuMulai)}\nKategori: $kategori";
                      if (kategori == "Tetap" && psDoc.data().toString().contains("durasi")) {
                        int durasiMenit = psDoc['durasi'] ?? 0;
                        DateTime waktuSelesaiTetap =
                            waktuMulai.add(Duration(minutes: durasiMenit));
                        detail += "\nWaktu Selesai (Predet.): ${DateFormat("yyyy-MM-dd HH:mm").format(waktuSelesaiTetap)}";
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("PlayStation Nomor: $selectedPlayStation"),
                              const SizedBox(height: 10),
                              Text(detail),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => akhiriPermainan(psDoc),
                                child: const Text("Akhiri Permainan"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
