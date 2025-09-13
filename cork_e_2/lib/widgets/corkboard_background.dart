import 'package:flutter/material.dart';

class CorkboardBackground extends StatelessWidget {
  final Widget child;

  const CorkboardBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD4A373),
        image: DecorationImage(
          image: const AssetImage('assets/images/cork_texture.jpg'),
          repeat: ImageRepeat.repeat,
          opacity: 0.8,
          fit: BoxFit.none,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.brown.withOpacity(0.05),
              Colors.orange.withOpacity(0.05),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}