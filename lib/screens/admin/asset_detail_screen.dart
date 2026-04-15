import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:office_assets_app/models/asset.dart';
import 'package:office_assets_app/providers/asset_provider.dart';
import 'package:office_assets_app/providers/auth_provider.dart';
import 'package:office_assets_app/providers/alert_provider.dart';
import 'package:office_assets_app/theme/app_theme.dart';
import 'package:office_assets_app/widgets/status_badge.dart';

class AssetDetailScreen extends StatefulWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  Asset? _fetchedAsset;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inProvider = context.read<AssetProvider>().getById(widget.assetId);
      if (inProvider == null) _fetchFromApi();
    });
  }

  Future<void> _fetchFromApi() async {
    setState(() => _isFetching = true);
    try {
      final asset = await context.read<AuthProvider>().apiService.getAsset(
        widget.assetId,
      );
      if (mounted)
        setState(() {
          _fetchedAsset = asset;
          _isFetching = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final asset = context.read<AssetProvider>().getById(widget.assetId);
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
      await context.read<AssetProvider>().deleteAsset(widget.assetId);
      if (context.mounted) context.go('/assets');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final asset =
        context.watch<AssetProvider>().getById(widget.assetId) ?? _fetchedAsset;

    if (_isFetching) {
      return Scaffold(
        appBar: AppBar(title: const Text('Asset Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.go('/assets/${widget.assetId}/edit'),
            ),
          if (isAdmin)
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
                  StatusBadge(
                    statusName: asset.statusName,
                    statusColorStr: asset.statusColorStr,
                    fontSize: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Consumer<AlertProvider>(
            builder: (context, alertProvider, child) {
              final activeAlerts = alertProvider.alerts
                  .where(
                    (a) =>
                        a.assetId == widget.assetId &&
                        (a.status == 'Pending' || a.status == 'Notified'),
                  )
                  .toList();
              if (activeAlerts.isEmpty) return const SizedBox.shrink();

              final alert = activeAlerts.first;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.dangerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.dangerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.dangerColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Maintenance Overdue',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppTheme.dangerColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(alert.message, style: textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.dangerColor,
                        ),
                        onPressed: () async {
                          try {
                            await alertProvider.updateAlertStatus(
                              alert.id,
                              'Completed',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Asset marked as serviced'),
                                ),
                              );
                              // Refresh asset to get updated last_service_date
                              _fetchFromApi();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to update: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Mark as Serviced'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

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
                    value: asset.locationName,
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
                  if (asset.lastServiceDate != null)
                    _DetailRow(
                      icon: Icons.build_circle_outlined,
                      label: 'Last Service Date',
                      value:
                          '${asset.lastServiceDate!.month}/${asset.lastServiceDate!.day}/${asset.lastServiceDate!.year}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (asset.assignedToName.isNotEmpty)
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
                          asset.assignedToName,
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
          if (asset.assignedToName.isNotEmpty) const SizedBox(height: 16),

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

          // QR Code Section (Admin only)
          if (isAdmin)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Asset QR Label',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: QrImageView(
                        data: asset.toQrJson(),
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: Color(0xFF1E3A5F),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      asset.serialNumber,
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: asset.toQrJson()),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('QR data copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Copy QR Data'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (isAdmin) const SizedBox(height: 16),

          // OutlinedButton.icon(
          //   onPressed: () {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //         content: Text('Report issue feature coming soon'),
          //       ),
          //     );
          //   },
          //   icon: const Icon(Icons.flag_outlined),
          //   label: const Text('Report Issue'),
          //   style: OutlinedButton.styleFrom(
          //     foregroundColor: AppTheme.warningColor,
          //     side: const BorderSide(color: AppTheme.warningColor),
          //     padding: const EdgeInsets.symmetric(vertical: 16),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(12),
          //     ),
          //   ),
          // ),
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
