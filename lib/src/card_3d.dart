import 'package:flutter/material.dart';

class Card3D extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Card3D({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF132236),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
