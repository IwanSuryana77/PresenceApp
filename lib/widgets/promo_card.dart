import 'dart:async';
import 'package:flutter/material.dart';

// Dot indicator widget
class DotIndicator extends StatelessWidget {
  final int currentIndex;
  final int count;
  const DotIndicator({
    required this.currentIndex,
    required this.count,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: currentIndex == index ? 10 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: currentIndex == index ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class PromoCardCarousel extends StatefulWidget {
  const PromoCardCarousel({super.key});
  @override
  State<PromoCardCarousel> createState() => _PromoCardCarouselState();
}

class _PromoCardCarouselState extends State<PromoCardCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_PromoModel> _data = [
    _PromoModel(
      imageAsset: 'assets/images/policy.jpg', // Ganti dengan gambar yang sesuai
      title: 'Pembaruan Kebijakan',
      desc: 'Kebijakan baru efektif 1 September.',
    ),
    _PromoModel(
      imageAsset: 'assets/images/work.jpg',
      title: 'Produktivitas',
      desc: 'Bekerja dengan fokus penuh.',
    ),
    _PromoModel(
      imageAsset: 'assets/images/fokus.jpg',
      title: 'Fokus',
      desc: 'Jaga fokus untuk hasil maksimal.',
    ),
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_controller.hasClients) {
        _currentPage = (_currentPage + 1) % _data.length;
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
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (idx) {
              setState(() => _currentPage = idx);
            },
            itemCount: _data.length,
            itemBuilder: (context, index) {
              return PromoCard(
                imageAsset: _data[index].imageAsset,
                title: _data[index].title,
                desc: _data[index].desc,
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        DotIndicator(currentIndex: _currentPage, count: _data.length),
      ],
    );
  }
}

class PromoCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String desc;
  const PromoCard({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    // Sesuaikan ukuran card dan padding sesuai gambar contoh
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 140, maxHeight: 170),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFE5EAF1), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoModel {
  final String imageAsset;
  final String title;
  final String desc;
  _PromoModel({
    required this.imageAsset,
    required this.title,
    required this.desc,
  });
}
