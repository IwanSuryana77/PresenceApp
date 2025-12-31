import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class ClockInOutPage extends StatefulWidget {
  final String absenType; // "Clock In" atau "Clock Out"
  const ClockInOutPage({super.key, required this.absenType});

  @override
  State<ClockInOutPage> createState() => _ClockInOutPageState();
}

class _ClockInOutPageState extends State<ClockInOutPage> {
  String? catatan;
  Position? position;
  bool loading = true;
  File? fotoFile;

  CameraController? _camController;
  List<CameraDescription>? _cameras;
  bool selfieMode = false;

  @override
  void initState() {
    super.initState();
    ambilLokasiDanKamera();
  }

  @override
  void dispose() {
    _camController?.dispose();
    super.dispose();
  }

  Future<void> ambilLokasiDanKamera() async {
    setState(() => loading = true);
    await _ambilLokasi();
    await _initCamera();
    setState(() => loading = false);
  }

  Future<void> _ambilLokasi() async {
    LocationPermission p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;
    var pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => position = pos);
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras!.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );
    _camController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _camController?.initialize();
    setState(() => selfieMode = true);
  }

  Future<void> _ambilFoto() async {
    if (_camController == null || !_camController!.value.isInitialized) return;
    final XFile file = await _camController!.takePicture();
    final appDir = await getTemporaryDirectory();
    final localFile = await File(file.path).copy('${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    setState(() {
      fotoFile = localFile;
      selfieMode = false;
    });
    _camController?.dispose();
    _camController = null;
  }

  Future<void> kirimAbsen() async {
    setState(() => loading = true);

    // Foto: Kamu bisa upload ke Firebase Storage jika mau, ini hanya path lokal
    String fotoUrl = fotoFile?.path ?? "";

    double lat = position?.latitude ?? 0;
    double lng = position?.longitude ?? 0;

    await FirebaseFirestore.instance.collection("absen").add({
      "tipe": widget.absenType,
      "waktu": DateTime.now(),
      "catatan": catatan ?? "",
      "latitude": lat,
      "longitude": lng,
      "foto": fotoUrl,
    });

    setState(() => loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.absenType} berhasil!')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1B1E6D);
    const cardBg = Color(0xFFF2F3F8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          widget.absenType,
          style: const TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
            fontSize: 27,
          ),
        ),
        toolbarHeight: 60,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: navy))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 9),
                // Jadwal
                Container(
                  padding: const EdgeInsets.all(13),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("DayOn", style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 18)),
                      Row(
                        children: [
                          const Icon(Icons.folder_open, size: 18, color: navy),
                          const SizedBox(width: 7),
                          Text(
                            "${DateTime.now().day} ${_bulan(DateTime.now().month)} ${DateTime.now().year} (00:00 - 00:00)",
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                // Kamera/Preview Foto/Fitur Selfie
                Expanded(
                  child: Center(
                    child: selfieMode
                        ? _camController != null && _camController!.value.isInitialized
                            ? Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: _camController!.value.aspectRatio,
                                    child: CameraPreview(_camController!),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: navy,
                                          width: 2,
                                          style: BorderStyle.solid,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 15,
                                    left: 0,
                                    right: 0,
                                      child: Center(
                                        child: FloatingActionButton(
                                          backgroundColor: navy,
                                          onPressed: _ambilFoto,
                                          child: const Icon(Icons.camera_alt, color: Colors.white),
                                        ),
                                      ),
                                  ),
                                ],
                              )
                            : const Center(child: CircularProgressIndicator())
                        : fotoFile != null
                            ? Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: navy, width: 2, style: BorderStyle.solid),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(fotoFile!, fit: BoxFit.cover),
                                ),
                              )
                            : GestureDetector(
                                onTap: () async {
                                  await _initCamera();
                                  setState(() => selfieMode = true);
                                },
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: navy, width: 2, style: BorderStyle.solid),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.camera_alt, size: 80, color: navy),
                                  ),
                                ),
                              ),
                  ),
                ),
                // Bagian bawah: catatan, lokasi & btn
                Container(
                  margin: const EdgeInsets.only(left: 7, right: 7, bottom: 8, top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: navy, width: 1.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(26),
                      topRight: Radius.circular(26),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 3,
                        width: 58,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: navy,
                      ),
                      const SizedBox(height: 10),
                      // Catatan
                      ListTile(
                        leading: const Icon(Icons.receipt_long, color: Colors.black),
                        title: const Text(
                          "catatan",
                          style: TextStyle(color: navy, fontSize: 17, fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: navy),
                        onTap: () async {
                          final hasil = await _bukaCatatan();
                          if (hasil != null) setState(() => catatan = hasil);
                        },
                        subtitle: catatan == null
                            ? null
                            : Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(catatan!, style: const TextStyle(color: navy))),
                      ),
                      // Lokasi real time (AUTO tampil)
                      ListTile(
                        leading: const Icon(Icons.location_on, color: navy),
                        title: const Text("Lokasi sekarang", style: TextStyle(color: navy, fontSize: 17,fontWeight: FontWeight.w500)),
                        subtitle: position == null
                            ? const Text("Mengambil lokasi...", style: TextStyle(fontSize: 13, color: navy))
                            : Text(
                                "Lat: ${position!.latitude.toStringAsFixed(5)}, Lng: ${position!.longitude.toStringAsFixed(5)}",
                                style: const TextStyle(fontSize: 13, color: navy)),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: (position != null && fotoFile != null) ? kirimAbsen : null,
                          child: const Text("Kirim"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<String?> _bukaCatatan() async {
    String value = catatan ?? "";
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Catatan Absen"),
        content: TextField(
          controller: TextEditingController(text: value),
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(hintText: "Tulis catatan di sini..."),
          onChanged: (val) => value = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(onPressed: () => Navigator.pop(context, value), child: const Text("Simpan")),
        ],
      ),
    );
  }

  String _bulan(int bln) {
    const b = [
      "",
      "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
      "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
    ];
    return b[bln];
  }
}