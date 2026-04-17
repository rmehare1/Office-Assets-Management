import 'package:flutter/material.dart';
import 'package:office_assets_app/utils/app_strings.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/models/asset.dart';
import 'package:office_assets_app/providers/asset_provider.dart';
import 'package:office_assets_app/providers/category_provider.dart';
import 'package:office_assets_app/providers/status_provider.dart';
import 'package:office_assets_app/providers/user_provider.dart';
import 'package:office_assets_app/services/api_exception.dart';

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

  String? _categoryId;
  String? _categoryName;
  String? _statusId;
  String? _statusName;
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
    _locationController = TextEditingController(
      text: asset?.locationName ?? '',
    );
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
      if (asset.statusName.toLowerCase() == 'assigned' &&
          asset.assignedTo.isNotEmpty) {
        _assignedToUserId = asset.assignedTo;
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
      userProvider.loadUsers().then((_) {
        if (!mounted) return;
        if (asset != null &&
            asset.statusName.toLowerCase() == 'assigned' &&
            asset.assignedTo.isNotEmpty) {
          final users = userProvider.users;
          final matchById = users.where((u) => u.id == asset.assignedTo);
          if (matchById.isNotEmpty) {
            setState(() => _assignedToUserId = matchById.first.id);
          } else {
            final matchByName = users.where((u) => u.name == asset.assignedTo);
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
    if (_categoryId == null || _statusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and status')),
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
      assignedTo: (_statusName?.toLowerCase() == 'assigned')
          ? (_assignedToUserId ?? '')
          : '',
      serialNumber: _serialController.text.trim(),
      locationId: "",
      locationName: _locationController.text.trim(),
      purchaseDate: _purchaseDate,
      purchasePrice: double.parse(_priceController.text.trim()),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      assignedToName: '',
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

    final catProvider = context.watch<CategoryProvider>();
    final statProvider = context.watch<StatusProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? AppStrings.editAsset : AppStrings.addAsset,
        ),
      ),
      body: (catProvider.isLoading || statProvider.isLoading)
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.name,
                      prefixIcon: Icon(Icons.label_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? AppStrings.required
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _serialController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.serialNumber,
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? AppStrings.required
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: AppStrings.category,
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: catProvider.categories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    validator: (v) => v == null ? AppStrings.required : null,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _categoryId = v;
                        _categoryName = catProvider.categories
                            .firstWhere((c) => c.id == v)
                            .name;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _statusId,
                    decoration: const InputDecoration(
                      labelText: AppStrings.status,
                      prefixIcon: Icon(Icons.info_outlined),
                    ),
                    items: statProvider.statuses.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.name));
                    }).toList(),
                    validator: (v) => v == null ? AppStrings.required : null,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _statusId = v;
                        _statusName = statProvider.statuses
                            .firstWhere((s) => s.id == v)
                            .name;
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
                            labelText: AppStrings.assignTo,
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
                            if (_statusName?.toLowerCase() == 'assigned' &&
                                (v == null || v.isEmpty)) {
                              return AppStrings.selectUser;
                            }
                            return null;
                          },
                          onChanged: (v) =>
                              setState(() => _assignedToUserId = v),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.location,
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? AppStrings.required
                        : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: AppStrings.purchaseDate,
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        '${_purchaseDate.month}/${_purchaseDate.day}/${_purchaseDate.year}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.purchasePrice,
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return AppStrings.required;
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return AppStrings.enterValidPrice;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.notes,
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
                          : Text(
                              widget.isEditing
                                  ? AppStrings.saveChanges
                                  : AppStrings.createAsset,
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
