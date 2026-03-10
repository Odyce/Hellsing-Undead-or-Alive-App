import 'package:flutter/material.dart';

class BookPageTemplate extends StatelessWidget {
  final String title;
  final String content;

  const BookPageTemplate({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF3E6C8),
          image: DecorationImage(
            image: AssetImage("assets/images/parchment.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: "Cinzel",
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    fontFamily: "EBGaramond",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
