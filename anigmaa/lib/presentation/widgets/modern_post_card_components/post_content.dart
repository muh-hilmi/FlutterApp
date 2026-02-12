import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostContent extends StatelessWidget {
  final String content;

  const PostContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        height: 1.5,
        color: const Color(0xFF1a1a1a),
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
      ),
    );
  }
}
