import 'package:flutter/material.dart';

class ModuleCard extends StatelessWidget {
  const ModuleCard({super.key, required this.title, required this.icon, required this.child, this.trailing, this.offline = false});

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                if (offline) const Chip(label: Text('离线'), visualDensity: VisualDensity.compact),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
