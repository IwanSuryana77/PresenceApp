import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peresenceapp/screens/home/absen_page.dart';
import 'package:peresenceapp/screens/home/daftarabsen_page.dart';
import 'package:peresenceapp/screens/home/lembur_page.dart';
import 'package:peresenceapp/screens/home/reimbursement_page.dart';
import 'package:peresenceapp/screens/home/selipgaji_page.dart';
import 'package:peresenceapp/screens/kalender_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/promo_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/surface.dart';
import '../../widgets/icon_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _pageController = PageController(viewportFraction: 0.92);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ---- HEADER GREETING BAR ----
          SliverToBoxAdapter(child: GreetingHeader()),

          SliverToBoxAdapter(
            child: SizedBox(height: 3),
          ), // Jarak antara header dan carousel
          // ---- CAROUSEL ----
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              vertical: 22,
              horizontal: 12,
            ), // lebar & tinggi carousel
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 3), // Jarak atas sebelum carousel
                  SizedBox(
                    height: 200,
                    child: PageView(
                      controller: _pageController,
                      children: const [
                        PromoCard(
                          imageAsset: 'assets/images/safety.jpg',
                          title: 'Keselamatan Kerja',
                          desc: 'Pikirkan aman, bekerja aman.',
                        ),
                        PromoCard(
                          imageAsset: 'assets/images/work.jpg',
                          title: 'Produktivitas',
                          desc: 'Bekerja dengan fokus penuh.',
                        ),
                        PromoCard(
                          imageAsset: 'assets/images/fokus.jpg',
                          title: 'Fokus',
                          desc: 'Jaga fokus untuk hasil maksimal.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ), // Jarak bawah antara carousel dan indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: WormEffect(
                      dotHeight: 7,
                      dotWidth: 7,
                      activeDotColor: AppColors.primary,
                      dotColor: const Color(0xFFCBD2E1),
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ), // Jarak bawah antara indicator dan menu grid
                ],
              ),
            ),
          ),
          // ---- MENU GRID ----
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            sliver: SliverToBoxAdapter(
              child: Surface(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    IconTile(
                      icon: Icons.calendar_today,
                      iconColor: AppColors.primary,
                      label: 'KALENDER',
                      textColor: Colors.black,
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CalendarPage(),
                          ),
                        );
                      },
                    ),
                    IconTile(
                      icon: Icons.receipt_long,
                      iconColor: AppColors.primary,
                      label: 'SLIP GAJI',
                      textColor: Colors.black,
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SlipGajiPage(),
                          ),
                        );
                      },
                    ),
                    IconTile(
                      icon: Icons.list_alt,
                      iconColor: AppColors.primary,
                      label: 'DAFTAR ABSEN',
                      textColor: Colors.black,
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DaftarAbsenPage(absensi: []),
                          ),
                        );
                      },
                    ),
                    IconTile(
                      icon: Icons.access_time,
                      iconColor: AppColors.primary,
                      label: 'LEMBUR',
                      textColor: Colors.black,
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LemburPage()),
                        );
                      },
                    ),
                    IconTile(
                      icon: Icons.attach_money,
                      iconColor: AppColors.primary,
                      label: 'REIMBURSE',
                      textColor: Colors.black,
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReimbursementListPage(),
                          ),
                        );
                      },
                    ),
                    IconTile(
                      icon: Icons.camera_alt,
                      iconColor: AppColors.primary,
                      label: 'ABSEN',
                      textColor: Colors.black,
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onTap: () {
                        final userId =
                            FirebaseAuth.instance.currentUser?.uid ?? 'guest';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AbsensiDashboardPage(userId: userId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---- PENGUMUMAN ----
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            sliver: SliverToBoxAdapter(
              child: SectionCard(
                title: 'Pengumuman',
                actionText: 'Lihat semua',
                onActionTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AllPengumumanPage(),
                    ),
                  );
                },
                titleStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                actionTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                child: const EmptyState(
                  title: 'Belum ada pengumuman',
                  subtitle: 'Pengumuman akan tampil disini',
                  titleStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  subtitleStyle: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ),

          // ---- TUGAS ----
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverToBoxAdapter(
              child: SectionCard(
                title: 'Tugas',
                actionText: 'Lihat semua',
                onActionTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AllTugasPage()),
                  );
                },
                titleStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                actionTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                child: const EmptyState(
                  title: 'Tidak ada tugas',
                  subtitle: 'Anda tidak memiliki tugas yang tertunda',
                  titleStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  subtitleStyle: TextStyle(color: Colors.black54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HEADER PROFILES, AUTO-DATA FROM FIREBASE AUTH ---
class GreetingHeader extends StatefulWidget {
  const GreetingHeader({super.key});

  @override
  State<GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends State<GreetingHeader> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    String displayName = user?.displayName ?? 'User';
    String email = user?.email ?? 'Username';
    String photoUrl = user?.photoURL ?? '';

    // Simpan ke SharedPreferences biar persistent (opsional)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', displayName);
    await prefs.setString('user_email', email);
    await prefs.setString('user_photo', photoUrl);

    return {'name': displayName, 'email': email, 'photoUrl': photoUrl};
  }

  String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        final userName = snapshot.hasData
            ? snapshot.data!['name'] as String
            : 'Jane Doe';
        final userRole = 'Marketing Manager'; // static role for demo
        final photoUrl = snapshot.hasData
            ? snapshot.data!['photoUrl'] as String
            : '';

        return Container(
          width: double.infinity,
          color: AppColors.extraLight,
          padding: const EdgeInsets.only(
            top: 18,
            left: 0,
            right: 0,
            bottom: 12,
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              // Avatar
              photoUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(photoUrl),
                    )
                  : CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Text(
                        getInitials(userName),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
              const SizedBox(width: 14),
              // Name & Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userRole,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification icon with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.black87,
                      size: 26,
                    ),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 10,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: const Center(
                        child: Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ],
          ),
        );
      },
    );
  }
}

// --- Tambahan: Halaman Semua Pengumuman dan Semua Tugas ---
class AllPengumumanPage extends StatelessWidget {
  const AllPengumumanPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.extraLight,
      appBar: AppBar(
        title: const Text(
          'Semua Pengumuman',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Daftar semua pengumuman',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
    );
  }
}

class AllTugasPage extends StatelessWidget {
  const AllTugasPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.extraLight,
      appBar: AppBar(
        title: const Text('Semua Tugas', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Daftar semua tugas',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
    );
  }
}
