import 'dart:async';
import 'package:flutter/material.dart';

// ==== PromoCard dengan Background Image Asset ====
class PromoCard extends StatelessWidget {
  final String imageAsset;
  const PromoCard({super.key, required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Container(
        height: 110, // tinggi card
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: DecorationImage(
            image: AssetImage(imageAsset),
            fit: BoxFit.cover,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
      ),
    );
    // Jika ingin overlay gelap untuk konten: aktifkan Container berikut!
    /* 
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.black.withOpacity(0.08),
          ),
        */
    // child: Row(
    //   children: [
    //     const SizedBox(width: 14),
    //     // Jika ingin bisa isi widget/icon di atas gambar, tambah di sini
    //     Expanded(
    //       child: Padding(
    //         padding: const EdgeInsets.fromLTRB(0, 16, 14, 16),
    //         child: Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Container(
    //               height: 10,
    //               width: double.infinity,
    //               decoration: BoxDecoration(
    //                 color: AppColors.navy.withOpacity(0.8),
    //                 borderRadius: BorderRadius.circular(99),
    //               ),
    //             ),
    // const SizedBox(height: 10),
    // Container(
    //   height: 8,
    //   width: 180,
    //   decoration: BoxDecoration(
    //     color: const Color(0xFFD8DDEA).withOpacity(0.8),
    //     borderRadius: BorderRadius.circular(99),
    //   ),
    // ),
    //     const SizedBox(height: 10),
    //     Row(
    //       children: List.generate(
    //         5,
    //         (i) => const Padding(
    //           padding: EdgeInsets.only(right: 4),
    //           child: Icon(
    //             Icons.star_border,
    //             size: 14,
    //             color: AppColors.navy,
    //           ),
    //         ),
    //       ),
    //     ),
    //   // ],
    // ),
    // ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
}

// ==== Carousel PageView Scroll Otomatis ====
class PromoCardCarousel extends StatefulWidget {
  const PromoCardCarousel({super.key});
  @override
  State<PromoCardCarousel> createState() => _PromoCardCarouselState();
}

class _PromoCardCarouselState extends State<PromoCardCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> imageAssets = [
    'assets/images/safety.jpg',
    'assets/images/work.jpg',
    'assets/images/fokus.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_controller.hasClients) {
        _currentPage++;
        if (_currentPage >= imageAssets.length) _currentPage = 0;
        _controller.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: PageView.builder(
        controller: _controller,
        itemCount: imageAssets.length,
        itemBuilder: (context, index) {
          return PromoCard(imageAsset: imageAssets[index]);
        },
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import '../theme/app_theme.dart';

// class PromoCard extends StatelessWidget {
//   const PromoCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       child: Container(
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x14000000),
//               blurRadius: 18,
//               offset: Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             const SizedBox(width: 14),
//             Container(
//               width: 66,
//               height: 66,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFE9ECF3),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: const Icon(Icons.image_outlined, color: AppColors.navy),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(0, 16, 14, 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       height: 10,
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         color: AppColors.navy,
//                         borderRadius: BorderRadius.circular(99),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Container(
//                       height: 8,
//                       width: 180,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFD8DDEA),
//                         borderRadius: BorderRadius.circular(99),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: List.generate(
//                         5,
//                         (i) => const Padding(
//                           padding: EdgeInsets.only(right: 4),
//                           child: Icon(
//                             Icons.star_border,
//                             size: 14,
//                             color: AppColors.navy,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }