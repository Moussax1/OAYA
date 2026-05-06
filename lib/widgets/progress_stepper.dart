import 'package:flutter/material.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme.dart';

class ProgressStepper extends StatelessWidget {
  final int currentStep; // 1, 2, or 3
  const ProgressStepper({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _step(1), _line(), _step(2), _line(), _step(3),
        ],
      ),
    );
  }

  Widget _step(int step) {
    final isActive = step == currentStep;
    final isCompleted = step < currentStep;
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : AppColors.border,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(FeatherIcons.check, size: 12, color: AppColors.textMuted)
            : Text('$step', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primary : AppColors.textMuted)),
      ),
    );
  }

  Widget _line() {
    return Container(width: 40, height: 2, margin: const EdgeInsets.symmetric(horizontal: 8), color: AppColors.border);
  }
}
