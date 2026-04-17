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
import 'package:office_assets_app/utils/app_strings.dart';
import 'package:office_assets_app/models/asset_log.dart';

class AssetDetailScreen extends StatefulWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  Asset? _fetchedAsset;
  bool _isFetching = false;
  List<AssetLog>? _history;
  bool _isFetchingHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inProvider = context.read<AssetProvider>().getById(widget.assetId);
      if (inProvider == null) {
        _fetchFromApi();
      } else {
        _fetchHistory();
      }
    });
  }

  Future<void> _fetchFromApi() async {
    setState(() => _isFetching = true);
    try {
      final asset = await context.read<AuthProvider>().apiService.getAsset(
        widget.assetId,
      );
      if (mounted) {
        setState(() {
          _fetchedAsset = asset;
          _isFetching = false;
        });
        _fetchHistory();
      }
    } catch (e) {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isFetchingHistory = true);
    try {
      final logs = await context
          .read<AuthProvider>()
          .apiService
          .getAssetHistory(widget.assetId);
      if (mounted) {
        setState(() {
          _history = logs;
          _isFetchingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingHistory = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final asset = context.read<AssetProvider>().getById(widget.assetId);
    if (asset == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteAsset),
        content: Text(
          AppStrings.deleteConfirm.replaceFirst('{name}', asset.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AssetProvider>().deleteAsset(widget.assetId);
      if (context.mounted) context.go('/assets');
    }
  }

  Future<void> _showDecommissionDialog(
    BuildContext context,
    Asset asset,
  ) async {
    final methodController = TextEditingController();
    final recyclerController = TextEditingController();
    final certController = TextEditingController();
    String selectedMethod = AppStrings.recycled;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.decommissionAsset),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(
                  labelText: AppStrings.decommissionMethod,
                ),
                items:
                    [
                          AppStrings.recycled,
                          AppStrings.disposed,
                          AppStrings.donated,
                        ]
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                onChanged: (v) => selectedMethod = v ?? selectedMethod,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: recyclerController,
                decoration: const InputDecoration(
                  labelText: AppStrings.recyclerName,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: certController,
                decoration: const InputDecoration(
                  labelText: AppStrings.certificateNumber,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<AssetProvider>().decommissionAsset(
                  asset: asset,
                  method: selectedMethod,
                  recycler: recyclerController.text.trim(),
                  cert: certController.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.decommissionSuccess),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text(AppStrings.decommission),
          ),
        ],
      ),
    );
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
        appBar: AppBar(title: const Text(AppStrings.assetDetails)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (asset == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.assetDetails)),
        body: const Center(child: Text(AppStrings.assetNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.assetDetails),
        actions: [
          if (isAdmin && asset.statusName != 'Decommissioned')
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.go('/assets/${widget.assetId}/edit'),
            ),
          if (isAdmin && asset.statusName != 'Decommissioned')
            IconButton(
              icon: const Icon(Icons.recycling_outlined),
              tooltip: AppStrings.decommission,
              onPressed: () => _showDecommissionDialog(context, asset),
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

          if (asset.statusName == 'Decommissioned')
            Card(
              color: AppTheme.dangerColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.recycling,
                          color: AppTheme.dangerColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.eWasteManagement,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.dangerColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: AppStrings.decommissionDate,
                      value: asset.decommissionedAt != null
                          ? '${asset.decommissionedAt!.month}/${asset.decommissionedAt!.day}/${asset.decommissionedAt!.year}'
                          : 'N/A',
                    ),
                    _DetailRow(
                      icon: Icons.recycling,
                      label: AppStrings.decommissionMethod,
                      value: asset.decommissionMethod ?? 'N/A',
                    ),
                    _DetailRow(
                      icon: Icons.business_outlined,
                      label: AppStrings.recyclerName,
                      value: asset.recyclerName ?? 'N/A',
                    ),
                    _DetailRow(
                      icon: Icons.verified_user_outlined,
                      label: AppStrings.certificateNumber,
                      value: asset.certificateNumber ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),
          if (asset.statusName == 'Decommissioned') const SizedBox(height: 16),

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
                          AppStrings.maintenanceOverdue,
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
                                  content: Text(AppStrings.assetServiced),
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
                        child: const Text(AppStrings.markAsServiced),
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
                    AppStrings.details,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.qr_code,
                    label: AppStrings.serialNumber,
                    value: asset.serialNumber,
                  ),
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: AppStrings.category,
                    value: asset.categoryLabel,
                  ),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: AppStrings.location,
                    value: asset.locationName,
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: AppStrings.purchaseDate,
                    value:
                        '${asset.purchaseDate.month}/${asset.purchaseDate.day}/${asset.purchaseDate.year}',
                  ),
                  _DetailRow(
                    icon: Icons.currency_rupee,
                    label: AppStrings.purchasePrice,
                    value: '${asset.purchasePrice.toStringAsFixed(2)}',
                  ),
                  if (asset.lastServiceDate != null)
                    _DetailRow(
                      icon: Icons.build_circle_outlined,
                      label: AppStrings.lastServiceDate,
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
                      AppStrings.assignment,
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
                      AppStrings.notes,
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
                          AppStrings.assetQrLabel,
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

          // Audit History Section
          if (isAdmin)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Audit History',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                        if (_isFetchingHistory)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: _fetchHistory,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_history == null && _isFetchingHistory)
                      const Center(child: Text('Loading history...'))
                    else if (_history == null || _history!.isEmpty)
                      const Text(
                        'No history records found.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    else
                      ..._history!.map((log) => _AuditLogItem(log: log)),
                  ],
                ),
              ),
            ),
          if (isAdmin) const SizedBox(height: 32),

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

class _AuditLogItem extends StatelessWidget {
  final AssetLog log;

  const _AuditLogItem({required this.log});

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    IconData icon;
    Color color;

    switch (log.action.toLowerCase()) {
      case 'created':
        icon = Icons.add_circle_outline;
        color = Colors.green;
        break;
      case 'updated':
        icon = Icons.edit_note;
        color = Colors.blue;
        break;
      case 'decommissioned':
        icon = Icons.recycling;
        color = AppTheme.dangerColor;
        break;
      case 'assigned':
        icon = Icons.person_add_alt_1_outlined;
        color = Colors.orange;
        break;
      case 'deleted':
        icon = Icons.delete_outline;
        color = AppTheme.dangerColor;
        break;
      default:
        icon = Icons.history;
        color = colors.onSurfaceVariant;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              Expanded(
                child: Container(
                  width: 1,
                  color: colors.outlineVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log.action,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        _formatDate(log.createdAt),
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${log.userName}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (log.details != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _buildDetails(context, log.details!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Map<String, dynamic> details) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.entries.map((e) {
        String from = e.value['from']?.toString() ?? 'N/A';
        String to = e.value['to']?.toString() ?? 'N/A';

        // Shorten long strings
        if (from.length > 30) from = '${from.substring(0, 27)}...';
        if (to.length > 30) to = '${to.substring(0, 27)}...';

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: RichText(
            text: TextSpan(
              style: textTheme.bodySmall?.copyWith(fontSize: 11),
              children: [
                TextSpan(
                  text: '${e.key}: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: '$from → ',
                  style: const TextStyle(color: Colors.grey),
                ),
                TextSpan(
                  text: to,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
