import 'package:flutter/material.dart';

/// Unit converter menu - shows category selection in a bottom sheet
class UnitConverterMenu extends StatelessWidget {
  final Function(String) onCategorySelected;

  const UnitConverterMenu({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Grid layout for unit converter categories
    final categories = [
      {
        'name': 'Length',
        'category': 'length',
        'icon': Icons.straighten,
        'color': Colors.blue,
      },
      {
        'name': 'Area',
        'category': 'area',
        'icon': Icons.square_foot,
        'color': Colors.green,
      },
      {
        'name': 'Volume',
        'category': 'volume',
        'icon': Icons.crop_free,
        'color': Colors.orange,
      },
      {
        'name': 'Time',
        'category': 'time',
        'icon': Icons.access_time,
        'color': Colors.purple,
      },
      {
        'name': 'Temperature',
        'category': 'temperature',
        'icon': Icons.thermostat,
        'color': Colors.red,
      },
      {
        'name': 'Weight',
        'category': 'weight',
        'icon': Icons.scale,
        'color': Colors.indigo,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unit Converter',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          // Category grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth > 600 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryCard(
                  context,
                  name: category['name'] as String,
                  category: category['category'] as String,
                  icon: category['icon'] as IconData,
                  color: category['color'] as Color,
                );
              },
            ),
          ),
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String name,
    required String category,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onCategorySelected(category);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.9),
                color.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static method to show unit converter menu as bottom sheet
void showUnitConverterMenu(
  BuildContext context,
  Function(String) onCategorySelected,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        UnitConverterMenu(onCategorySelected: onCategorySelected),
  );
}
