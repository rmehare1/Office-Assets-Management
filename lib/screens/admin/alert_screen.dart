import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/providers/alert_provider.dart';
import 'package:office_assets_app/theme/app_theme.dart';
import 'package:office_assets_app/models/maintenance_alert.dart';
import 'package:office_assets_app/utils/app_strings.dart';

class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertProvider>().loadAlerts();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppTheme.dangerColor;
      case 'Notified':
        return AppTheme.warningColor;
      case 'Completed':
        return AppTheme.accentColor;
      case 'Dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(MaintenanceAlert alert, String newStatus) async {
    try {
      await context.read<AlertProvider>().updateAlertStatus(
        alert.id,
        newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Alert marked as $newStatus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update alert: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final alerts = alertProvider.alerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.maintenanceAlerts),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AlertProvider>().loadAlerts(),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: alertProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : alertProvider.error != null
          ? Center(
              child: Text(
                'Error: ${alertProvider.error}',
                style: const TextStyle(color: AppTheme.dangerColor),
              ),
            )
          : alerts.isEmpty
          ? const Center(child: Text(AppStrings.noMaintenanceAlerts))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final isPending =
                    alert.status == 'Pending' || alert.status == 'Notified';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(
                        alert.status,
                      ).withValues(alpha: 0.2),
                      child: Icon(
                        isPending
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: _getStatusColor(alert.status),
                      ),
                    ),
                    title: Text(alert.assetName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${alert.message}\nStatus: ${alert.status}'),
                        if (alert.serialNumber != null)
                          Text(
                            'SN: ${alert.serialNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: isPending
                        ? PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'view') {
                                context.go('/assets/${alert.assetId}');
                              } else {
                                _updateStatus(alert, val);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Text(AppStrings.viewAsset),
                              ),
                              const PopupMenuItem(
                                value: 'Completed',
                                child: Text(AppStrings.markCompleted),
                              ),
                              const PopupMenuItem(
                                value: 'Dismissed',
                                child: Text(AppStrings.dismiss),
                              ),
                            ],
                          )
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () =>
                                context.go('/assets/${alert.assetId}'),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
