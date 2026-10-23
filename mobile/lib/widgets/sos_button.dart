import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SosButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const SosButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 8,
          shadowColor: AppColors.primary.withValues(alpha: 0.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital_rounded, size: 52),
            SizedBox(height: 6),
            Text(
              'DISPATCH',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
