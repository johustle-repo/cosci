import 'package:flutter/material.dart';

class AuthActionButton extends StatelessWidget {
  const AuthActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [
                    Color(0xFF174EA6),
                    Color(0xFF2563EB),
                    Color(0xFF0F9F91),
                  ],
                ),
          color: isLoading ? const Color(0xFF94A3B8) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: .28),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
