import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/models/asset.dart';
import 'package:office_assets_app/providers/asset_provider.dart';
import 'package:office_assets_app/widgets/asset_card.dart';
import 'package:office_assets_app/providers/status_provider.dart';
import 'package:office_assets_app/widgets/staggered_list_item.dart';
import 'package:office_assets_app/utils/app_strings.dart';

class AssetsListScreen extends StatefulWidget {
  const AssetsListScreen({super.key});

  @override
  State<AssetsListScreen> createState() => _AssetsListScreenState();
}

class _AssetsListScreenState extends State<AssetsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<AssetProvider>().searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetProvider = context.watch<AssetProvider>();
    final statProvider = context.watch<StatusProvider>();
    final assets = assetProvider.filteredAssets;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.allAssets),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              final parts = value.split(':');
              assetProvider.setSort(parts[0], parts[1] == 'asc');
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'name:asc', child: Text('Name (A-Z)')),
              const PopupMenuItem(
                value: 'name:desc',
                child: Text('Name (Z-A)'),
              ),
              const PopupMenuItem(
                value: 'purchase_price:asc',
                child: Text('Price (Low-High)'),
              ),
              const PopupMenuItem(
                value: 'purchase_price:desc',
                child: Text('Price (High-Low)'),
              ),
              const PopupMenuItem(
                value: 'purchase_date:desc',
                child: Text('Newest First'),
              ),
              const PopupMenuItem(
                value: 'purchase_date:asc',
                child: Text('Oldest First'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: assetProvider.setSearchQuery,
              decoration: InputDecoration(
                hintText: AppStrings.searchAssets,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: assetProvider.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          assetProvider.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),
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
                ...statProvider.statuses.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.name),
                      selected: assetProvider.statusFilter == status.id,
                      onSelected: (_) => assetProvider.setStatusFilter(
                        assetProvider.statusFilter == status.id
                            ? null
                            : status.id,
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
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.noAssetsFound,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
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
