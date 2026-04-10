import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/models/location.dart';
import 'package:office_assets_app/providers/location_provider.dart';
import 'package:office_assets_app/theme/app_theme.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadLocations();
    });
  }

  void _showLocationDialog([Location? location]) {
    final isEditing = location != null;
    final nameCtrl = TextEditingController(text: location?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Location' : 'Add Location'),
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
                final locProvider = context.read<LocationProvider>();
                if (isEditing) {
                  await locProvider.updateLocation(Location(
                    id: location.id,
                    name: nameCtrl.text.trim(),
                  ));
                } else {
                  await locProvider.addLocation(Location(
                    id: '',
                    name: nameCtrl.text.trim(),
                  ));
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

  void _confirmDelete(Location location) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Delete "${location.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<LocationProvider>().deleteLocation(location.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locProvider = context.watch<LocationProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Location Master')),
      body: locProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: locProvider.locations.length,
              itemBuilder: (context, index) {
                final loc = locProvider.locations[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.location_on),
                    ),
                    title: Text(loc.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showLocationDialog(loc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(loc),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLocationDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
