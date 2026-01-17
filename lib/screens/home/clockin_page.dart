import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

const primaryPurple = Color(0xFF242484);
const greyBg = Color(0xFFEFEFF2);

class ClockInPage extends StatefulWidget {
  final String userId;
  final bool isCheckOut;

  const ClockInPage({
    required this.userId,
    required this.isCheckOut,
    super.key,
  });
  @override
  State<ClockInPage> createState() => _ClockInPageState();
}

class _ClockInPageState extends State<ClockInPage> {
  String? namaLokasi;
  double? latitude;
  double? longitude;
  XFile? fotoWajah;
  final TextEditingController _catatanCtrl = TextEditingController();
  bool _loading = false;
  bool _loadingLokasi = true;
  DateTime now = DateTime.now();

  get InputImage => null;

  @override
  void initState() {
    super.initState();
    _ambilLokasi();
  }

  Future<void> _ambilLokasi() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      String alamatLengkap = 'Lokasi tidak ditemukan';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final alamatParts = <String>[];
        if (place.street != null && place.street!.isNotEmpty)
          alamatParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          alamatParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty)
          alamatParts.add(place.locality!);
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty)
          alamatParts.add(place.administrativeArea!);
        if (place.country != null && place.country!.isNotEmpty)
          alamatParts.add(place.country!);
        alamatLengkap = alamatParts.join(', ');
      }

      setState(() {
        latitude = pos.latitude;
        longitude = pos.longitude;
        namaLokasi = alamatLengkap;
        _loadingLokasi = false;
      });
    } catch (e) {
      setState(() {
        namaLokasi = 'Lokasi gagal diambil: $e';
        _loadingLokasi = false;
      });
    }
  }

  Future<void> _ambilFoto() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CameraFaceDialog(
        onConfirm: (XFile fileResult) {
          setState(() => fotoWajah = fileResult);
        },
      ),
    );
  }

  // === ML Kit face detection ===
  Future<bool> _cekAdaWajah(File imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final faceDetector = FaceDetector(options: FaceDetectorOptions());
    final List<Face> faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();
    return faces.isNotEmpty; // True jika ada wajah
  }

  // Upload foto ke Storage, simpan info ke Firestore (cek wajah dulu)
  Future<void> _kirimAbsensi() async {
    if (fotoWajah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Foto wajah harus diambil terlebih dahulu'),
        ),
      );
      return;
    }
    if (latitude == null || longitude == null || namaLokasi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lokasi belum berhasil diambil')),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      // ==== DETEKSI WAJAH sebelum upload ====
      final adaWajah = await _cekAdaWajah(File(fotoWajah!.path));
      if (!adaWajah) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              '❌ Wajah tidak terdeteksi.\nUlangi pengambilan foto.',
            ),
          ),
        );
        return;
      }
      // ==== Lanjut upload ====
      String? urlFoto;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final ref = FirebaseStorage.instance.ref(
        'absensi_photo/${widget.userId}_${timestamp}.jpg',
      );
      await ref.putFile(File(fotoWajah!.path));
      urlFoto = await ref.getDownloadURL();

      final hariKey = DateFormat('yyyy-MM-dd').format(now);
      final waktuFormatted = DateFormat('HH:mm:ss').format(now);

      final absenData = {
        'waktu': waktuFormatted,
        'jam_masuk_pulang': widget.isCheckOut ? 'Jam Pulang' : 'Jam Masuk',
        'koordinat': {'latitude': latitude, 'longitude': longitude},
        'nama_lokasi': namaLokasi,
        'catatan': _catatanCtrl.text.trim(),
        'fotoUrl': urlFoto ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      };

      final checkInKey = widget.isCheckOut ? 'checkOut' : 'checkIn';
      await FirebaseFirestore.instance
          .collection('absensi')
          .doc(widget.userId)
          .collection('hari')
          .doc(hariKey)
          .set({checkInKey: absenData}, SetOptions(merge: true));

      setState(() => _loading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${widget.isCheckOut ? "Jam pulang" : "Jam masuk"} berhasil dicatat!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tStyleTitle = TextStyle(
      color: primaryPurple,
      fontWeight: FontWeight.bold,
      fontSize: 21,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isCheckOut ? 'Jam Pulang' : 'Jam Masuk',
          style: tStyleTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: greyBg,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  'DayOn',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.folder_open, color: primaryPurple),
                    SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy (HH:mm)', 'id_ID').format(now),
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Foto Wajah',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryPurple,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _ambilFoto,
            child: Container(
              width: double.infinity,
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: greyBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryPurple, width: 1.2),
              ),
              child: fotoWajah == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: primaryPurple, size: 50),
                        const SizedBox(height: 8),
                        Text(
                          'Tap untuk ambil foto',
                          style: TextStyle(color: primaryPurple),
                        ),
                      ],
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.file(
                          File(fotoWajah!.path),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => fotoWajah = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Lokasi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryPurple,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: greyBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: _loadingLokasi
                ? Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(primaryPurple),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Mengambil lokasi...',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: primaryPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              namaLokasi ?? 'Lokasi tidak ditemukan',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (latitude != null && longitude != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.map,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Koordinat',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            'Catatan (Opsional)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryPurple,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _catatanCtrl,
            decoration: InputDecoration(
              hintText: 'Tulis catatan tambahan...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryPurple, width: 2),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                disabledBackgroundColor: Colors.grey[400],
              ),
              onPressed: _loading ? null : _kirimAbsensi,
              child: _loading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.isCheckOut
                          ? 'Kirim Jam Pulang'
                          : 'Kirim Jam Masuk',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ---------- Widget Kamera Modal dengan Konfirmasi ----------
class CameraFaceDialog extends StatefulWidget {
  final Function(XFile) onConfirm;
  const CameraFaceDialog({required this.onConfirm, super.key});
  @override
  State<CameraFaceDialog> createState() => _CameraFaceDialogState();
}

class _CameraFaceDialogState extends State<CameraFaceDialog> {
  CameraController? controller;
  XFile? file;
  bool takingPicture = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    controller = CameraController(
      frontCam,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller?.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _takePicture() async {
    if (controller == null || !controller!.value.isInitialized) return;
    setState(() => takingPicture = true);
    try {
      final XFile image = await controller!.takePicture();
      setState(() => file = image);
    } finally {
      setState(() => takingPicture = false);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file == null)
              (controller != null && controller!.value.isInitialized)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: controller!.value.aspectRatio,
                        child: CameraPreview(controller!),
                      ),
                    )
                  : Container(
                      height: 220,
                      alignment: Alignment.center,
                      child: const Text('Memuat kamera...'),
                    ),
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(file!.path),
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 18),
            Text(
              file == null ? 'Cek Wajah...' : 'Sudah cocok?',
              style: const TextStyle(
                color: primaryPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: file == null
                          ? Colors.blue
                          : primaryPurple,
                    ),
                    onPressed: file == null
                        ? (takingPicture ? null : _takePicture)
                        : () {
                            widget.onConfirm(file!);
                            Navigator.pop(context);
                          },
                    child: file == null
                        ? (takingPicture
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.camera_alt, size: 26))
                        : const Text('Konfirmasi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:io';
// import 'package:intl/intl.dart';

// const primaryPurple = Color(0xFF242484);
// const greyBg = Color(0xFFEFEFF2);

// class ClockInPage extends StatefulWidget {
//   final String userId; // sebagai penanda user asal
//   final bool isCheckOut; // true jika jam pulang, false jika jam masuk

//   const ClockInPage({
//     required this.userId,
//     required this.isCheckOut,
//     super.key,
//   });
//   @override
//   State<ClockInPage> createState() => _ClockInPageState();
// }

// class _ClockInPageState extends State<ClockInPage> {
//   String? namaLokasi; // Nama alamat dari reverse geocoding
//   double? latitude;
//   double? longitude;
//   XFile? fotoWajah;
//   final TextEditingController _catatanCtrl = TextEditingController();
//   bool _loading = false;
//   bool _loadingLokasi = true;

//   DateTime now = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _ambilLokasi();
//   }

//   // Ambil koordinat & nama lokasi (reverse geocoding)
//   Future<void> _ambilLokasi() async {
//     try {
//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       // Reverse geocoding untuk mendapatkan nama alamat
//       final List<Placemark> placemarks = await placemarkFromCoordinates(
//         pos.latitude,
//         pos.longitude,
//       );

//       String alamatLengkap = 'Lokasi tidak ditemukan';
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         // Susun alamat lengkap: jalan, area, kota, negara
//         final alamatParts = <String>[];
//         if (place.street != null && place.street!.isNotEmpty)
//           alamatParts.add(place.street!);
//         if (place.subLocality != null && place.subLocality!.isNotEmpty)
//           alamatParts.add(place.subLocality!);
//         if (place.locality != null && place.locality!.isNotEmpty)
//           alamatParts.add(place.locality!);
//         if (place.administrativeArea != null &&
//             place.administrativeArea!.isNotEmpty)
//           alamatParts.add(place.administrativeArea!);
//         if (place.country != null && place.country!.isNotEmpty)
//           alamatParts.add(place.country!);

//         alamatLengkap = alamatParts.join(', ');
//       }

//       setState(() {
//         latitude = pos.latitude;
//         longitude = pos.longitude;
//         namaLokasi = alamatLengkap;
//         _loadingLokasi = false;
//       });
//     } catch (e) {
//       setState(() {
//         namaLokasi = 'Lokasi gagal diambil: $e';
//         _loadingLokasi = false;
//       });
//     }
//   }

//   // Ambil foto wajah (kamera depan & show konfirmasi dialog)
//   Future<void> _ambilFoto() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => CameraFaceDialog(
//         onConfirm: (XFile fileResult) {
//           setState(()=> fotoWajah = fileResult);
//         },
//       ),
//     );
//   }

//   // Upload foto ke Storage, simpan info ke Firestore (termasuk nama alamat dari maps)
//   Future<void> _kirimAbsensi() async {
//     // Validasi data wajib
//     if (fotoWajah == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('❌ Foto wajah harus diambil terlebih dahulu'),
//         ),
//       );
//       return;
//     }

//     if (latitude == null || longitude == null || namaLokasi == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('❌ Lokasi belum berhasil diambil')),
//       );
//       return;
//     }

//     setState(() => _loading = true);

//     try {
//       String? urlFoto;

//       // Upload foto ke Firebase Storage
//       if (fotoWajah != null) {
//         final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
//         final ref = FirebaseStorage.instance.ref(
//           'absensi_photo/${widget.userId}_${timestamp}.jpg',
//         );
//         await ref.putFile(File(fotoWajah!.path));
//         urlFoto = await ref.getDownloadURL();
//       }

//       // Siapkan data yang akan dikirim ke Firestore
//       final hariKey = DateFormat('yyyy-MM-dd').format(now);
//       final waktuFormatted = DateFormat('HH:mm:ss').format(now);

//       // Data readable dan lengkap
//       final absenData = {
//         'waktu': waktuFormatted,
//         'jam_masuk_pulang': widget.isCheckOut ? 'Jam Pulang' : 'Jam Masuk',
//         'koordinat': {'latitude': latitude, 'longitude': longitude},
//         'nama_lokasi': namaLokasi,
//         'catatan': _catatanCtrl.text.trim(),
//         'fotoUrl': urlFoto ?? '',
//         'timestamp': FieldValue.serverTimestamp(),
//       };

//       // Simpan ke Firestore
//       final checkInKey = widget.isCheckOut ? 'checkOut' : 'checkIn';
//       await FirebaseFirestore.instance
//           .collection('absensi')
//           .doc(widget.userId)
//           .collection('hari')
//           .doc(hariKey)
//           .set({checkInKey: absenData}, SetOptions(merge: true));

//       setState(() => _loading = false);

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             '✅ ${widget.isCheckOut ? "Jam pulang" : "Jam masuk"} berhasil dicatat!',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       setState(() => _loading = false);
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final tStyleTitle = TextStyle(
//       color: primaryPurple,
//       fontWeight: FontWeight.bold,
//       fontSize: 21,
//     );
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: primaryPurple),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           widget.isCheckOut ? 'Jam Pulang' : 'Jam Masuk',
//           style: tStyleTitle,
//         ),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.symmetric(horizontal: 24),
//         children: [
//           const SizedBox(height: 10),
//           Container(
//             decoration: BoxDecoration(
//               color: greyBg,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             padding: const EdgeInsets.all(10),
//             child: Column(
//               children: [
//                 Text(
//                   'DayOn',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: primaryPurple,
//                     fontSize: 18,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Icon(Icons.folder_open, color: primaryPurple),
//                     SizedBox(width: 8),
//                     Text(
//                       DateFormat('dd MMM yyyy (HH:mm)', 'id_ID').format(now),
//                       style: TextStyle(color: Colors.black54, fontSize: 16),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             'Foto Wajah',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: primaryPurple,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 8),
//           GestureDetector(
//             onTap: _ambilFoto,
//             child: Container(
//               width: double.infinity,
//               height: 200,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 color: greyBg,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: primaryPurple, width: 1.2),
//               ),
//               child: fotoWajah == null
//                   ? Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.camera_alt, color: primaryPurple, size: 50),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Tap untuk ambil foto',
//                           style: TextStyle(color: primaryPurple),
//                         ),
//                       ],
//                     )
//                   : Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         Image.file(
//                           File(fotoWajah!.path),
//                           width: double.infinity,
//                           height: 200,
//                           fit: BoxFit.cover,
//                         ),
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: GestureDetector(
//                             onTap: () => setState(() => fotoWajah = null),
//                             child: Container(
//                               padding: const EdgeInsets.all(4),
//                               decoration: BoxDecoration(
//                                 color: Colors.red,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Icon(
//                                 Icons.close,
//                                 color: Colors.white,
//                                 size: 18,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'Lokasi',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: primaryPurple,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: greyBg,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: primaryPurple.withOpacity(0.3),
//                 width: 1,
//               ),
//             ),
//             child: _loadingLokasi
//                 ? Row(
//                     children: [
//                       SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation(primaryPurple),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Mengambil lokasi...',
//                         style: TextStyle(color: Colors.black54),
//                       ),
//                     ],
//                   )
//                 : Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on,
//                             color: primaryPurple,
//                             size: 20,
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               namaLokasi ?? 'Lokasi tidak ditemukan',
//                               style: TextStyle(
//                                 color: Colors.black87,
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 13,
//                               ),
//                               maxLines: 3,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (latitude != null && longitude != null) ...[
//                         const SizedBox(height: 10),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 8,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.map,
//                                 color: Colors.grey[600],
//                                 size: 16,
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Koordinat',
//                                       style: TextStyle(
//                                         color: Colors.black54,
//                                         fontSize: 11,
//                                       ),
//                                     ),
//                                     Text(
//                                       '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
//                                       style: TextStyle(
//                                         color: Colors.black87,
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'Catatan (Opsional)',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: primaryPurple,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextField(
//             controller: _catatanCtrl,
//             decoration: InputDecoration(
//               hintText: 'Tulis catatan tambahan...',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: Colors.grey[300]!),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: Colors.grey[300]!),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: primaryPurple, width: 2),
//               ),
//               contentPadding: const EdgeInsets.all(14),
//             ),
//             maxLines: 3,
//           ),
//           const SizedBox(height: 24),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryPurple,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 padding: const EdgeInsets.symmetric(vertical: 18),
//                 disabledBackgroundColor: Colors.grey[400],
//               ),
//               onPressed: _loading ? null : _kirimAbsensi,
//               child: _loading
//                   ? SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2,
//                       ),
//                     )
//                   : Text(
//                       widget.isCheckOut
//                           ? 'Kirim Jam Pulang'
//                           : 'Kirim Jam Masuk',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
// }

// // ---------- Widget Kamera Modal dengan Konfirmasi ----------
// class CameraFaceDialog extends StatefulWidget {
//   final Function(XFile) onConfirm;
//   const CameraFaceDialog({required this.onConfirm, super.key});
//   @override
//   State<CameraFaceDialog> createState() => _CameraFaceDialogState();
// }

// class _CameraFaceDialogState extends State<CameraFaceDialog> {
//   CameraController? controller;
//   XFile? file;
//   bool takingPicture = false;

//   @override
//   void initState() {
//     super.initState();
//     _initCamera();
//   }

//   Future<void> _initCamera() async {
//     final cameras = await availableCameras();
//     final frontCam = cameras.firstWhere(
//       (c) => c.lensDirection == CameraLensDirection.front,
//       orElse: () => cameras.first,
//     );
//     controller = CameraController(frontCam, ResolutionPreset.medium, enableAudio: false);
//     await controller?.initialize();
//     if (mounted) setState(() {});
//   }

//   Future<void> _takePicture() async {
//     if (controller == null || !controller!.value.isInitialized) return;
//     setState(() => takingPicture = true);
//     try {
//       final XFile image = await controller!.takePicture();
//       setState(() => file = image);
//     } finally {
//       setState(() => takingPicture = false);
//     }
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       insetPadding: const EdgeInsets.all(16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(18),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (file == null)
//               (controller != null && controller!.value.isInitialized)
//                   ? ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: AspectRatio(
//                         aspectRatio: controller!.value.aspectRatio,
//                         child: CameraPreview(controller!),
//                       ),
//                     )
//                   : Container(
//                       height: 220,
//                       alignment: Alignment.center,
//                       child: const Text('Memuat kamera...')),
//             if (file != null)
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.file(File(file!.path), height: 220, fit: BoxFit.cover),
//               ),
//             const SizedBox(height: 18),
//             Text(
//               file == null ? 'Cek Wajah...' : 'Sudah cocok?',
//               style: const TextStyle(
//                   color: primaryPurple, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 18),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Colors.red,
//                       side: const BorderSide(color: Colors.red),
//                     ),
//                     child: const Text('Batal'),
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: file == null ? Colors.blue : primaryPurple,
//                     ),
//                     onPressed: file == null
//                         ? (takingPicture ? null : _takePicture)
//                         : () {
//                             widget.onConfirm(file!);
//                             Navigator.pop(context);
//                           },
//                     child: file == null
//                         ? (takingPicture
//                             ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
//                             : const Icon(Icons.camera_alt, size: 26))
//                         : const Text('Konfirmasi'),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:io';
// import 'package:intl/intl.dart';

// const primaryPurple = Color(0xFF242484);
// const greyBg = Color(0xFFEFEFF2);

// class ClockInPage extends StatefulWidget {
//   final String userId; // sebagai penanda user asal
//   final bool isCheckOut; // true jika jam pulang, false jika jam masuk

//   const ClockInPage({
//     required this.userId,
//     required this.isCheckOut,
//     super.key,
//   });
//   @override
//   State<ClockInPage> createState() => _ClockInPageState();
// }

// class _ClockInPageState extends State<ClockInPage> {
//   String? namaLokasi; // Nama alamat dari reverse geocoding
//   double? latitude;
//   double? longitude;
//   XFile? fotoWajah;
//   final TextEditingController _catatanCtrl = TextEditingController();
//   bool _loading = false;
//   bool _loadingLokasi = true;

//   DateTime now = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _ambilLokasi();
//   }

//   // Ambil koordinat & nama lokasi (reverse geocoding)
//   Future<void> _ambilLokasi() async {
//     try {
//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       // Reverse geocoding untuk mendapatkan nama alamat
//       final List<Placemark> placemarks = await placemarkFromCoordinates(
//         pos.latitude,
//         pos.longitude,
//       );

//       String alamatLengkap = 'Lokasi tidak ditemukan';
//       if (placemarks.isNotEmpty) {
//         final place = placemarks.first;
//         // Susun alamat lengkap: jalan, area, kota, negara
//         final alamatParts = <String>[];
//         if (place.street != null && place.street!.isNotEmpty)
//           alamatParts.add(place.street!);
//         if (place.subLocality != null && place.subLocality!.isNotEmpty)
//           alamatParts.add(place.subLocality!);
//         if (place.locality != null && place.locality!.isNotEmpty)
//           alamatParts.add(place.locality!);
//         if (place.administrativeArea != null &&
//             place.administrativeArea!.isNotEmpty)
//           alamatParts.add(place.administrativeArea!);
//         if (place.country != null && place.country!.isNotEmpty)
//           alamatParts.add(place.country!);

//         alamatLengkap = alamatParts.join(', ');
//       }

//       setState(() {
//         latitude = pos.latitude;
//         longitude = pos.longitude;
//         namaLokasi = alamatLengkap;
//         _loadingLokasi = false;
//       });
//     } catch (e) {
//       setState(() {
//         namaLokasi = 'Lokasi gagal diambil: $e';
//         _loadingLokasi = false;
//       });
//     }
//   }

//   // Ambil foto wajah (kamera depan)
//   Future<void> _ambilFoto() async {
//     final ImagePicker picker = ImagePicker();
//     final result = await picker.pickImage(
//       source: ImageSource.camera,
//       preferredCameraDevice: CameraDevice.front,
//     );
//     if (result != null) {
//       setState(() => fotoWajah = result);
//     }
//   }

//   // Upload foto ke Storage, simpan info ke Firestore (termasuk nama alamat dari maps)
//   Future<void> _kirimAbsensi() async {
//     // Validasi data wajib
//     if (fotoWajah == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('❌ Foto wajah harus diambil terlebih dahulu'),
//         ),
//       );
//       return;
//     }

//     if (latitude == null || longitude == null || namaLokasi == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('❌ Lokasi belum berhasil diambil')),
//       );
//       return;
//     }

//     setState(() => _loading = true);

//     try {
//       String? urlFoto;

//       // Upload foto ke Firebase Storage
//       if (fotoWajah != null) {
//         final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
//         final ref = FirebaseStorage.instance.ref(
//           'absensi_photo/${widget.userId}_${timestamp}.jpg',
//         );
//         await ref.putFile(File(fotoWajah!.path));
//         urlFoto = await ref.getDownloadURL();
//       }

//       // Siapkan data yang akan dikirim ke Firestore
//       final hariKey = DateFormat('yyyy-MM-dd').format(now);
//       final waktuFormatted = DateFormat('HH:mm:ss').format(now);

//       // Data readable dan lengkap
//       final absenData = {
//         'waktu': waktuFormatted,
//         'jam_masuk_pulang': widget.isCheckOut ? 'Jam Pulang' : 'Jam Masuk',
//         'koordinat': {'latitude': latitude, 'longitude': longitude},
//         'nama_lokasi': namaLokasi,
//         'catatan': _catatanCtrl.text.trim(),
//         'fotoUrl': urlFoto ?? '',
//         'timestamp': FieldValue.serverTimestamp(),
//       };

//       // Simpan ke Firestore
//       final checkInKey = widget.isCheckOut ? 'checkOut' : 'checkIn';
//       await FirebaseFirestore.instance
//           .collection('absensi')
//           .doc(widget.userId)
//           .collection('hari')
//           .doc(hariKey)
//           .set({checkInKey: absenData}, SetOptions(merge: true));

//       setState(() => _loading = false);

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             '✅ ${widget.isCheckOut ? "Jam pulang" : "Jam masuk"} berhasil dicatat!',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       setState(() => _loading = false);
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final tStyleTitle = TextStyle(
//       color: primaryPurple,
//       fontWeight: FontWeight.bold,
//       fontSize: 21,
//     );
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: primaryPurple),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           widget.isCheckOut ? 'Jam Pulang' : 'Jam Masuk',
//           style: tStyleTitle,
//         ),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.symmetric(horizontal: 24),
//         children: [
//           const SizedBox(height: 10),
//           Container(
//             decoration: BoxDecoration(
//               color: greyBg,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             padding: const EdgeInsets.all(10),
//             child: Column(
//               children: [
//                 Text(
//                   'DayOn',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: primaryPurple,
//                     fontSize: 18,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Icon(Icons.folder_open, color: primaryPurple),
//                     SizedBox(width: 8),
//                     Text(
//                       DateFormat('dd MMM yyyy (HH:mm)', 'id_ID').format(now),
//                       style: TextStyle(color: Colors.black54, fontSize: 16),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Foto Wajah Section
//           Text(
//             'Foto Wajah',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: primaryPurple,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 8),
//           GestureDetector(
//             onTap: _ambilFoto,
//             child: Container(
//               width: double.infinity,
//               height: 200,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 color: greyBg,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: primaryPurple, width: 1.2),
//               ),
//               child: fotoWajah == null
//                   ? Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.camera_alt, color: primaryPurple, size: 50),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Tap untuk ambil foto',
//                           style: TextStyle(color: primaryPurple),
//                         ),
//                       ],
//                     )
//                   : Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         Image.file(
//                           File(fotoWajah!.path),
//                           width: double.infinity,
//                           height: 200,
//                           fit: BoxFit.cover,
//                         ),
//                         Positioned(
//                           top: 8,
//                           right: 8,
//                           child: GestureDetector(
//                             onTap: () => setState(() => fotoWajah = null),
//                             child: Container(
//                               padding: const EdgeInsets.all(4),
//                               decoration: BoxDecoration(
//                                 color: Colors.red,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Icon(
//                                 Icons.close,
//                                 color: Colors.white,
//                                 size: 18,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Lokasi Section
//           Text(
//             'Lokasi',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: primaryPurple,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(
//               color: greyBg,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: primaryPurple.withValues(alpha: 0.3),
//                 width: 1,
//               ),
//             ),
//             child: _loadingLokasi
//                 ? Row(
//                     children: [
//                       SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation(primaryPurple),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Mengambil lokasi...',
//                         style: TextStyle(color: Colors.black54),
//                       ),
//                     ],
//                   )
//                 : Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.location_on,
//                             color: primaryPurple,
//                             size: 20,
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               namaLokasi ?? 'Lokasi tidak ditemukan',
//                               style: TextStyle(
//                                 color: Colors.black87,
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 13,
//                               ),
//                               maxLines: 3,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (latitude != null && longitude != null) ...[
//                         const SizedBox(height: 10),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 8,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.map,
//                                 color: Colors.grey[600],
//                                 size: 16,
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Koordinat',
//                                       style: TextStyle(
//                                         color: Colors.black54,
//                                         fontSize: 11,
//                                       ),
//                                     ),
//                                     Text(
//                                       '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
//                                       style: TextStyle(
//                                         color: Colors.black87,
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//           ),
//           const SizedBox(height: 24),

//           // Catatan Section
//           Text(
//             'Catatan (Opsional)',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: primaryPurple,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 8),
//           TextField(
//             controller: _catatanCtrl,
//             decoration: InputDecoration(
//               hintText: 'Tulis catatan tambahan...',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: Colors.grey[300]!),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: Colors.grey[300]!),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: primaryPurple, width: 2),
//               ),
//               contentPadding: const EdgeInsets.all(14),
//             ),
//             maxLines: 3,
//           ),
//           const SizedBox(height: 24),

//           // Tombol Kirim
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryPurple,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 padding: const EdgeInsets.symmetric(vertical: 18),
//                 disabledBackgroundColor: Colors.grey[400],
//               ),
//               onPressed: _loading ? null : _kirimAbsensi,
//               child: _loading
//                   ? SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2,
//                       ),
//                     )
//                   : Text(
//                       widget.isCheckOut
//                           ? 'Kirim Jam Pulang'
//                           : 'Kirim Jam Masuk',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
// }
