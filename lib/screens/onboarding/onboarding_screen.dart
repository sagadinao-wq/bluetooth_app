import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../widgets/common_widgets.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const SizedBox(
                width: 280,
                height: 320,
                child: _OriginalLogoGraphic(),
              ),
              const Spacer(),
              PrimaryButton(
                label: "Розпочати роботу",
                color: kCyanColor,
                onTap: () => context.go('/workout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OriginalLogoGraphic extends StatelessWidget {
  const _OriginalLogoGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(280, 320),
      painter: VectorLogoFullPainter(),
    );
  }
}

class VectorLogoFullPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cyan = Paint()..color = kCyanColor..style = PaintingStyle.fill;
    final orange = Paint()..color = kOrangeColor..style = PaintingStyle.fill;

    final leftV = Path()
      ..moveTo(90, 70)
      ..lineTo(162, 195)
      ..lineTo(135, 195)
      ..lineTo(70, 85)
      ..close();
    canvas.drawPath(leftV, cyan);

    final line1 = Path()..moveTo(60, 95)..lineTo(100, 95)..lineTo(92, 103)..lineTo(60, 103)..close();
    final line2 = Path()..moveTo(35, 115)..lineTo(112, 115)..lineTo(104, 123)..lineTo(35, 123)..close();
    final line3 = Path()..moveTo(42, 135)..lineTo(120, 135)..lineTo(112, 143)..lineTo(42, 143)..close();
    final line4 = Path()..moveTo(25, 155)..lineTo(128, 155)..lineTo(120, 163)..lineTo(25, 163)..close();

    canvas.drawPath(line1, cyan);
    canvas.drawPath(line2, cyan);
    canvas.drawPath(line3, cyan);
    canvas.drawPath(line4, cyan);

    final redLine1 = Path()..moveTo(48, 105)..lineTo(108, 105)..lineTo(100, 113)..lineTo(48, 113)..close();
    final redLine2 = Path()..moveTo(78, 165)..lineTo(140, 165)..lineTo(132, 173)..lineTo(78, 173)..close();

    canvas.drawPath(redLine1, orange);
    canvas.drawPath(redLine2, orange);

    final rightArrow = Path()
      ..moveTo(148, 182)
      ..lineTo(235, 60)
      ..lineTo(180, 88)
      ..lineTo(255, 50)
      ..lineTo(228, 125)
      ..lineTo(205, 98)
      ..lineTo(162, 182)
      ..close();
    canvas.drawPath(rightArrow, cyan);

    final rightOrange = Path()
      ..moveTo(182, 180)
      ..lineTo(254, 65)
      ..lineTo(222, 118)
      ..lineTo(200, 132)
      ..lineTo(225, 132)
      ..lineTo(195, 172)
      ..close();
    canvas.drawPath(rightOrange, orange);

    final TextPainter vectorTp = TextPainter(
      text: const TextSpan(
        text: "VECTOR",
        style: TextStyle(
          color: kCyanColor,
          fontSize: 38,
          fontWeight: FontWeight.w900,
          letterSpacing: 4.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    vectorTp.layout();
    vectorTp.paint(canvas, Offset((size.width - vectorTp.width) / 2, 220));

    final TextPainter vbtTp = TextPainter(
      text: const TextSpan(
        text: "— VBT —",
        style: TextStyle(
          color: kOrangeColor,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 5.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    vbtTp.layout();
    vbtTp.paint(canvas, Offset((size.width - vbtTp.width) / 2, 270));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
