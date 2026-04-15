import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/models/category.dart';
import 'package:office_assets_app/providers/category_provider.dart';
import 'package:office_assets_app/theme/app_theme.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  void _showCategoryDialog([Category? category]) {
    final isEditing = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final colorCtrl = TextEditingController(
      text: category?.color ?? '0xFF9E9E9E',
    );
    final iconCtrl = TextEditingController(text: category?.icon ?? 'devices');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
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
                decoration: const InputDecoration(
                  labelText: 'Color (Hex) e.g. 0xFF...',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: iconCtrl,
                decoration: const InputDecoration(
                  labelText: 'Icon String e.g. laptop',
                ),
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
                final catProvider = context.read<CategoryProvider>();
                if (isEditing) {
                  await catProvider.updateCategory(
                    Category(
                      id: category.id,
                      name: nameCtrl.text.trim(),
                      color: colorCtrl.text.trim(),
                      icon: iconCtrl.text.trim(),
                    ),
                  );
                } else {
                  await catProvider.addCategory(
                    Category(
                      id: '',
                      name: nameCtrl.text.trim(),
                      color: colorCtrl.text.trim(),
                      icon: iconCtrl.text.trim(),
                    ),
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

  void _confirmDelete(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${category.name}"?'),
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
      await context.read<CategoryProvider>().deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Master'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: catProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: catProvider.categories.length,
              itemBuilder: (context, index) {
                final c = catProvider.categories[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _parseColor(c.color),
                      child: const Icon(Icons.category, color: Colors.white),
                    ),
                    title: Text(c.name),
                    subtitle: Text('Icon: ${c.icon}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showCategoryDialog(c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(c),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
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
