import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:intl/intl.dart';

const primaryPurple = Color(0xFF242484);
const greyBg = Color(0xFFEFEFF2);

class ClockInPage extends StatefulWidget {
  final String userId; // sebagai penanda user asal
  final bool isCheckOut; // true jika jam pulang, false jika jam masuk

  const ClockInPage({required this.userId, required this.isCheckOut, super.key});
  @override
  State<ClockInPage> createState() => _ClockInPageState();
}

class _ClockInPageState extends State<ClockInPage> {
  String? lokasi;
  XFile? fotoWajah;
  final TextEditingController _catatanCtrl = TextEditingController();
  bool _loading = false;

  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(()=> lokasi = '${pos.latitude}, ${pos.longitude}');
    } catch (e) {
      setState(()=> lokasi = 'Lokasi gagal diambil');
    }
  }

  Future<void> _ambilFoto() async {
    final ImagePicker picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if(result != null){
      setState(()=> fotoWajah = result);
    }
  }

  // Tombol kirim: upload foto ke Storage, simpan info ke Firestore
  Future<void> _kirimAbsensi() async {
    setState(()=> _loading = true);
    String? urlFoto;
    if (fotoWajah != null) {
      final ref = FirebaseStorage.instance.ref(
        'absensi_photo/${widget.userId}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.jpg'
      );
      await ref.putFile(File(fotoWajah!.path));
      urlFoto = await ref.getDownloadURL();
    }

    // Simpan ke Firestore
    final hariKey = DateFormat('yyyy-MM-dd').format(now);
    final absenData = {
      'waktu': DateFormat('HH:mm:ss').format(now),
      'lokasi': lokasi,
      'fotoUrl': urlFoto ?? '',
      'catatan': _catatanCtrl.text,
    };

    await FirebaseFirestore.instance
      .collection('absensi').doc(widget.userId).collection('hari').doc(hariKey)
      .set(
        widget.isCheckOut ? {'checkOut': absenData} : {'checkIn': absenData},
        SetOptions(merge: true)
      );

    setState(()=> _loading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Absensi berhasil!'))
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tStyleTitle = TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize:21);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryPurple),
          onPressed: ()=>Navigator.pop(context),
        ),
        title: Text('Clock In', style: tStyleTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal:24),
        children: [
          const SizedBox(height:10),
          Container(
            decoration: BoxDecoration(color: greyBg, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text('DayOn', style: TextStyle(fontWeight: FontWeight.bold, color: primaryPurple, fontSize:18)),
                Row(
                  children: [
                    Icon(Icons.folder_open, color: primaryPurple),
                    SizedBox(width:8),
                    Text(
                      DateFormat('dd MMM yyyy (HH:mm)', 'id_ID').format(now),
                      style: TextStyle(color: Colors.black54, fontSize:16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height:14),
          // Foto Wajah Section
          GestureDetector(
            onTap: _ambilFoto,
            child: Container(
              width: 200, height:200,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(vertical:16),
              decoration: BoxDecoration(
                color:greyBg, borderRadius:BorderRadius.circular(16),
                border: Border.all(color: primaryPurple, width:1.2)
              ),
              child: fotoWajah == null
                ? Icon(Icons.person_outline, color: primaryPurple, size:90)
                : Image.file(File(fotoWajah!.path), width:170, height:170, fit:BoxFit.cover),
            ),
          ),
          const SizedBox(height:16),
          Divider(),
          ListTile(
            leading: Icon(Icons.notes, color: Colors.black),
            title: Text('catatan', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w600)),
            subtitle: TextFormField(
              controller: _catatanCtrl,
              decoration: InputDecoration(hintText:'Tulis catatan'),
              maxLines:2,
            ),
            trailing: Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: Icon(Icons.pin_drop, color: primaryPurple),
            title: Text('Lihat lokasi', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w600)),
            subtitle: Text(lokasi ?? 'Mengambil lokasi...', style: TextStyle(color: Colors.black)),
            trailing: Icon(Icons.chevron_right),
          ),

          const SizedBox(height:16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical:18)
              ),
              onPressed: _loading ? null : _kirimAbsensi,
              child: _loading
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Kirim', style: TextStyle(fontSize:18, color:Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}