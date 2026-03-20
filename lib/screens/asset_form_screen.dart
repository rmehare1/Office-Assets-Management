import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_exception.dart';

class AssetFormScreen extends StatefulWidget {
  final String? assetId;

  const AssetFormScreen({super.key, this.assetId});

  bool get isEditing => assetId != null;

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _serialController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  AssetCategory _category = AssetCategory.laptop;
  AssetStatus _status = AssetStatus.available;
  String? _assignedToUserId;
  DateTime _purchaseDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final asset = widget.assetId != null
        ? context.read<AssetProvider>().getById(widget.assetId!)
        : null;

    _nameController = TextEditingController(text: asset?.name ?? '');
    _serialController = TextEditingController(text: asset?.serialNumber ?? '');
    _locationController = TextEditingController(text: asset?.location ?? '');
    _priceController = TextEditingController(
      text: asset != null ? asset.purchasePrice.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: asset?.notes ?? '');

    if (asset != null) {
      _category = asset.category;
      _status = asset.status;
      _purchaseDate = asset.purchaseDate;
      if (asset.status == AssetStatus.assigned && asset.assignedTo.isNotEmpty) {
        _assignedToUserId = asset.assignedTo;
      }
    }

    // Load users for the assign-to dropdown
    final userProvider = context.read<UserProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userProvider.loadUsers().then((_) {
        if (!mounted) return;
        // If editing and assignedTo is a name (from assigned_to_name), resolve to user ID
        if (asset != null &&
            asset.status == AssetStatus.assigned &&
            asset.assignedTo.isNotEmpty) {
          final users = userProvider.users;
          final matchById = users.where((u) => u.id == asset.assignedTo);
          if (matchById.isNotEmpty) {
            setState(() => _assignedToUserId = matchById.first.id);
          } else {
            // Try matching by name (API returns assigned_to_name)
            final matchByName =
                users.where((u) => u.name == asset.assignedTo);
            if (matchByName.isNotEmpty) {
              setState(() => _assignedToUserId = matchByName.first.id);
            }
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final asset = Asset(
      id: widget.assetId ?? '',
      name: _nameController.text.trim(),
      category: _category,
      status: _status,
      assignedTo: _status == AssetStatus.assigned ? (_assignedToUserId ?? '') : '',
      serialNumber: _serialController.text.trim(),
      location: _locationController.text.trim(),
      purchaseDate: _purchaseDate,
      purchasePrice: double.parse(_priceController.text.trim()),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Asset' : 'Add Asset'),
      ),
      body: Form(
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
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serialController,
              decoration: const InputDecoration(
                labelText: 'Serial Number',
                prefixIcon: Icon(Icons.qr_code),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AssetCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AssetCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.name[0].toUpperCase() + c.name.substring(1)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AssetStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.info_outlined),
              ),
              items: AssetStatus.values.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s.name[0].toUpperCase() + s.name.substring(1)),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _status = v!;
                  if (_status != AssetStatus.assigned) {
                    _assignedToUserId = null;
                  }
                });
              },
            ),
            // Conditional Assign-To dropdown
            if (_status == AssetStatus.assigned) ...[
              const SizedBox(height: 16),
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  final users = userProvider.users;
                  return DropdownButtonFormField<String>(
                    value: _assignedToUserId,
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
                      if (_status == AssetStatus.assigned &&
                          (v == null || v.isEmpty)) {
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
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
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
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
