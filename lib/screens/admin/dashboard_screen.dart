import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:office_assets_app/models/category.dart';
import 'package:office_assets_app/providers/asset_provider.dart';
import 'package:office_assets_app/providers/status_provider.dart';
import 'package:office_assets_app/providers/category_provider.dart';
import 'package:office_assets_app/providers/ticket_provider.dart';
import 'package:office_assets_app/widgets/asset_card.dart';
import 'package:office_assets_app/widgets/stat_card.dart';
import 'package:office_assets_app/widgets/staggered_list_item.dart';
import 'package:office_assets_app/widgets/tutorial_overlay.dart';

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

    // Create a pool of animations for dynamic cards
    _statScales = List.generate(10, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _statsController,
          curve: Interval(i * 0.1, 0.4 + i * 0.1, curve: Curves.easeOutBack),
        ),
      );
    });

    _statOpacities = List.generate(10, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _statsController,
          curve: Interval(i * 0.1, 0.3 + i * 0.1, curve: Curves.easeIn),
        ),
      );
    });

    _statsController.forward();

    // Ensure providers are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<CategoryProvider>().categories.isEmpty) {
        context.read<CategoryProvider>().loadCategories();
      }
      if (context.read<StatusProvider>().statuses.isEmpty) {
        context.read<StatusProvider>().loadStatuses();
      }
      context.read<TicketProvider>().loadAllTickets();
    });

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

  void _navigateWithFilter(BuildContext context, String? statusId) {
    context.read<AssetProvider>().setStatusFilter(statusId);
    context.go('/assets');
  }

  Widget _buildStatCard(int index, Widget child) {
    final i = index % _statScales.length;
    return AnimatedBuilder(
      animation: _statsController,
      builder: (context, _) {
        return Opacity(
          opacity: _statOpacities[i].value,
          child: Transform.scale(scale: _statScales[i].value, child: child),
        );
      },
    );
  }

  Color _parseColor(String? colorStr) {
    if (colorStr != null && colorStr.startsWith('0x')) {
      return Color(int.parse(colorStr));
    }
    return Colors.grey;
  }

  IconData _parseIcon(String? iconStr) {
    if (iconStr == 'laptop') return Icons.computer;
    if (iconStr == 'monitor') return Icons.monitor;
    if (iconStr == 'phone') return Icons.smartphone;
    if (iconStr == 'furniture') return Icons.chair;
    if (iconStr == 'accessory') return Icons.keyboard;
    return Icons.devices;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final assetProvider = context.watch<AssetProvider>();
    final statProvider = context.watch<StatusProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body:
              (assetProvider.isLoading ||
                  statProvider.isLoading ||
                  catProvider.isLoading)
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await assetProvider.loadAssets();
                    await statProvider.loadStatuses();
                    await catProvider.loadCategories();
                  },
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
                                  onPressed: () =>
                                      assetProvider.setSearchQuery(''),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      GridView.count(
                        key: _statsKey,
                        crossAxisCount: isDesktop ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: isDesktop ? 3.0 : 1.4,
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
                          ...List.generate(
                            statProvider.statuses
                                .where((s) => s.name.toLowerCase() != 'retired')
                                .length,
                            (index) {
                              final status = statProvider.statuses
                                  .where(
                                    (s) => s.name.toLowerCase() != 'retired',
                                  )
                                  .toList()[index];
                              final count = assetProvider.assets
                                  .where((a) => a.statusId == status.id)
                                  .length;
                              return _buildStatCard(
                                index + 1,
                                GestureDetector(
                                  onTap: () =>
                                      _navigateWithFilter(context, status.id),
                                  child: StatCard(
                                    title: status.name,
                                    value: '$count',
                                    icon: Icons.info_outline,
                                    color: _parseColor(status.color),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _RecentTicketsBanner(
                        pendingCount: context
                            .watch<TicketProvider>()
                            .allTickets
                            .where((t) => t.status == 'pending')
                            .length,
                        totalCount: context
                            .watch<TicketProvider>()
                            .allTickets
                            .length,
                        onTap: () => context.go('/admin/tickets'),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Categories',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (assetProvider.assets.isNotEmpty)
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: assetProvider.categoryBreakdown.entries
                                .map((entry) {
                                  final cat = catProvider.categories.firstWhere(
                                    (c) => c.name == entry.key,
                                    orElse: () => Category(
                                      id: '',
                                      name: entry.key,
                                      icon: 'devices',
                                      color: '0xFF9E9E9E',
                                    ),
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Chip(
                                      avatar: Icon(
                                        _parseIcon(cat.icon),
                                        size: 18,
                                        color: _parseColor(cat.color),
                                      ),
                                      label: Text(
                                        '${entry.key}: ${entry.value}',
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 24),

                      Row(
                        key: _assetsKey,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Assets',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          if (assetProvider.searchQuery.isNotEmpty)
                            Text(
                              '${assetProvider.filteredAssets.length} results',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (assetProvider.filteredAssets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No assets match your search',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
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
                                onTap: () =>
                                    context.go('/assets/${entry.value.id}'),
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
                description:
                    'Quickly find any asset by name, category, location, or serial number.',
                icon: Icons.search,
              ),
              TutorialStep(
                targetKey: _statsKey,
                title: 'Asset Overview',
                description:
                    'Tap any stat card to jump to a filtered view of those assets.',
                icon: Icons.dashboard,
              ),
              TutorialStep(
                targetKey: _assetsKey,
                title: 'Recent Assets',
                description:
                    'Browse your latest assets here. Tap any card to see full details.',
                icon: Icons.inventory_2,
              ),
            ],
            onComplete: () => setState(() => _showTutorial = false),
          ),
      ],
    );
  }
}

class _RecentTicketsBanner extends StatelessWidget {
  final int pendingCount;
  final int totalCount;
  final VoidCallback onTap;

  const _RecentTicketsBanner({
    required this.pendingCount,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.15),
            Colors.orange.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Tickets',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'You have $pendingCount active requests to review',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '$totalCount total requests in system',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$pendingCount',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.orange,
                        letterSpacing: -1,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'View All',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
