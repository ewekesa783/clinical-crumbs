import 'package:flutter/material.dart';

class ClinicalCrumbsStartupScreen extends StatelessWidget {
  const ClinicalCrumbsStartupScreen({
    super.key,
    this.errorMessage,
  });

  final String? errorMessage;

  static const Color _navy = Color(0xFF243B6B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/branding/clinical_crumbs_logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Clinical Crumbs',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Smart. Small. Essential.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFDCE5F7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.1,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 28),
                  Text(
                    'Startup failed: $errorMessage',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFD7D7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
