import 'package:flutter/material.dart';

const kPurpleAccent = Color(0xFF6C22FF);
const kDarkCardBg = Color(0xFF16161E);
const kDarkBg = Color(0xFF0D0D12);

class NumberKeyboardSheet extends StatefulWidget {
  final String title;
  final String initialValue;
  final String unit;
  final Function(String) onConfirm;

  const NumberKeyboardSheet({
    super.key,
    required this.title,
    required this.initialValue,
    this.unit = '',
    required this.onConfirm,
  });

  @override
  State<NumberKeyboardSheet> createState() => _NumberKeyboardSheetState();
}

class _NumberKeyboardSheetState extends State<NumberKeyboardSheet> {
  late String _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue == '—' ? '' : widget.initialValue;
  }

  void _onKeyPress(String val) {
    setState(() {
      if (val == '.' && _currentValue.contains('.')) return;
      _currentValue += val;
    });
  }

  void _onBackspace() {
    if (_currentValue.isNotEmpty) {
      setState(() {
        _currentValue = _currentValue.substring(0, _currentValue.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: kDarkCardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Поле введення з фіолетовим курсором
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: kDarkBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPurpleAccent.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _currentValue.isEmpty ? '0' : _currentValue,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.unit,
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 20),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    widget.onConfirm(_currentValue.isEmpty ? '—' : _currentValue);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPurpleAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Сітка цифрової клавіатури
          Column(
            children: [
              _buildKeyboardRow(['1', '2', '3']),
              const SizedBox(height: 10),
              _buildKeyboardRow(['4', '5', '6']),
              const SizedBox(height: 10),
              _buildKeyboardRow(['7', '8', '9']),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildKeyButton('.', onTap: () => _onKeyPress('.')),
                  const SizedBox(width: 10),
                  _buildKeyButton('0', onTap: () => _onKeyPress('0')),
                  const SizedBox(width: 10),
                  _buildKeyButton('', icon: Icons.backspace_outlined, onTap: _onBackspace),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _buildKeyButton(key, onTap: () => _onKeyPress(key)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyButton(String text, {IconData? icon, VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: kDarkBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 22)
                : Text(text, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
