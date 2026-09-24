import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TopBar extends StatelessWidget {
  final String title;
  final String? statusText;
  final Color? statusColor;
  const TopBar({super.key, required this.title, this.statusText, this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (Navigator.of(context).canPop())
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: RoundIconButton(
                  icon: Icons.chevron_left,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Colors.white,
              ),
            ),
          ],
        ),
        if (statusText != null)
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                statusText!,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
      ],
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white, size: 22)),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? color : kCard2Color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: enabled ? Colors.black : kSubColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: enabled ? Colors.black : kSubColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
