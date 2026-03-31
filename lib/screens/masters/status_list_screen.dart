import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/status.dart';
import '../../providers/status_provider.dart';
import '../../theme/app_theme.dart';

class StatusListScreen extends StatefulWidget {
  const StatusListScreen({super.key});

  @override
  State<StatusListScreen> createState() => _StatusListScreenState();
}

class _StatusListScreenState extends State<StatusListScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatusProvider>().loadStatuses();
    });
  }

  void _showStatusDialog([Status? status]) {
    final isEditing = status != null;
    final nameCtrl = TextEditingController(text: status?.name ?? '');
    final colorCtrl = TextEditingController(text: status?.color ?? '0xFF9E9E9E');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Status' : 'Add Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(labelText: 'Color (Hex) e.g. 0xFF...'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final statProvider = context.read<StatusProvider>();
                if (isEditing) {
                  await statProvider.updateStatus(Status(
                    id: status.id,
                    name: nameCtrl.text.trim(),
                    color: colorCtrl.text.trim(),
                  ));
                } else {
                  await statProvider.addStatus(Status(
                    id: '',
                    name: nameCtrl.text.trim(),
                    color: colorCtrl.text.trim(),
                  ));
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            )
          ],
        );
      }
    );
  }

  void _confirmDelete(Status status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Status'),
        content: Text('Delete "${status.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      )
    );
    if (confirm == true && mounted) {
      await context.read<StatusProvider>().deleteStatus(status.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statProvider = context.watch<StatusProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Status Master')),
      body: statProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: statProvider.statuses.length,
              itemBuilder: (context, index) {
                final s = statProvider.statuses[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _parseColor(s.color),
                      child: const Icon(Icons.info, color: Colors.white),
                    ),
                    title: Text(s.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showStatusDialog(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(s),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStatusDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _parseColor(String? colorStr) {
    if (colorStr != null && colorStr.startsWith('0x')) {
      try {
        return Color(int.parse(colorStr));
      } catch (e) {
        return Colors.grey;
      }
    }
    return Colors.grey;
  }
}
