// lib/views/common/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool elevated;
  final EdgeInsetsGeometry padding;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.elevated = true,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (elevated) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          padding: padding,
          elevation: 4,
        ),
        child: child,
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          padding: padding,
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.12)),
        ),
        child: child,
      );
    }
  }
}
