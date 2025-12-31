import 'package:flutter/material.dart';
import 'package:peresenceapp/screens/home/absen_page.dart';
import 'package:peresenceapp/screens/home/daftarabsen_page.dart';
import 'package:peresenceapp/screens/home/lembur_page.dart';
import 'package:peresenceapp/screens/home/reimbursement_page.dart';
import 'package:peresenceapp/screens/home/selipgaji_page.dart';
import 'package:peresenceapp/screens/kalender_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/promo_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/surface.dart';
import '../../widgets/svg_icon_tile.dart';

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

  // Nama user bisa diganti/dinamis sesuai login/setting
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
                      activeDotColor: AppColors.navy,
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
                    SvgIconTile(
                      asset: 'assets/images/Kalender.jpg',
                      label: 'KALENDER',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CalendarPage(),
                          ),
                        );
                      },
                    ),
                    SvgIconTile(
                      asset: 'assets/images/selipgaji.jpg',
                      label: 'SLIP GAJI',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SlipGajiPage(),
                          ),
                        );
                      },
                    ),
                    SvgIconTile(
                      asset: 'assets/images/daftarabsen.jpg',
                      label: 'DAFTAR ABSEN',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DaftarAbsenPage(absensi: []),
                          ),
                        );
                      },
                    ),
                    SvgIconTile(
                      asset: 'assets/images/JamLembur.jpg',
                      label: 'LEMBUR',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LemburPage()),
                        );
                      },
                    ),
                    SvgIconTile(
                      asset: 'assets/images/Reimbursment.jpg',
                      label: 'REIMBURSEMENT',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReimbursementPage(),
                          ),
                        );
                      },
                    ),
                    SvgIconTile(
                      asset: 'assets/images/FaceKamera.jpg',
                      label: 'ABSEN',
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
                onActionTap: () {},
                child: const EmptyState(
                  title: 'Belum ada pengumuman',
                  subtitle: 'Pengumuman akan tampil disini',
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
                onActionTap: () {},
                child: const EmptyState(
                  title: 'Tidak ada tugas',
                  subtitle: 'Anda tidak memiliki tugas yang tertunda',
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
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 144, 155, 255), // biru muda sesuai gambar
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // Top bar icons
          // Positioned(
          //   top: 18,
          //   left: 18,
          //   child: Icon(Icons.menu, color: Color(0xFF0052A5), size: 28),
          // ),
          Positioned(
            top: 18,
            right: 60,
            child: Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF0052A5),
              size: 26,
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Icon(
              Icons.settings_outlined,
              color: Color(0xFF0052A5),
              size: 26,
            ),
          ),
          // Greeting and profile
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
                          color: Color(0xFFB1B6C6),
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
                          color: Color(0xFF0052A5),
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
                    style: const TextStyle(
                      color: Color(0xFF0052A5),
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
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.search,
                          color: Color(0xFFB1B6C6),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Color(0xFFB1B6C6),
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 15),
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
                    color: Color(0xFF0052A5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
