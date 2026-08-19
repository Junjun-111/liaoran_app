import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models/asset.dart';
import '../domain/models/asset_lifecycle_status.dart';
import '../state/asset_store.dart';
import '../state/settings_store.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/asset_card.dart';
import '../widgets/asset_detail_sheet.dart';
import '../widgets/asset_grid_card.dart';
import '../widgets/asset_overview_card.dart';
import '../widgets/background_blobs.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/empty_state_card.dart';
import 'add_flow_page.dart';

/// 首页：品牌头部 + 实时资产总览 + 资产列表（含状态筛选）/ 空状态 + 悬浮底部导航
class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onNavTap});

  final ValueChanged<int>? onNavTap;

  static const double _pagePadding = 24;
  static const double _navBarHeight = 66;
  static const double _navBarBottomMargin = 24;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double topInset = mediaQuery.padding.top;
    final double bottomInset = mediaQuery.padding.bottom;

    const double statusBarRowBottom = 24;
    final double headerTop =
        (topInset > 36 ? statusBarRowBottom : topInset) + 30;

    final double navBarBottom = bottomInset + _navBarBottomMargin;
    final double bottomReserved = _navBarHeight + navBarBottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: BackgroundBlobs()),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth =
                    Responsive.contentWidthFor(constraints.maxWidth);
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: bottomReserved),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(24, headerTop, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('了然', style: AppTextStyles.brandTitle),
                                SizedBox(height: 4),
                                Text('理清资产订阅 全局一目了然',
                                    style: AppTextStyles.tagline),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _pagePadding,
                            ),
                            child: AssetOverviewCard(),
                          ),
                          const SizedBox(height: 20),
                          ListenableBuilder(
                            listenable: AssetStore.instance,
                            builder: (context, _) {
                              if (AssetStore.instance.isEmpty) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _pagePadding,
                                  ),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 100),
                                      EmptyStateCard(
                                        onAdd: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const AddFlowPage(initialTab: 0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: _pagePadding,
                                ),
                                child: _HomeAssetSection(),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: navBarBottom,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: BottomNavBar(
                  currentIndex: 0,
                  onTap: onNavTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 首页资产列表：状态筛选胶囊 + 卡片列表
class _HomeAssetSection extends StatefulWidget {
  const _HomeAssetSection({super.key});

  @override
  State<_HomeAssetSection> createState() => _HomeAssetSectionState();
}

class _HomeAssetSectionState extends State<_HomeAssetSection> {
  static const _filters = <AssetLifecycleStatus?>[
    null,
    AssetLifecycleStatus.active,
    AssetLifecycleStatus.retired,
    AssetLifecycleStatus.sold,
  ];

  int _filterIndex = 0;

  void _showDetail(Asset asset) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AssetDetailSheet(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AssetStore.instance,
        SettingsStore.instance,
      ]),
      builder: (context, _) {
        final all = AssetStore.instance.items;
        final filter = _filters[_filterIndex];
        final items = filter == null
            ? all
            : all.where((a) => a.status == filter).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (final (i, f) in _filters.indexed) ...[
                  _FilterChip(
                    label: f?.label ?? '全部',
                    selected: i == _filterIndex,
                    onTap: () => setState(() => _filterIndex = i),
                  ),
                  if (i < _filters.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
            SizedBox(
              height: SettingsStore.instance.viewStyle == '双列' ? 16 : 14,
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text(
                    '该状态下暂无资产',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              )
            else if (SettingsStore.instance.viewStyle == '双列')
              _HomeAssetGrid(
                items: items,
                onTap: _showDetail,
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                AssetCard(
                  asset: items[i],
                  onTap: () => _showDetail(items[i]),
                  onDelete: () => AssetStore.instance.remove(items[i]),
                ),
                if (i < items.length - 1) const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

class _HomeAssetGrid extends StatelessWidget {
  const _HomeAssetGrid({required this.items, required this.onTap});

  final List<Asset> items;
  final ValueChanged<Asset> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final asset in items)
              SizedBox(
                width: cardWidth,
                child: LongPressDeleteCard(
                  key: ValueKey(asset.id),
                  onTap: () => onTap(asset),
                  onDelete: () => AssetStore.instance.remove(asset),
                  child: AssetGridCard(asset: asset),
                ),
              ),
          ],
        );
      },
    );
  }
}


/// 筛选胶囊：选中绿色实心，未选白色玻璃描边
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? null
              : Border.all(color: AppColors.cardStroke, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
