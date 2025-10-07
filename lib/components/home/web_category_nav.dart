import 'package:flutter/material.dart';

class WebCategoryNav extends StatelessWidget {
  const WebCategoryNav({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'All', 'icon': Icons.grid_view},
      {'name': 'CPUs', 'icon': Icons.memory},
      {'name': 'GPUs', 'icon': Icons.videogame_asset},
      {'name': 'Motherboards', 'icon': Icons.developer_board},
      {'name': 'RAM', 'icon': Icons.storage},
      {'name': 'Storage', 'icon': Icons.save},
      {'name': 'Cooling', 'icon': Icons.ac_unit},
      {'name': 'Cases', 'icon': Icons.computer},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCategoryButton(
              context,
              category['name'] as String,
              category['icon'] as IconData,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryButton(
      BuildContext context, String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              size: 18),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
