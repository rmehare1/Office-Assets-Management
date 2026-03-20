import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../widgets/asset_card.dart';
import '../widgets/staggered_list_item.dart';

class AssetsListScreen extends StatelessWidget {
  const AssetsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assetProvider = context.watch<AssetProvider>();
    final assets = assetProvider.filteredAssets;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Assets'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              final parts = value.split(':');
              assetProvider.setSort(parts[0], parts[1] == 'asc');
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'name:asc', child: Text('Name (A-Z)')),
              const PopupMenuItem(value: 'name:desc', child: Text('Name (Z-A)')),
              const PopupMenuItem(value: 'purchase_price:asc', child: Text('Price (Low-High)')),
              const PopupMenuItem(value: 'purchase_price:desc', child: Text('Price (High-Low)')),
              const PopupMenuItem(value: 'purchase_date:desc', child: Text('Newest First')),
              const PopupMenuItem(value: 'purchase_date:asc', child: Text('Oldest First')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: assetProvider.statusFilter == null,
                  onSelected: (_) => assetProvider.setStatusFilter(null),
                ),
                const SizedBox(width: 8),
                ...AssetStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.name[0].toUpperCase() + status.name.substring(1)),
                      selected: assetProvider.statusFilter == status,
                      onSelected: (_) => assetProvider.setStatusFilter(
                        assetProvider.statusFilter == status ? null : status,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Asset list
          Expanded(
            child: assetProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : assets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: colors.onSurfaceVariant),
                            const SizedBox(height: 16),
                            Text('No assets found', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: assetProvider.loadAssets,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: assets.length,
                          itemBuilder: (context, index) {
                            final asset = assets[index];
                            return StaggeredListItem(
                              index: index,
                              baseDelay: Duration.zero,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: AssetCard(
                                  asset: asset,
                                  onTap: () => context.go('/assets/${asset.id}'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/assets/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
