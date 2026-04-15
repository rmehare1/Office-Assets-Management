import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/models/asset.dart';
import 'package:office_assets_app/providers/auth_provider.dart';
import 'package:office_assets_app/theme/app_theme.dart';
import 'package:office_assets_app/widgets/asset_card.dart';

class UsersAssetsScreen extends StatefulWidget {
  final String userId;
  const UsersAssetsScreen({super.key, required this.userId});

  @override
  State<UsersAssetsScreen> createState() => _UsersAssetsScreenState();
}

class _UsersAssetsScreenState extends State<UsersAssetsScreen> {
  List<Asset> _assets = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // final userId = context.read<AuthProvider>().currentUser!.id;
      final assets = await context.read<AuthProvider>().apiService.getAssets(
        assignedToUserId: this.widget.userId!,
      );
      if (mounted)
        setState(() {
          _assets = assets;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Assets'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/users'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error: $_error',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.dangerColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _assets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No assets assigned to you',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _assets.length,
                itemBuilder: (context, index) {
                  final asset = _assets[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AssetCard(
                      asset: asset,
                      onTap: () => context.go('/assets/${asset.id}'),
                      showStatus: false,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
