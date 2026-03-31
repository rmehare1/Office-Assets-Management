import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class AssetDetailScreen extends StatelessWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  Future<void> _confirmDelete(BuildContext context) async {
    final asset = context.read<AssetProvider>().getById(assetId);
    if (asset == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text('Are you sure you want to delete "${asset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AssetProvider>().deleteAsset(assetId);
      if (context.mounted) context.go('/assets');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final asset = context.watch<AssetProvider>().getById(assetId);

    if (asset == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Asset Details')),
        body: const Center(child: Text('Asset not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/assets/$assetId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: asset.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      asset.categoryIcon,
                      color: asset.statusColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    asset.name,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(statusName: asset.statusName, statusColorStr: asset.statusColorStr, fontSize: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.qr_code,
                    label: 'Serial Number',
                    value: asset.serialNumber,
                  ),
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: asset.categoryLabel,
                  ),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: asset.location,
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Purchase Date',
                    value:
                        '${asset.purchaseDate.month}/${asset.purchaseDate.day}/${asset.purchaseDate.year}',
                  ),
                  _DetailRow(
                    icon: Icons.currency_rupee,
                    label: 'Purchase Price',
                    value: '${asset.purchasePrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (asset.assignedTo.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignment',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colors.secondary.withValues(
                            alpha: 0.15,
                          ),
                          child: Icon(Icons.person, color: colors.secondary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          asset.assignedTo,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (asset.assignedTo.isNotEmpty) const SizedBox(height: 16),

          if (asset.notes != null && asset.notes!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      asset.notes!,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report issue feature coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Report Issue'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.warningColor,
              side: const BorderSide(color: AppTheme.warningColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
