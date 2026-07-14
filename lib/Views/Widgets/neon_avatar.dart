import 'package:flutter/material.dart';

class NeonAvatar extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final double size;
  final bool isOnline;
  final bool isGroup;

  const NeonAvatar({
    Key? key,
    this.imageUrl,
    required this.displayName,
    this.size = 48,
    this.isOnline = false,
    this.isGroup = false,
  }) : super(key: key);

  Widget _buildSingleCircle({
    required String initial,
    required double circleSize,
    required int patternIndex,
    bool hasBorder = false,
  }) {
    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        color: const Color(0xFF111111), // Solid Charcoal Background
        shape: BoxShape.circle,
        border: hasBorder
            ? Border.all(
                color: const Color(0xFFFFFFFF), // White mask border
                width: circleSize * 0.08,
              )
            : Border.all(
                color: const Color(0xFF111111),
                width: 1,
              ),
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner decorative geometric layout for a high-end vector feel
            Positioned.fill(
              child: CustomPaint(
                painter: _AvatarGeometryPainter(patternIndex),
              ),
            ),
            // Sharp, high-contrast monogram text
            Text(
              initial,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: circleSize * 0.38,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFFFFF), // Pure White
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String cleanName = displayName.trim();
    if (cleanName.startsWith('+')) {
      cleanName = cleanName.substring(1).trim();
    }

    // Generate a consistent shape pattern based on displayName string value
    final int charCodeSum = displayName.runes.fold(0, (prev, element) => prev + element);
    final int patternIndex = charCodeSum % 3;

    if (isGroup) {
      // Differentiate Group: two overlapping avatars!
      List<String> initials = [];
      if (cleanName.isNotEmpty) {
        final parts = cleanName.split(RegExp(r'\s+'));
        if (parts.length > 1) {
          initials.add(parts[0].substring(0, 1).toUpperCase());
          initials.add(parts[1].substring(0, 1).toUpperCase());
        } else if (cleanName.length > 1) {
          initials.add(cleanName.substring(0, 1).toUpperCase());
          initials.add(cleanName.substring(1, 2).toUpperCase());
        } else {
          initials.add(cleanName.substring(0, 1).toUpperCase());
          initials.add('G');
        }
      } else {
        initials = ['G', 'P'];
      }

      final double circleSize = size * 0.68;
      final int patternIndex1 = patternIndex;
      final int patternIndex2 = (patternIndex + 1) % 3;

      return Container(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Top-Right circle (in the back)
            Positioned(
              top: 0,
              right: 0,
              child: _buildSingleCircle(
                initial: initials[0],
                circleSize: circleSize,
                patternIndex: patternIndex1,
                hasBorder: false,
              ),
            ),
            // Bottom-Left circle (in the front, overlapping with white border mask)
            Positioned(
              bottom: 0,
              left: 0,
              child: _buildSingleCircle(
                initial: initials[1],
                circleSize: circleSize,
                patternIndex: patternIndex2,
                hasBorder: true,
              ),
            ),
          ],
        ),
      );
    }

    final String initial = cleanName.isNotEmpty
        ? cleanName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF111111), // Solid Charcoal Background
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF111111),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner decorative geometric layout for a high-end vector feel
          Positioned.fill(
            child: ClipOval(
              child: CustomPaint(
                painter: _AvatarGeometryPainter(patternIndex),
              ),
            ),
          ),
          // Sharp, high-contrast monogram text
          Text(
            initial,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFFFFFF), // Pure White
              letterSpacing: -0.5,
            ),
          ),
          // Neon Pulse active indicator dot (if online or as sub-accent)
          if (isOnline)
            Positioned(
              right: size * 0.05,
              bottom: size * 0.05,
              child: Container(
                width: size * 0.22,
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B54ED), // Neon Lime
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF111111),
                    width: size * 0.05,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarGeometryPainter extends CustomPainter {
  final int patternIndex;

  _AvatarGeometryPainter(this.patternIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2B54ED).withOpacity(0.15) // Neon Lime accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06;

    if (patternIndex == 0) {
      // Geometric concentric thin circle
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5),
        size.width * 0.42,
        paint,
      );
      
      // Small accent dot in Neon Lime
      final dotPaint = Paint()
        ..color = const Color(0xFF2B54ED)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.3),
        size.width * 0.05,
        dotPaint,
      );
    } else if (patternIndex == 1) {
      // Geometric cross lines / tech alignment
      canvas.drawRect(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.5),
          radius: size.width * 0.35,
        ),
        paint,
      );
    } else {
      // Tech-like arc segment
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.5),
          radius: size.width * 0.38,
        ),
        0.5,
        2.0,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
