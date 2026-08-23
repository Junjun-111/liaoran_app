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
        // 键盘弹出时不压缩页面高度，避免把底部导航栏顶起来
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 静态背景独立成层，滚动时不再反复重绘
            const Positioned.fill(
              child: RepaintBoundary(child: BackgroundBlobs()),
            ),
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
  const _HomeAssetSection();

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

  /// 排序依据（按用户要求：添加时间 / 购买时间 / 按日均成本 / 服役时长 / 物品价值）
  static const _sortFields = <_SortField>[
    _SortField('添加时间', _SortFieldKind.createdAt),
    _SortField('购买时间', _SortFieldKind.purchaseDate),
    _SortField('按日均成本', _SortFieldKind.dailyCost),
    _SortField('服役时长', _SortFieldKind.serviceDays),
    _SortField('物品价值', _SortFieldKind.value),
  ];

  int _filterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searchOpen = false;
  int _sortFieldIndex = 0;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Asset> _applySearchAndSort(List<Asset> source) {
    final query = _searchController.text.trim().toLowerCase();
    var result = source;
    if (query.isNotEmpty) {
      result = result.where((a) {
        return a.name.toLowerCase().contains(query) ||
            a.category.toLowerCase().contains(query) ||
            a.remark.toLowerCase().contains(query) ||
            a.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }

    final field = _sortFields[_sortFieldIndex];
    final List<Asset> sorted = List.of(result);
    sorted.sort((a, b) {
      int cmp;
      switch (field.kind) {
        case _SortFieldKind.createdAt:
          cmp = a.createdAt.compareTo(b.createdAt);
        case _SortFieldKind.purchaseDate:
          cmp = a.purchaseDate.compareTo(b.purchaseDate);
        case _SortFieldKind.dailyCost:
          cmp = a.purchasePrice.compareTo(b.purchasePrice);
        case _SortFieldKind.serviceDays:
          cmp = a.purchaseDate.compareTo(b.purchaseDate);
        case _SortFieldKind.value:
          cmp = a.purchasePrice.compareTo(b.purchasePrice);
      }
      if (cmp == 0) cmp = a.createdAt.compareTo(b.createdAt);
      // 按用户确认：正序 = 当前的倒序规则，倒序 = 当前的正序规则
      return _sortAscending ? -cmp : cmp;
    });
    return sorted;
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
        _searchFocus.unfocus();
      }
    });
    if (_searchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocus.requestFocus();
      });
    }
  }

  Future<void> _openSortSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SortSheet(
        fieldIndex: _sortFieldIndex,
        ascending: _sortAscending,
        onChanged: (fieldIndex, ascending) {
          if (!mounted) return;
          setState(() {
            _sortFieldIndex = fieldIndex;
            _sortAscending = ascending;
          });
        },
      ),
    );
  }

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
        _searchController,
      ]),
      builder: (context, _) {
        final all = AssetStore.instance.items;
        final filter = _filters[_filterIndex];
        final filtered = filter == null
            ? all
            : all.where((a) => a.status == filter).toList();
        final items = _applySearchAndSort(filtered);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      for (final (i, f) in _filters.indexed) ...[
                        _FilterChip(
                          label: f?.label ?? '全部',
                          selected: i == _filterIndex,
                          onTap: () => setState(() => _filterIndex = i),
                        ),
                        if (i < _filters.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _FilterIconButton(
                  key: const ValueKey('home_search_icon'),
                  icon: _searchOpen ? Icons.close : Icons.search,
                  selected: _searchOpen,
                  onTap: _toggleSearch,
                ),
                const SizedBox(width: 8),
                _FilterIconButton(
                  key: const ValueKey('home_sort_icon'),
                  icon: Icons.swap_vert,
                  selected: _sortAscending || _sortFieldIndex != 0,
                  onTap: _openSortSheet,
                ),
              ],
            ),
            if (_searchOpen) ...[
              const SizedBox(height: 12),
              _SearchField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (_) => setState(() {}),
                onClear: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ],
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
                  onDelete: () => AssetStore.instance.moveToTrash(items[i]),
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
                  onDelete: () => AssetStore.instance.moveToTrash(asset),
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

/// 筛选行右侧的圆形图标按钮（搜索 / 排序）
class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: AppMotion.easeOut,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.72),
          shape: BoxShape.circle,
          border: selected
              ? null
              : Border.all(color: AppColors.cardStroke, width: 1),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// 展开后的搜索输入框
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardStroke, width: 1),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontFamily: AppFonts.manrope,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '搜索名称、分类、标签或备注',
          hintStyle: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: AppColors.textHint,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : GestureDetector(
                  onTap: onClear,
                  child: const Icon(
                    Icons.cancel,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
}

/// 排序依据
enum _SortFieldKind { createdAt, purchaseDate, dailyCost, serviceDays, value }

class _SortField {
  const _SortField(this.label, this.kind);

  final String label;
  final _SortFieldKind kind;
}

/// 底部排序面板：点选即生效，实时改变列表排序
class _SortSheet extends StatefulWidget {
  const _SortSheet({
    required this.fieldIndex,
    required this.ascending,
    required this.onChanged,
  });

  final int fieldIndex;
  final bool ascending;
  final void Function(int fieldIndex, bool ascending) onChanged;

  @override
  State<_SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends State<_SortSheet> {
  late int _fieldIndex = widget.fieldIndex;
  late bool _ascending = widget.ascending;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '排序方式',
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              for (final (i, field) in _HomeAssetSectionState._sortFields.indexed)
                _SortOptionRow(
                  label: field.label,
                  selected: i == _fieldIndex,
                  onTap: () {
                    setState(() => _fieldIndex = i);
                    widget.onChanged(i, _ascending);
                  },
                ),
              const Divider(height: 22, color: Color(0xFFEEF2F7)),
              _SortOptionRow(
                label: '正序',
                selected: _ascending,
                onTap: () {
                  setState(() => _ascending = true);
                  widget.onChanged(_fieldIndex, true);
                },
              ),
              _SortOptionRow(
                label: '倒序',
                selected: !_ascending,
                onTap: () {
                  setState(() => _ascending = false);
                  widget.onChanged(_fieldIndex, false);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// 排序面板中的单选行
class _SortOptionRow extends StatelessWidget {
  const _SortOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: AppMotion.easeOut,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: selected
                    ? null
                    : Border.all(color: const Color(0xFFCBD5E1), width: 1.4),
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
