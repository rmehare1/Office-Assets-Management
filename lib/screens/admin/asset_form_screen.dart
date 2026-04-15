import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/models/asset.dart';
import 'package:office_assets_app/providers/asset_provider.dart';
import 'package:office_assets_app/providers/category_provider.dart';
import 'package:office_assets_app/providers/status_provider.dart';
import 'package:office_assets_app/providers/location_provider.dart';
import 'package:office_assets_app/providers/user_provider.dart';
import 'package:office_assets_app/services/api_exception.dart';

class AssetFormScreen extends StatefulWidget {
  final String? assetId;
  final Map<String, dynamic>? scannedData;

  const AssetFormScreen({super.key, this.assetId, this.scannedData});

  bool get isEditing => assetId != null;

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _serialController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;

  String? _categoryId;
  String? _categoryName;
  String? _statusId;
  String? _statusName;
  String? _assignedToUserId;
  String? _locationId;
  String? _locationName;
  DateTime _purchaseDate = DateTime.now();
  DateTime? _lastServiceDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final asset = widget.assetId != null
        ? context.read<AssetProvider>().getById(widget.assetId!)
        : null;

    _nameController = TextEditingController(text: asset?.name ?? '');
    _serialController = TextEditingController(text: asset?.serialNumber ?? '');
    _priceController = TextEditingController(
      text: asset != null ? asset.purchasePrice.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: asset?.notes ?? '');

    if (asset != null) {
      _categoryId = asset.categoryId;
      _categoryName = asset.categoryName;
      _statusId = asset.statusId;
      _statusName = asset.statusName;
      _purchaseDate = asset.purchaseDate;
      _lastServiceDate = asset.lastServiceDate;
      _locationId = asset.locationId.isNotEmpty ? asset.locationId : null;
      _locationName = asset.locationName.isNotEmpty ? asset.locationName : null;
      if (asset.assignedTo.isNotEmpty) {
        _assignedToUserId = asset.assignedTo;
      }
    }

    // Apply scanned data if provided (from QR/barcode scanner)
    final scanned = widget.scannedData;
    if (scanned != null && asset == null) {
      if (scanned['serial_number'] != null) {
        _serialController.text = scanned['serial_number'].toString();
      }
      if (scanned['name'] != null) {
        _nameController.text = scanned['name'].toString();
      }
      if (scanned['purchase_price'] != null) {
        _priceController.text = scanned['purchase_price'].toString();
      }
      if (scanned['notes'] != null) {
        _notesController.text = scanned['notes'].toString();
      }
      if (scanned['purchase_date'] != null) {
        try {
          _purchaseDate = DateTime.parse(scanned['purchase_date'].toString());
        } catch (_) {}
      }
    }

    final userProvider = context.read<UserProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<CategoryProvider>().categories.isEmpty) {
        context.read<CategoryProvider>().loadCategories();
      }
      if (context.read<StatusProvider>().statuses.isEmpty) {
        context.read<StatusProvider>().loadStatuses();
      }
      if (context.read<LocationProvider>().locations.isEmpty) {
        context.read<LocationProvider>().loadLocations();
      }

      // Auto-select category/status/location from scanned data after masters load
      _applyScannedMasterData();
      userProvider.loadUsers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Matches scanned category/status/location names to their IDs after master data loads.
  void _applyScannedMasterData() {
    final scanned = widget.scannedData;
    if (scanned == null || widget.isEditing) return;

    // Match category by name
    if (scanned['category'] != null && _categoryId == null) {
      final cats = context.read<CategoryProvider>().categories;
      final match = cats.where(
        (c) => c.name.toLowerCase() == scanned['category'].toString().toLowerCase(),
      );
      if (match.isNotEmpty) {
        setState(() {
          _categoryId = match.first.id;
          _categoryName = match.first.name;
        });
      }
    }

    // Match status by name
    if (scanned['status'] != null && _statusId == null) {
      final stats = context.read<StatusProvider>().statuses;
      final match = stats.where(
        (s) => s.name.toLowerCase() == scanned['status'].toString().toLowerCase(),
      );
      if (match.isNotEmpty) {
        setState(() {
          _statusId = match.first.id;
          _statusName = match.first.name;
        });
      }
    }

    // Match location by name
    if (scanned['location'] != null && _locationId == null) {
      final locs = context.read<LocationProvider>().locations;
      final match = locs.where(
        (l) => l.name.toLowerCase() == scanned['location'].toString().toLowerCase(),
      );
      if (match.isNotEmpty) {
        setState(() {
          _locationId = match.first.id;
          _locationName = match.first.name;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastServiceDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lastServiceDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _statusId == null || _locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category, status, and location')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final asset = Asset(
      id: widget.assetId ?? '',
      name: _nameController.text.trim(),
      categoryId: _categoryId!,
      categoryName: _categoryName ?? '',
      statusId: _statusId!,
      statusName: _statusName ?? '',
      assignedTo: _assignedToUserId ?? '',
      assignedToName: '', // Backend will populate this if needed
      serialNumber: _serialController.text.trim(),
      locationId: _locationId!,
      locationName: _locationName ?? '',
      purchaseDate: _purchaseDate,
      purchasePrice: double.parse(_priceController.text.trim()),
      lastServiceDate: _lastServiceDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      final provider = context.read<AssetProvider>();
      if (widget.isEditing) {
        await provider.updateAsset(asset);
      } else {
        await provider.addAsset(asset);
      }
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final catProvider = context.watch<CategoryProvider>();
    final statProvider = context.watch<StatusProvider>();
    final locProvider = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Asset' : 'Add Asset'),
      ),
      body: (catProvider.isLoading || statProvider.isLoading || locProvider.isLoading || context.watch<UserProvider>().isLoading)
      ? const Center(child: CircularProgressIndicator()) 
      : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.label_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serialController,
              decoration: InputDecoration(
                labelText: 'Serial Number',
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: widget.isEditing
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        tooltip: 'Scan QR/Barcode',
                        onPressed: () => context.go('/scanner'),
                      ),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: catProvider.categories.map((c) {
                return DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                );
              }).toList(),
              validator: (v) => v == null ? 'Required' : null,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _categoryId = v;
                  _categoryName = catProvider.categories.firstWhere((c) => c.id == v).name;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _statusId,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.info_outlined),
              ),
              items: statProvider.statuses.map((s) {
                return DropdownMenuItem(
                  value: s.id,
                  child: Text(s.name),
                );
              }).toList(),
              validator: (v) => v == null ? 'Required' : null,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _statusId = v;
                  _statusName = statProvider.statuses.firstWhere((s) => s.id == v).name;
                  if (_statusName?.toLowerCase() != 'assigned') {
                    _assignedToUserId = null;
                  }
                });
              },
            ),
            if (_statusName?.toLowerCase() == 'assigned') ...[
              const SizedBox(height: 16),
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  final users = userProvider.users;
                  return DropdownButtonFormField<String>(
                    initialValue: _assignedToUserId,
                    decoration: const InputDecoration(
                      labelText: 'Assign To',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    items: users.map((user) {
                      return DropdownMenuItem<String>(
                        value: user.id,
                        child: Text(
                          '${user.name} (${user.department})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    validator: (v) {
                      if (_statusName?.toLowerCase() == 'assigned' && (v == null || v.isEmpty)) {
                        return 'Please select a user';
                      }
                      return null;
                    },
                    onChanged: (v) => setState(() => _assignedToUserId = v),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _locationId,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: locProvider.locations.map((l) {
                return DropdownMenuItem(
                  value: l.id,
                  child: Text(l.name),
                );
              }).toList(),
              validator: (v) => v == null ? 'Required' : null,
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _locationId = v;
                  _locationName = locProvider.locations.firstWhere((l) => l.id == v).name;
                });
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Purchase Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  '${_purchaseDate.month}/${_purchaseDate.day}/${_purchaseDate.year}',
                  style: textTheme.bodyLarge?.copyWith(color: colors.onSurface),
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickServiceDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Last Service Date (Optional)',
                  prefixIcon: Icon(Icons.build_circle_outlined),
                ),
                child: Text(
                  _lastServiceDate != null 
                      ? '${_lastServiceDate!.month}/${_lastServiceDate!.day}/${_lastServiceDate!.year}'
                      : 'Not serviced yet',
                  style: textTheme.bodyLarge?.copyWith(
                    color: _lastServiceDate != null ? colors.onSurface : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v.trim());
                if (n == null || n < 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: colors.onPrimary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(widget.isEditing ? 'Save Changes' : 'Create Asset'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
