import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/models/asset.dart';
import 'package:office_assets_app/models/ticket.dart';
import 'package:office_assets_app/providers/auth_provider.dart';
import 'package:office_assets_app/providers/ticket_provider.dart';
import 'package:office_assets_app/theme/app_theme.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTickets();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'approved':
        return AppTheme.accentColor;
      case 'rejected':
        return AppTheme.dangerColor;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    return type == 'new_asset_request'
        ? Icons.add_circle_outline
        : Icons.assignment_return_outlined;
  }

  void _showCreateTicketSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _CreateTicketSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final provider = context.watch<TicketProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadTickets(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTicketSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error loading tickets',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.dangerColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => provider.loadTickets(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : provider.tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.confirmation_number_outlined,
                            size: 64,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tickets yet',
                            style: textTheme.titleMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to raise an asset request',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.loadTickets(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = provider.tickets[index];
                          return _TicketCard(
                            ticket: ticket,
                            statusColor: _statusColor(ticket.status),
                            typeIcon: _typeIcon(ticket.type),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ── Ticket Card ──────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final Color statusColor;
  final IconData typeIcon;

  const _TicketCard({
    required this.ticket,
    required this.statusColor,
    required this.typeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, color: colors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ticket.typeLabel,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket.statusLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (ticket.assetName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ticket.assetName!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (ticket.notes != null && ticket.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                ticket.notes!,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              _formatDate(ticket.createdAt),
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ── Create Ticket Bottom Sheet ───────────────────────

class _CreateTicketSheet extends StatefulWidget {
  const _CreateTicketSheet();

  @override
  State<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<_CreateTicketSheet> {
  String _type = 'new_asset_request';
  String? _selectedAssetId;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  List<Asset> _availableAssets = [];
  bool _loadingAssets = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableAssets();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableAssets() async {
    setState(() => _loadingAssets = true);
    try {
      final apiService = context.read<AuthProvider>().apiService;
      final assets = await apiService.getAssets();
      if (mounted) {
        setState(() {
          _availableAssets = assets;
          _loadingAssets = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAssets = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final provider = context.read<TicketProvider>();
    final success = await provider.createTicket(
      type: _type,
      assetId: _selectedAssetId,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket created successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to create ticket'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'New Ticket',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          // Type selector
          Text('Ticket Type', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'new_asset_request',
                label: Text('New Asset'),
                icon: Icon(Icons.add_circle_outline),
              ),
              ButtonSegment(
                value: 'return_asset',
                label: Text('Return Asset'),
                icon: Icon(Icons.assignment_return_outlined),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) {
              setState(() {
                _type = value.first;
                _selectedAssetId = null;
              });
            },
          ),
          const SizedBox(height: 16),

          // Asset picker
          Text(
            _type == 'return_asset'
                ? 'Asset to Return'
                : 'Specific Asset (optional)',
            style: textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          _loadingAssets
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<String?>(
                  value: _selectedAssetId,
                  decoration: const InputDecoration(
                    hintText: 'Select an asset',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('None'),
                    ),
                    ..._availableAssets.map(
                      (asset) => DropdownMenuItem(
                        value: asset.id,
                        child: Text(
                          asset.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedAssetId = value),
                ),
          const SizedBox(height: 16),

          // Notes
          Text('Notes', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe your request...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),

          // Submit
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(_isSubmitting ? 'Submitting...' : 'Submit Ticket'),
          ),
        ],
      ),
    );
  }
}
