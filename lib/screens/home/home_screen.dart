import 'package:flutter/material.dart';
import 'package:peresenceapp/screens/home/absen_page.dart';
import 'package:peresenceapp/screens/home/daftarabsen_page.dart';
import 'package:peresenceapp/screens/home/lembur_page.dart';
import 'package:peresenceapp/screens/home/pengajuan_page.dart';
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

  final String username = 'Ramadhani Hibban';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ---- HEADER GREETING BAR ----
          SliverToBoxAdapter(
            child: GreetingHeader(
              username: username,
              assetImage: 'assets/images/header.jpg',
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 18)),

          // ---- CAROUSEL ----
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: PageView(
                      controller: _pageController,
                      children: const [
                        PromoCard(imageAsset: 'assets/images/safety.jpg'),
                        PromoCard(imageAsset: 'assets/images/work.jpg'),
                        PromoCard(imageAsset: 'assets/images/fokus.jpg'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
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
                      label: 'REIMBURSEMENT',
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
                            builder: (_) => const PengajuanPage(),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AbsenPage()),
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

// HEADER GREETINGS
class GreetingHeader extends StatelessWidget {
  final String username;
  final String assetImage;
  final double height;

  const GreetingHeader({
    super.key,
    required this.username,
    required this.assetImage,
    this.height = 170,
  });

  String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  String getGreeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'Selamat pagi';
    if (hour >= 12 && hour < 16) return 'Selamat siang';
    if (hour >= 16 && hour < 19) return 'Selamat sore';
    if (hour >= 19 && hour <= 23) return 'Selamat malam';
    return 'Selamat dini hari';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: 60,
            child: Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Icon(Icons.settings_outlined, color: Colors.white, size: 26),
          ),
          Positioned(
            left: 18,
            top: 54,
            right: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hello',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 21,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    getInitials(username),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search bar
          Positioned(
            left: 18,
            right: 18,
            top: 108,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.tune, color: AppColors.primary, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
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
