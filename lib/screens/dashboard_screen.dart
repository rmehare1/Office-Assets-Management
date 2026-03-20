import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/asset_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/staggered_list_item.dart';
import '../widgets/tutorial_overlay.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _statsController;
  late List<Animation<double>> _statScales;
  late List<Animation<double>> _statOpacities;
  bool _showTutorial = false;

  final _searchKey = GlobalKey();
  final _statsKey = GlobalKey();
  final _assetsKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _statScales = List.generate(4, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _statsController,
          curve: Interval(i * 0.15, 0.4 + i * 0.15, curve: Curves.easeOutBack),
        ),
      );
    });

    _statOpacities = List.generate(4, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _statsController,
          curve: Interval(i * 0.15, 0.3 + i * 0.15, curve: Curves.easeIn),
        ),
      );
    });

    _statsController.forward();

    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final show = await TutorialOverlay.shouldShow('dashboard');
    if (show && mounted) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _showTutorial = true);
    }
  }

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }

  void _navigateWithFilter(BuildContext context, AssetStatus? status) {
    context.read<AssetProvider>().setStatusFilter(status);
    context.go('/assets');
  }

  Widget _buildStatCard(int index, Widget child) {
    return AnimatedBuilder(
      animation: _statsController,
      builder: (context, _) {
        return Opacity(
          opacity: _statOpacities[index].value,
          child: Transform.scale(
            scale: _statScales[index].value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final assetProvider = context.watch<AssetProvider>();

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body: assetProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: assetProvider.loadAssets,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                        key: _searchKey,
                        onChanged: assetProvider.setSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Search assets...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: assetProvider.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => assetProvider.setSearchQuery(''),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      GridView.count(
                        key: _statsKey,
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _buildStatCard(
                            0,
                            GestureDetector(
                              onTap: () => _navigateWithFilter(context, null),
                              child: StatCard(
                                title: 'Total Assets',
                                value: '${assetProvider.totalAssets}',
                                icon: Icons.inventory_2,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          _buildStatCard(
                            1,
                            GestureDetector(
                              onTap: () => _navigateWithFilter(context, AssetStatus.available),
                              child: StatCard(
                                title: 'Available',
                                value: '${assetProvider.availableCount}',
                                icon: Icons.check_circle_outline,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ),
                          _buildStatCard(
                            2,
                            GestureDetector(
                              onTap: () => _navigateWithFilter(context, AssetStatus.assigned),
                              child: StatCard(
                                title: 'Assigned',
                                value: '${assetProvider.assignedCount}',
                                icon: Icons.person_outline,
                                color: colors.secondary,
                              ),
                            ),
                          ),
                          _buildStatCard(
                            3,
                            GestureDetector(
                              onTap: () => _navigateWithFilter(context, AssetStatus.maintenance),
                              child: StatCard(
                                title: 'Maintenance',
                                value: '${assetProvider.maintenanceCount}',
                                icon: Icons.build_outlined,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Categories',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface),
                      ),
                      const SizedBox(height: 12),
                      if (assetProvider.assets.isNotEmpty)
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: assetProvider.categoryBreakdown.entries.map((entry) {
                              final sampleAsset = assetProvider.assets.firstWhere((a) => a.category == entry.key);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  avatar: Icon(sampleAsset.categoryIcon, size: 18),
                                  label: Text('${sampleAsset.categoryLabel}: ${entry.value}'),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),

                      Row(
                        key: _assetsKey,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Assets', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface)),
                          if (assetProvider.searchQuery.isNotEmpty)
                            Text('${assetProvider.filteredAssets.length} results', style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (assetProvider.filteredAssets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 48, color: colors.onSurfaceVariant),
                              const SizedBox(height: 8),
                              Text('No assets match your search', style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                            ],
                          ),
                        )
                      else
                        ...assetProvider.filteredAssets.asMap().entries.map(
                          (entry) => StaggeredListItem(
                            index: entry.key,
                            baseDelay: const Duration(milliseconds: 600),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AssetCard(
                                asset: entry.value,
                                onTap: () => context.go('/assets/${entry.value.id}'),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        if (_showTutorial)
          TutorialOverlay(
            tutorialId: 'dashboard',
            steps: [
              TutorialStep(
                targetKey: _searchKey,
                title: 'Search Assets',
                description: 'Quickly find any asset by name, category, location, or serial number.',
                icon: Icons.search,
              ),
              TutorialStep(
                targetKey: _statsKey,
                title: 'Asset Overview',
                description: 'Tap any stat card to jump to a filtered view of those assets.',
                icon: Icons.dashboard,
              ),
              TutorialStep(
                targetKey: _assetsKey,
                title: 'Recent Assets',
                description: 'Browse your latest assets here. Tap any card to see full details.',
                icon: Icons.inventory_2,
              ),
            ],
            onComplete: () => setState(() => _showTutorial = false),
          ),
      ],
    );
  }
}
