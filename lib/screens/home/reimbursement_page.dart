import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReimbursementData {
  DateTime tanggal;
  double nominal;
  String keterangan;

  ReimbursementData({
    required this.tanggal,
    required this.nominal,
    required this.keterangan,
  });
}

class ReimbursementPage extends StatefulWidget {
  const ReimbursementPage({super.key});

  @override
  State<ReimbursementPage> createState() => _ReimbursementPageState();
}

class _ReimbursementPageState extends State<ReimbursementPage> {
  final navy = const Color(0xFF1B1E6D);
  final _formKey = GlobalKey<FormState>();

  DateTime _tanggal = DateTime.now();
  double? _nominal;
  String? _keterangan;

  final List<ReimbursementData> _list = [];

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2024, 1),
      lastDate: DateTime(2100, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: navy, onSurface: navy),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _tanggal = picked);
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() != true) return;
    _formKey.currentState?.save();

    setState(() {
      _list.insert(
        0,
        ReimbursementData(
          tanggal: _tanggal,
          nominal: _nominal ?? 0,
          keterangan: _keterangan ?? "",
        ),
      );
      // Reset form (tanggal tetap hari ini)
      _nominal = null;
      _keterangan = null;
    });

    // TODO: Simpan ke database (hubungkan ke SQLite, Firestore, API, dll. sesuai kebutuhan)
    // saveToDatabase(_list.first);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengajuan reimbursement berhasil ditambah!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: navy),
        title: const Text(
          'Reimburs',
          style: TextStyle(
            color: Color(0xFF1B1E6D),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Tanggal
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _pickTanggal,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Tanggal Pengajuan",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          DateFormat('d MMMM yyyy').format(_tanggal),
                          style: TextStyle(
                            color: navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nominal
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Nominal (Rp)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.bold,
                      ),
                      onSaved: (val) => _nominal = double.tryParse(
                        val?.replaceAll('.', '').replaceAll(',', '') ?? '',
                      ),
                      validator: (val) =>
                          (val == null ||
                              val.isEmpty ||
                              double.tryParse(
                                    val.replaceAll('.', '').replaceAll(',', ''),
                                  ) ==
                                  null)
                          ? "Nominal wajib diisi"
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Keterangan
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Keterangan Reimbursement",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 1,
                      onSaved: (val) => _keterangan = val,
                      validator: (val) => (val == null || val.isEmpty)
                          ? "Keterangan wajib diisi"
                          : null,
                    ),
                    const SizedBox(height: 17),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.save_rounded),
                        label: const Text("Simpan Reimbursement"),
                        onPressed: _submitForm,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              // Daftar reimbursement
              Expanded(
                child: _list.isEmpty
                    ? const Center(
                        child: Text(
                          "Belum ada data reimbursement.",
                          style: TextStyle(
                            color: Color(0xFF1B1E6D),
                            fontWeight: FontWeight.w500,
                            fontSize: 14.5,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _list.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 16, color: Color(0xFFE5E7F1)),
                        itemBuilder: (context, i) {
                          final d = _list[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.attach_money,
                              color: Color(0xFF1B1E6D),
                            ),
                            title: Text(
                              "Rp ${NumberFormat('#,###', 'id').format(d.nominal)}",
                              style: const TextStyle(
                                color: Color(0xFF1B1E6D),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              d.keterangan,
                              style: TextStyle(
                                color: navy.withValues(alpha: 0.75),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Text(
                              DateFormat('d MMM yyyy').format(d.tanggal),
                              style: TextStyle(
                                color: navy.withValues(alpha: 0.6),
                                fontSize: 12.5,
                              ),
                            ),
                            // TODO: Tambah aksi edit/hapus untuk CRUD jika mau
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
