import 'package:flutter/material.dart';

import '../data/local/local_trash_repository.dart';
import '../state/asset_store.dart';
import '../state/trash_store.dart';
import '../theme/app_theme.dart';
import '../widgets/background_blobs.dart';

/// 回收站：最近删除的资产，30 天内可恢复。
class TrashPage extends StatelessWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: BackgroundBlobs()),
          SafeArea(
            child: ListenableBuilder(
              listenable: TrashStore.instance,
              builder: (context, _) {
                final entries = TrashStore.instance.entries;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TrashHeader(
                      onBack: () => Navigator.of(context).pop(),
                      count: entries.length,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: entries.isEmpty
                          ? const _TrashEmpty()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: entries.length + 1,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index == entries.length) {
                                  return _ClearAllButton();
                                }
                                final entry = entries[index];
                                return _TrashCard(
                                  entry: entry,
                                  onRestore: () {
                                    final asset =
                                        TrashStore.instance.restore(entry);
                                    if (asset != null) {
                                      AssetStore.instance.add(asset);
                                    }
                                  },
                                  onDeleteForever: () {
                                    TrashStore.instance.deleteForever(entry);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrashHeader extends StatelessWidget {
  const _TrashHeader({required this.onBack, required this.count});

  final VoidCallback onBack;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardStroke),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadowBlack,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('回收站', style: AppTextStyles.brandTitle),
                SizedBox(height: 2),
                Text('最近删除 30 天内可恢复', style: AppTextStyles.pageSubtitle),
              ],
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count 项',
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrashCard extends StatelessWidget {
  const _TrashCard({
    required this.entry,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final TrashEntry entry;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  String _remainingDays() {
    final days = DateTime.now().difference(entry.deletedAt).inDays;
    final remaining = 30 - days;
    if (remaining <= 0) return '即将过期';
    return '剩余 $remaining 天';
  }

  @override
  Widget build(BuildContext context) {
    final asset = entry.asset;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardStroke),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadowPrimary,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4FAF8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 22,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${asset.category} · ${_remainingDays()}',
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRestore,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '恢复',
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDeleteForever,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: Color(0xFFE5484D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearAllButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '清空回收站',
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: const Text('清空后所有资产将被永久删除，无法恢复。确认清空吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    '清空',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE5484D),
                    ),
                  ),
                ),
              ],
            ),
          );
          if (ok == true) {
            TrashStore.instance.clear();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.cardStroke),
          ),
          child: const Text(
            '清空回收站',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE5484D),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrashEmpty extends StatelessWidget {
  const _TrashEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_sweep_outlined,
            size: 52,
            color: AppColors.textHint,
          ),
          SizedBox(height: 14),
          Text(
            '回收站是空的',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5),
          Text(
            '删除的资产会在这里保留 30 天',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
