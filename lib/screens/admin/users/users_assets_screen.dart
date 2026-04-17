import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/models/asset.dart';
import 'package:office_assets_app/providers/auth_provider.dart';
import 'package:office_assets_app/theme/app_theme.dart';
import 'package:office_assets_app/widgets/asset_card.dart';

import 'package:office_assets_app/providers/asset_provider.dart';

class UsersAssetsScreen extends StatefulWidget {
  final String userId;
  const UsersAssetsScreen({super.key, required this.userId});

  @override
  State<UsersAssetsScreen> createState() => _UsersAssetsScreenState();
}

class _UsersAssetsScreenState extends State<UsersAssetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    context.read<AssetProvider>().loadUserAssets(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final assetProvider = context.watch<AssetProvider>();
    final assets = assetProvider.userAssets;

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
      body: assetProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : assetProvider.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error: ${assetProvider.error}',
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
          : assets.isEmpty
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
                    'No assets assigned to user',
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
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
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
