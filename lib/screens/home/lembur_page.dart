import 'package:flutter/material.dart';

const primaryBlue = Color(0xFF1F2A7A);
const softGrey = Color(0xFFF1F1F1);

class LemburPage extends StatelessWidget {
  const LemburPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryBlue.withOpacity(0.1),
                    child: Icon(Icons.arrow_back, color: primaryBlue),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Pengajuan Lembur",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // ===== FORM =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("Jadwal lembur"),
                    inputField("Tanggal lembur *", icon: Icons.calendar_today),
                    inputField("Shift *", icon: Icons.keyboard_arrow_down),

                    sectionTitle("Lembur sebelum shift"),
                    greyCard([
                      inputField("Durasi lembur"),
                      inputField("Durasi istirahat lembur", helper: "opsional"),
                    ]),

                    sectionTitle("Lembur setelah shift"),
                    greyCard([
                      inputField("Durasi lembur"),
                      inputField("Durasi istirahat lembur", helper: "opsional"),
                    ]),

                    sectionTitle("Informasi tambahan"),
                    greyCard([
                      inputField("Kompensasi *"),
                      inputField("Alasan"),
                      const SizedBox(height: 10),
                      const Text(
                        "Lampiran",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          uploadBox(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Anda dapat mengunggah maksimal 5 file\n"
                              "PDF, JPG, PNG, XLSX, DOCX (maks 10MB)",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // ===== BUTTON =====
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {},
                        child: const Text(
                          "Kirim",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== WIDGET KECIL =====
  static Widget sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryBlue,
      ),
    ),
  );

  static Widget inputField(String label, {IconData? icon, String? helper}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            suffixIcon: icon != null ? Icon(icon) : null,
            border: const UnderlineInputBorder(),
          ),
        ),
      );

  static Widget greyCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: softGrey,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(children: children),
  );

  static Widget uploadBox() => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: primaryBlue,
        width: 1.5,
        style: BorderStyle.solid,
      ),
    ),
    child: const Icon(Icons.add, color: primaryBlue, size: 32),
  );
}
