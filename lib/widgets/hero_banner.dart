import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme.dart';

class HeroBannerData {
  final int id;
  final String title;
  final String subtitle;
  final List<Color> bg;
  final String tag;

  const HeroBannerData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.tag,
  });
}

const List<HeroBannerData> heroBanners = [
  HeroBannerData(
    id: 1,
    title: 'Nouvelle Collection',
    subtitle: 'Printemps 2026',
    bg: [Color(0xFF111111), Color(0xFF2D2D2D)],
    tag: 'NEW',
  ),
  HeroBannerData(
    id: 2,
    title: 'Montres & Bijoux',
    subtitle: 'Élégance intemporelle',
    bg: [Color(0xFFC9A96E), Color(0xFF8B6914)],
    tag: 'TRENDING',
  ),
  HeroBannerData(
    id: 3,
    title: 'Sneakers Exclusifs',
    subtitle: 'Édition limitée',
    bg: [Color(0xFF1a1a2e), Color(0xFF16213e)],
    tag: 'LIMITED',
  ),
];

class HeroBanner extends StatefulWidget {
  final VoidCallback onDiscoverTap;

  const HeroBanner({super.key, required this.onDiscoverTap});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final PageController _controller = PageController();
  int _activePage = 0;

  @override
  void dispose() {
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
            itemCount: heroBanners.length,
            onPageChanged: (i) => setState(() => _activePage = i),
            itemBuilder: (context, index) {
              final b = heroBanners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: b.bg,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Stack(
                  children: [
                    // Tag
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          b.tag,
                          style: GoogleFonts.inter(
                            fontSize: AppFontSize.xs,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textInverse,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b.subtitle,
                            style: GoogleFonts.inter(
                              fontSize: AppFontSize.sm,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: widget.onDiscoverTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Découvrir',
                                    style: GoogleFonts.inter(
                                      fontSize: AppFontSize.xs,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    FeatherIcons.arrowRight,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(heroBanners.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _activePage ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _activePage
                    ? AppColors.accent
                    : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
