import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/models/user.dart';
import 'package:office_assets_app/providers/auth_provider.dart';
import 'package:office_assets_app/theme/app_theme.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<AppUser> _users = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUsers());
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users =
          await context.read<AuthProvider>().apiService.getUsers();
      if (mounted) setState(() { _users = users; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _changeRole(AppUser user) async {
    String selected = user.role;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Change Role — ${user.name}'),
          content: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(value: 'user', child: Text('User')),
            ],
            onChanged: (v) {
              if (v != null) setDialogState(() => selected = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selected != user.role) {
      if (!mounted) return;
      try {
        await context.read<AuthProvider>().apiService.updateUserRole(user.id, selected);
        if (mounted) _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update role: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: $_error',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.dangerColor)),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _loadUsers, child: const Text('Retry')),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final initials = user.name
                            .split(' ')
                            .take(2)
                            .map((w) => w.isNotEmpty ? w[0] : '')
                            .join()
                            .toUpperCase();
                        final isAdmin = user.role == 'admin';
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor:
                                  colors.primary.withValues(alpha: 0.15),
                              child: Text(initials,
                                  style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(user.name,
                                style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(user.email,
                                style: textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Chip(
                                  label: Text(
                                    isAdmin ? 'Admin' : 'User',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: isAdmin
                                          ? colors.onPrimary
                                          : colors.onSurfaceVariant,
                                    ),
                                  ),
                                  backgroundColor: isAdmin
                                      ? colors.primary
                                      : colors.surfaceContainerHighest,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 20),
                                  onPressed: () => _changeRole(user),
                                  tooltip: 'Change role',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
