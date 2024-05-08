import 'package:flutter/material.dart';

class CheckboxLabel extends StatelessWidget {
  const CheckboxLabel({
    super.key,
    required this.checked,
    required this.label,
    this.onTab,
  });

  final bool checked;
  final String label;
  final VoidCallback? onTab;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTab,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IgnorePointer(child: Checkbox(value: checked, onChanged: (_) {})),
          Text(label),
        ],
      ),
    );
  }
}
