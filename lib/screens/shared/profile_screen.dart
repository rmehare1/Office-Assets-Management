import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/providers/auth_provider.dart';
import 'package:office_assets_app/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:office_assets_app/theme/app_theme.dart';
import 'package:office_assets_app/models/department.dart';
import 'package:office_assets_app/models/user.dart';
import 'package:office_assets_app/widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedDepartmentId;
  List<Department> _departments = [];
  bool _loadingDepts = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadingDepts = true);
    try {
      final api = context.read<AuthProvider>().apiService;
      final depts = await api.getDepartments();
      if (mounted) setState(() => _departments = depts);
    } catch (_) {
      // Silently fail — department is optional
    } finally {
      if (mounted) setState(() => _loadingDepts = false);
    }
  }

  void _startEditing(AppUser user) {
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    _emailController.text = user.email;
    final match = _departments
        .where((d) => d.name == user.department)
        .firstOrNull;
    _selectedDepartmentId = match?.id;
    setState(() => _isEditing = true);
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    final phone = _phoneController.text.trim();
    final dept = _selectedDepartmentId != null
        ? _departments.firstWhere((d) => d.id == _selectedDepartmentId).name
        : null;

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email cannot be empty')));
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      name,
      phone: phone.isEmpty ? null : phone,
      department: dept,
      email: email.isEmpty ? null : email,
    );

    if (!mounted) return;
    if (success) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error ?? 'Update failed')));
    }
  }

  void _showChangePasswordSheet() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Password',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: currentCtrl,
                    label: 'Current Password',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: obscureCurrent,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setSheetState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: newCtrl,
                    label: 'New Password',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: obscureNew,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setSheetState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: confirmCtrl,
                    label: 'Confirm New Password',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setSheetState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (newCtrl.text != confirmCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('New passwords do not match'),
                            ),
                          );
                          return;
                        }
                        if (newCtrl.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password must be at least 6 characters',
                              ),
                            ),
                          );
                          return;
                        }
                        final auth = context.read<AuthProvider>();
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final ok = await auth.changePassword(
                          currentCtrl.text,
                          newCtrl.text,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Password changed'
                                  : (auth.error ?? 'Failed'),
                            ),
                          ),
                        );
                      },
                      child: const Text('Change Password'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().currentUser;
    final isLoading = context.watch<AuthProvider>().isLoading;
    final themeProvider = context.watch<ThemeProvider>();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _startEditing(user),
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => setState(() => _isEditing = false),
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _saveProfile(),
            ),
          ],
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
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colors.primary,
                    child: Text(
                      user.name
                          .split(' ')
                          .map((n) => n[0])
                          .join()
                          .toUpperCase(),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.role,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
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
                    'Information',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isEditing) ...[
                    _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user.phone,
                    ),
                    _InfoTile(
                      icon: Icons.business_outlined,
                      label: 'Department',
                      value: user.department,
                    ),
                    _InfoTile(
                      icon: Icons.inventory_2_outlined,
                      label: 'My Assets',
                      value: '${user.assignedAssets} assigned',
                    ),
                  ] else ...[
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                    ),

                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      prefixIcon: Icons.person_outlined,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDepartmentId,
                      decoration: InputDecoration(
                        labelText: 'Department (optional)',
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      hint: _loadingDepts
                          ? const Text('Loading...')
                          : const Text('Select department'),
                      items: _departments
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedDepartmentId = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'Settings',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Push notification alerts'),
                  secondary: const Icon(Icons.notifications_outlined),
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch to dark theme'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
                ListTile(
                  title: const Text('Change Password'),
                  leading: const Icon(Icons.key_outlined),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showChangePasswordSheet,
                ),
                if (user.role == 'admin')
                  ListTile(
                    title: const Text('Manage Categories'),
                    subtitle: const Text(
                      'Add, edit, or remove asset categories',
                    ),
                    leading: const Icon(Icons.category_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/categories'),
                  ),
                if (user.role == 'admin')
                  ListTile(
                    title: const Text('Manage Statuses'),
                    subtitle: const Text('Add, edit, or remove asset statuses'),
                    leading: const Icon(Icons.info_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/statuses'),
                  ),
                if (user.role == 'admin')
                  ListTile(
                    title: const Text('Manage Locations'),
                    subtitle: const Text(
                      'Add, edit, or remove asset locations',
                    ),
                    leading: const Icon(Icons.location_on_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/locations'),
                  ),
                if (user.role == 'admin')
                  ListTile(
                    title: const Text('Manage Departments'),
                    subtitle: const Text('Add, edit, or remove departments'),
                    leading: const Icon(Icons.business_outlined),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/departments'),
                  ),
                if (user.role == 'admin') const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AuthProvider>().logout();
                // Navigation handled by go_router redirect
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.dangerColor,
                side: const BorderSide(color: AppTheme.dangerColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
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
