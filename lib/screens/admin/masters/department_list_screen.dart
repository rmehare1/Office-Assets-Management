import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/models/department.dart';
import 'package:office_assets_app/providers/department_provider.dart';
import 'package:office_assets_app/theme/app_theme.dart';

class DepartmentListScreen extends StatefulWidget {
  const DepartmentListScreen({super.key});

  @override
  State<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends State<DepartmentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepartmentProvider>().loadDepartments();
    });
  }

  void _showDepartmentDialog([Department? department]) {
    final isEditing = department != null;
    final nameCtrl = TextEditingController(text: department?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Department' : 'Add Department'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final deptProvider = context.read<DepartmentProvider>();
                if (isEditing) {
                  await deptProvider.updateDepartment(
                    Department(id: department.id, name: nameCtrl.text.trim()),
                  );
                } else {
                  await deptProvider.addDepartment(
                    Department(id: '', name: nameCtrl.text.trim()),
                  );
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Department department) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text('Delete "${department.name}"?'),
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
    if (confirm == true && mounted) {
      await context.read<DepartmentProvider>().deleteDepartment(department.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deptProvider = context.watch<DepartmentProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Master'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: deptProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deptProvider.departments.length,
              itemBuilder: (context, index) {
                final dept = deptProvider.departments[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.business)),
                    title: Text(dept.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showDepartmentDialog(dept),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(dept),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDepartmentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
