import 'package:flutter/material.dart';

class SeverityIndicator extends StatelessWidget {
  final int severity;

  const SeverityIndicator({super.key, required this.severity});

  Color get color {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Severity Level",
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.grey.shade300,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: (severity / 5) * 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          severity == 1
              ? "Very Mild"
              : severity == 2
                  ? "Mild"
                  : severity == 3
                      ? "Moderate"
                      : severity == 4
                          ? "Severe"
                          : "Critical",
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}
