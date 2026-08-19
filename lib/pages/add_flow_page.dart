import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/models/asset.dart';
import '../domain/models/asset_lifecycle_status.dart';
import '../domain/models/wishlist_item.dart';
import '../models/subscription.dart';
import '../services/upload_service.dart';
import '../state/asset_store.dart';
import '../state/settings_store.dart';
import '../state/subscription_store.dart';
import '../state/wishlist_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_date_picker.dart';
import '../widgets/dialog_controllers.dart';
import '../widgets/item_icon.dart';
import '../widgets/top_snackbar.dart';
import 'icon_matting_editor_page.dart';

/// 添加流程页（资产 / 订阅 / 心愿）
///
/// 视觉严格按用户提供的 Figma 转 Flutter 代码
/// `add_subscription_screen.dart` 1:1 复刻：
/// - 背景渐变 begin(-0.6,-1)→end(0.6,1)，stops [0.08, 0.42, 0.92]
/// - 顶栏：chevron_left 28/#444444 + 「添加」24.6/加粗/行高 1.5
/// - Tab：Material 图标 + AnimatedContainer(200ms)
/// - 图标区：89.6 圆角 25 渐变方块 + 40 图标
/// - 提交按钮固定在底部（滚动区外），94 高、圆角 24.6、渐变 #5DDBA0→#2BAF74
///
/// 在 1:1 基础上保留完整交互：表单校验、保存到订阅管理、系统相册上传、换图标。
class AddFlowPage extends StatefulWidget {
  const AddFlowPage({
    super.key,
    this.initialTab = 0,
    this.editingSubscription,
    this.editingAsset,
  });

  final int initialTab;

  /// 编辑模式：传入已有订阅时只显示订阅表单并回填
  final Subscription? editingSubscription;

  /// 编辑模式：传入已有资产时只显示资产表单并回填
  final Asset? editingAsset;

  @override
  State<AddFlowPage> createState() => _AddFlowPageState();
}

class _AddFlowPageState extends State<AddFlowPage> {
  late int _tab =
      widget.editingSubscription != null
          ? 1
          : widget.editingAsset != null
              ? 0
              : widget.initialTab.clamp(0, 2);

  static const _tabLabels = ['资产', '订阅', '心愿'];

  final _assetKey = GlobalKey<_AssetFormState>();
  final _subKey = GlobalKey<_SubscriptionFormState>();
  final _wishKey = GlobalKey<_WishFormState>();

  /// 订阅页所选图标资源；null 表示默认 Material 日历图标
  late String? _subIcon = widget.editingSubscription?.icon;

  /// 资产页所选图标资源（默认资产图标）
  late String? _assetIcon =
      widget.editingAsset?.icon ?? 'assets/CodeBuddyAssets/42_951/6.svg';

  /// 心愿页所选图标资源
  String _wishIcon = 'assets/CodeBuddyAssets/43_1372/5.svg';

  /// “更换图标”入口：拍照 / 选图 → 图标调整页（AI 抠图 + 框选 + 缩放）→ 设为图标。
  Future<void> _changeIcon(int tab) async {
    final source = await _pickPhotoSource();
    if (source == null || !mounted) return;

    // emoji 图标：输入一个 emoji 直接作为主图，不走抠图流程
    if (source == 'emoji') {
      final emoji = await _pickEmoji();
      if (emoji == null || !mounted) return;
      setState(() {
        if (tab == 0) {
          _assetIcon = emojiIcon(emoji);
        } else if (tab == 1) {
          _subIcon = emojiIcon(emoji);
        } else {
          _wishIcon = emojiIcon(emoji);
        }
      });
      showTopSnackBar(context, '已设为图标');
      return;
    }

    // 拍照 / 相册选择：先选图，再进入 AI 抠图调整页
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    final path = picked?.path;
    if (path == null || !mounted) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => IconMattingEditorPage(sourcePath: path),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (tab == 0) {
        _assetIcon = result;
      } else if (tab == 1) {
        _subIcon = result;
      } else {
        _wishIcon = result;
      }
    });
    showTopSnackBar(context, 'AI 抠图完成，已设为图标');
  }

  /// 弹窗输入一个 emoji；只允许单个 emoji，取消返回 null。
  Future<String?> _pickEmoji() async {
    return showDialog<String>(
      context: context,
      builder: (_) => const _EmojiInputDialog(),
    );
  }

  Future<String?> _pickPhotoSource() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E8E6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '拍摄 / 选择照片',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '选中后自动 AI 抠图，秒出透明底图标',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 14),
              _PhotoSourceRow(
                icon: Icons.photo_camera_outlined,
                title: '拍照',
                value: 'camera',
                onSelected: (v) => Navigator.of(sheetCtx).pop(v),
              ),
              const SizedBox(height: 8),
              _PhotoSourceRow(
                icon: Icons.photo_library_outlined,
                title: '从相册选择',
                value: 'gallery',
                onSelected: (v) => Navigator.of(sheetCtx).pop(v),
              ),
              const SizedBox(height: 8),
              _PhotoSourceRow(
                icon: Icons.emoji_emotions_outlined,
                title: '输入 emoji',
                value: 'emoji',
                onSelected: (v) => Navigator.of(sheetCtx).pop(v),
              ),
            ],
          ),
        ),
      ),
    );
    return action;
  }

  bool get _isEditing =>
      widget.editingSubscription != null || widget.editingAsset != null;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.6, -1),
              end: Alignment(0.6, 1),
              colors: [_C.bg1, _C.bg2, _C.bg3],
              stops: [0.08, 0.42, 0.92],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  title: _isEditing ? '编辑' : '添加',
                  onConfirm: _confirmForTab(_tab),
                ),
                if (!_isEditing)
                  _TabBar(
                    labels: _tabLabels,
                    current: _tab,
                    onTap: (i) => setState(() => _tab = i),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        _buildIconPreview(),
                        _buildForm(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconPreview() {
    switch (_tab) {
      case 0:
        return _IconPreview(
          icon: _assetIcon,
          defaultIcon: Icons.inventory_2_outlined,
          onTap: () => _changeIcon(0),
        );
      case 1:
        return _IconPreview(
          icon: _subIcon,
          defaultIcon: Icons.subscriptions_outlined,
          onTap: () => _changeIcon(1),
        );
      default:
        return _IconPreview(icon: _wishIcon, onTap: () => _changeIcon(2));
    }
  }

  Widget _buildForm() {
    switch (_tab) {
      case 0:
        return _AssetForm(
          key: _assetKey,
          icon: _assetIcon,
          editing: widget.editingAsset,
        );
      case 1:
        return _SubscriptionForm(
          key: _subKey,
          icon: _subIcon,
          editing: widget.editingSubscription,
        );
      default:
        return _WishForm(key: _wishKey, icon: _wishIcon);
    }
  }

  VoidCallback _confirmForTab(int tab) {
    switch (tab) {
      case 0:
        return () => _assetKey.currentState?.submit();
      case 1:
        return () => _subKey.currentState?.submit();
      default:
        return () => _wishKey.currentState?.submit();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tokens（与 add_subscription_screen.dart 一致）
// ═══════════════════════════════════════════════════════════════════════════

class _C {
  _C._();
  static const primary = Color(0xFF3DC88A);
  static const primaryDark = Color(0xFF2BAF74);
  static const primaryLight = Color(0xFF5DDBA0);
  static const bg1 = Color(0xFFEAF6F2);
  static const bg2 = Color(0xFFF0F5FB);
  static const bg3 = Color(0xFFF5EEF8);
  static const card = Color(0xD1FFFFFF); // rgba(255,255,255,0.82)
  static const label = Color(0xFF555555);
  static const text = Color(0xFF1A1A1A);
  static const placeholder = Color(0x801A1A1A); // rgba(26,26,26,0.50)
  static const hint = Color(0xFFBBBBBB);
  static const subtext = Color(0xFF888888);
  static const divider = Color(0xFFCFCECF);
  static const iconGradStart = Color(0xFF4DD49A);
  static const iconGradEnd = Color(0xFF2BAF74);
  static const toggleOff = Color(0xFFD1D1D6);
  static const subText = Color(0xFF999999);
  static const sheetHandle = Color(0xFFE3E8E6);
  static const iconSheetBg = Color(0xFFF2F5F3);
  static const iconSheetSelected = Color(0x2E3DC88A);
  static const error = Color(0xFFE5484D);
}

const _kCardRadius = 15.7;
const _kPillRadius = 22.4;
const _kSectionGap = 17.9;
const _kFieldPadH = 15.7;
const _kFieldPadV = 13.4;

// ═══════════════════════════════════════════════════════════════════════════
// 通用交互包装：桌面悬停变淡 + 点击光标；移动端无感
// ═══════════════════════════════════════════════════════════════════════════

class _PressFx extends StatefulWidget {
  const _PressFx({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressFx> createState() => _PressFxState();
}

class _PressFxState extends State<_PressFx> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: _hovered ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 顶栏：chevron_left 28/#444444 + 「添加」24.6 加粗，padding(22,9,22,13)
// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onConfirm, this.title = '添加'});

  /// 右侧绿色对勾提交按钮的点击回调
  final VoidCallback onConfirm;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 9, 22, 13),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(
              Icons.chevron_left,
              size: 28,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(width: 11),
            Text(
              title,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 24.6,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              height: 1.5,
            ),
          ),
          const Spacer(),
          _ConfirmCheckButton(onTap: onConfirm),
        ],
      ),
    );
  }
}

/// 绿色圆形提交按钮：绿底 + 中间白色对勾
class _ConfirmCheckButton extends StatelessWidget {
  const _ConfirmCheckButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressFx(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_C.primaryLight, _C.primaryDark],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2BAF74).withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.check, size: 24, color: Colors.white),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 切换条：白底圆角 20.2、padding 4.5、Material 图标 14.6、文字 15.7
// ═══════════════════════════════════════════════════════════════════════════

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.labels,
    required this.current,
    required this.onTap,
  });

  final List<String> labels;
  final int current;
  final ValueChanged<int> onTap;

  static const _assetIcon = 'assets/CodeBuddyAssets/42_951/6.svg';

  static const _icons = [
    Icons.inventory_2_outlined,
    Icons.subscriptions_outlined,
    Icons.favorite_border,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17.9),
      child: Container(
        padding: const EdgeInsets.all(4.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.2),
        ),
        child: Row(
          children: List.generate(labels.length, (i) {
            final active = i == current;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? _C.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(15.7),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (i == 0)
                        SvgPicture.asset(
                          _assetIcon,
                          width: 14.6,
                          height: 14.6,
                          colorFilter: ColorFilter.mode(
                            active ? Colors.white : _C.subtext,
                            BlendMode.srcIn,
                          ),
                        )
                      else
                        Icon(
                          _icons[i],
                          size: 14.6,
                          color: active ? Colors.white : _C.subtext,
                        ),
                      const SizedBox(width: 5.6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontFamily: AppFonts.manrope,
                          fontSize: 15.7,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: active ? Colors.white : _C.subtext,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 图标展示区：点击后拍照/选图并 AI 抠图，把结果作为图标
// ═══════════════════════════════════════════════════════════════════════════

class _IconPreview extends StatelessWidget {
  const _IconPreview({
    this.icon,
    this.defaultIcon,
    required this.onTap,
  });

  final String? icon;
  final IconData? defaultIcon;
  final VoidCallback onTap;

  bool get _isPhoto =>
      icon != null &&
      icon!.isNotEmpty &&
      !icon!.endsWith('.svg') &&
      !isEmojiIconPath(icon);

  bool get _isEmoji => isEmojiIconPath(icon);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 26.9, bottom: 17.9),
        child: Column(
          children: [
            _isEmoji
                ? EmojiIconSquare(
                    emoji: emojiFromIconPath(icon)!,
                    size: 89.6,
                  )
                : _isPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(icon!),
                      width: 89.6,
                      height: 89.6,
                      fit: BoxFit.contain,
                      cacheWidth: (89.6 *
                              MediaQuery.of(context).devicePixelRatio)
                          .round(),
                      cacheHeight: (89.6 *
                              MediaQuery.of(context).devicePixelRatio)
                          .round(),
                    ),
                  )
                : Container(
                    width: 89.6,
                    height: 89.6,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_C.iconGradStart, _C.iconGradEnd],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2BAF74).withValues(alpha: 0.35),
                          blurRadius: 26.9,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ItemIcon(
                        iconPath: icon,
                        fallbackIcon: defaultIcon,
                        size: 40,
                      ),
                    ),
                  ),
            const SizedBox(height: 11.2),
            const Text(
              '⇋更换图标',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 13.4,
                color: Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 拍照 / 相册选择行
class _PhotoSourceRow extends StatelessWidget {
  const _PhotoSourceRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FAF8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: _C.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFFC7C7CC),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 共享表单组件（数值以 add_subscription_screen.dart 为准）
// ═══════════════════════════════════════════════════════════════════════════

/// 字段标签：14.6/#555555/行高 1.5；资产/心愿表单可带 16×16 前缀图标
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.icon});

  final String text;
  final String? icon;

  static const _style = TextStyle(
    fontFamily: AppFonts.manrope,
    fontSize: 14.6,
    color: _C.label,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Text(text, style: _style);
    }
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          SizedBox(
            width: 22.6,
            height: 22,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SvgPicture.asset(icon!, width: 16, height: 16),
            ),
          ),
          Text(text, style: _style),
        ],
      ),
    );
  }
}

/// 字段卡片：rgba(255,255,255,0.82) 圆角 15.7
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.child,
    this.height,
    this.hasError = false,
  });

  final Widget child;
  final double? height;

  /// 校验失败时显示红色描边
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(
        horizontal: _kFieldPadH,
        vertical: _kFieldPadV,
      ),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: hasError ? Border.all(color: _C.error, width: 1.1) : null,
      ),
      child: child,
    );
  }
}

/// 文本输入框：16.8 / 提示 rgba(26,26,26,0.50)
class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.hint,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.fontSize = 16.8,
    this.expands = false,
    this.textAlignVertical,
    this.inputFormatters,
    this.onChanged,
  });

  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final double fontSize;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      expands: expands,
      textAlignVertical: textAlignVertical,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: AppFonts.manrope,
        fontSize: fontSize,
        color: _C.text,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.manrope,
          fontSize: fontSize,
          color: _C.placeholder,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

/// 金额输入：¥(#555555) + 数字，间距 4.5
class _MoneyInput extends StatelessWidget {
  const _MoneyInput({this.controller, this.onChanged});

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '¥',
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 16.8,
            color: _C.label,
          ),
        ),
        const SizedBox(width: 4.5),
        Expanded(
          child: _TextInput(
            hint: '0.00',
            controller: controller,
            onChanged: onChanged,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }
}

/// 下拉卡片：点击后弹出 APP 风格的底部选项面板。
class _DropdownCard extends StatelessWidget {
  const _DropdownCard({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppOptionSheet(options: options, selected: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.7),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context),
        child: Container(
          height: 53.7,
          padding: const EdgeInsets.symmetric(
            horizontal: _kFieldPadH,
            vertical: _kFieldPadV,
          ),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(_kCardRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 16.8,
                    color: _C.text,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF999999),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppOptionSheet extends StatelessWidget {
  const _AppOptionSheet({required this.options, required this.selected});

  final List<String> options;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.sheetHandle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == selected;
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _C.iconSheetSelected
                            : const Color(0xFFF7F9F8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontFamily: AppFonts.manrope,
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? _C.primary
                                    : _C.text,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              color: _C.primary,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagEntry extends StatelessWidget {
  const _TagEntry({required this.tags, required this.onTap});

  final List<String> tags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _FieldCard(
        height: 53.7,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            tags.isEmpty ? '添加标签' : tags.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 16.8,
              color: tags.isEmpty ? _C.placeholder : _C.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _TagPickerSheet extends StatefulWidget {
  const _TagPickerSheet({required this.initialSelected});

  final List<String> initialSelected;

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  late final Set<String> _selected = {...widget.initialSelected};

  List<String> get _tags => SettingsStore.instance.tags;

  Future<void> _addTag() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => DialogControllers(
        create: () => [TextEditingController()],
        builder: (ctx, ctrls) {
          final ctrl = ctrls[0];
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              '新增标签',
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _C.text,
              ),
            ),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '标签名称'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  '取消',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    color: _C.subtext,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
                child: const Text(
                  '添加',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontWeight: FontWeight.w700,
                    color: _C.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;
    SettingsStore.instance.addTag(name);
    setState(() => _selected.add(name));
  }

  @override
  Widget build(BuildContext context) {
    final tags = _tags;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.sheetHandle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '选择标签',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _C.text,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  _TagChoice(
                    label: tag,
                    selected: _selected.contains(tag),
                    onTap: () => setState(() {
                      if (!_selected.add(tag)) _selected.remove(tag);
                    }),
                  ),
                GestureDetector(
                  onTap: _addTag,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAF8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _C.divider),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: _C.primary),
                        SizedBox(width: 4),
                        Text(
                          '新增标签',
                          style: TextStyle(
                            fontFamily: AppFonts.manrope,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _C.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () =>
                  Navigator.of(context).pop(_selected.toList()),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_C.primaryLight, _C.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '完成',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChoice extends StatelessWidget {
  const _TagChoice({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _C.primary : const Color(0xFFF4FAF8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _C.primary : _C.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _C.text,
          ),
        ),
      ),
    );
  }
}

/// 日期选择字段：点击弹出系统日期选择器，格式 yyyy-MM-dd
class _DateField extends StatelessWidget {
  const _DateField({
    required this.icon,
    required this.placeholder,
    this.value,
    this.onChanged,
    this.formatter,
    this.fontSize = 16.8,
    this.height,
    this.hasError = false,
  });

  final Widget icon;
  final String placeholder;
  final DateTime? value;
  final ValueChanged<DateTime>? onChanged;

  /// 可选日期格式化函数；默认 yyyy-MM-dd
  final String Function(DateTime)? formatter;
  final double fontSize;

  /// 卡片高度；默认随内容自适应
  final double? height;
  final bool hasError;

  static String _defaultFmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(2000),
    );
    if (picked != null) onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final date = value;
    return Padding(
      padding: const EdgeInsets.only(top: 6.7),
      child: _PressFx(
        onTap: () => _pick(context),
        child: _FieldCard(
          height: height,
          hasError: hasError,
          child: Row(
            children: [
              icon,
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  date != null
                      ? (formatter ?? _defaultFmt)(date)
                      : placeholder,
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: fontSize,
                    color: date != null ? _C.text : _C.hint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 胶囊单选组：单行（订阅类型/扣款周期）或两列宫格（当前状态）
enum _CapsuleLayout { row, grid2 }

class _CapsuleGroup extends StatelessWidget {
  const _CapsuleGroup({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.layout = _CapsuleLayout.row,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final _CapsuleLayout layout;

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case _CapsuleLayout.row:
        return SizedBox(
          height: 41.4,
          child: Row(
            children: List.generate(options.length, (i) {
              return Padding(
                padding: EdgeInsets.only(
                  right: i < options.length - 1 ? 9.0 : 0,
                ),
                child: _Capsule(
                  label: options[i],
                  selected: i == selectedIndex,
                  onTap: () => onChanged(i),
                ),
              );
            }),
          ),
        );
      case _CapsuleLayout.grid2:
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 9.0,
          mainAxisSpacing: 9.0,
          childAspectRatio: 197.6 / 45.9,
          children: List.generate(options.length, (i) {
            return _Capsule(
              label: options[i],
              selected: i == selectedIndex,
              onTap: () => onChanged(i),
              grid: true,
            );
          }),
        );
    }
  }
}

class _Capsule extends StatelessWidget {
  const _Capsule({
    required this.label,
    required this.selected,
    required this.onTap,
    this.grid = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// 宫格模式（当前状态）：文字居中、无内边距
  final bool grid;

  @override
  Widget build(BuildContext context) {
    return _PressFx(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: grid
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 20.2, vertical: 9.0),
        alignment: grid ? Alignment.center : null,
        decoration: BoxDecoration(
          color: selected ? _C.primary : _C.card,
          borderRadius: BorderRadius.circular(grid ? _kCardRadius : _kPillRadius),
          boxShadow: selected
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3.4,
                    offset: const Offset(0, 1.1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 15.7,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : _C.label,
          ),
        ),
      ),
    );
  }
}

/// 重点关注 (Care) 开关行（Figma 42_951 资产表单）
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.15,
      padding: const EdgeInsets.fromLTRB(15.79, 15.79, 15.79, 0),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(15.79),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '重点关注 (Care)',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 16.92,
                    fontWeight: FontWeight.bold,
                    color: _C.text,
                  ),
                ),
                SizedBox(height: 4.26),
                Text(
                  '开启后将在资产卡片中高亮显示',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 13.54,
                    color: _C.subText,
                  ),
                ),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(top: 9.62),
              child: GestureDetector(
                key: const ValueKey('care_switch'),
                onTap: () => onChanged(!value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 49.64,
                height: 29.33,
                padding: const EdgeInsets.all(3.38),
                alignment: value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: value ? _C.primary : _C.toggleOff,
                  borderRadius: BorderRadius.circular(14.67),
                ),
                child: Container(
                  width: 22.57,
                  height: 22.57,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 截图/发票上传框：点击调用系统相册，选中后显示缩略图
class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.attachmentPath,
    required this.onPick,
    required this.onRemove,
  });

  final String? attachmentPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _PressFx(
      onTap: onPick,
      child: Container(
        width: 73.9,
        height: 73.9,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.6),
          border: Border.all(color: _C.divider, width: 1.1),
        ),
        child: attachmentPath == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 26,
                    color: _C.divider,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '上传',
                    style: TextStyle(
                      fontFamily: AppFonts.manrope,
                      fontSize: 11.2,
                      fontWeight: FontWeight.bold,
                      color: _C.divider,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13.5),
                    child: Image.file(
                      File(attachmentPath!),
                      fit: BoxFit.cover,
                      cacheWidth: (360 *
                              MediaQuery.of(context).devicePixelRatio)
                          .round(),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0x99000000),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 两列字段行
class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 11.2),
        Expanded(child: right),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 表单 · 添加资产（Figma 42_951）
// ═══════════════════════════════════════════════════════════════════════════

  class _AssetForm extends StatefulWidget {
    const _AssetForm({super.key, this.icon, this.editing});

    /// 所选图标资源；null 表示默认资产图标
    final String? icon;

    final Asset? editing;

  @override
  State<_AssetForm> createState() => _AssetFormState();
}

  class _AssetFormState extends State<_AssetForm> {
    static const _f = 'assets/CodeBuddyAssets/42_951';

    late final _nameCtrl =
        TextEditingController(text: widget.editing?.name ?? '');
    late final _priceCtrl = TextEditingController(
      text: widget.editing?.purchasePrice.toStringAsFixed(2) ?? '',
    );
    late final _customCategoryCtrl = TextEditingController(
      text: widget.editing != null &&
              !SettingsStore.instance.categories.contains(widget.editing!.category)
          ? widget.editing!.category
          : '',
    );
    late final _noteCtrl =
        TextEditingController(text: widget.editing?.remark ?? '');

    late DateTime? _purchaseDate =
        widget.editing?.purchaseDate ?? DateTime.now();
    late String _category = widget.editing == null
        ? (SettingsStore.instance.categories.firstOrNull ?? '其他')
        : SettingsStore.instance.categories.contains(widget.editing!.category)
            ? widget.editing!.category
            : '自定义';
    late bool _isCustomCategory = widget.editing != null &&
        !SettingsStore.instance.categories.contains(widget.editing!.category);
    late String? _attachmentPath = widget.editing?.attachmentPath;
    late List<String> _selectedTags = [...?widget.editing?.tags];
    late bool _careEnabled = widget.editing?.careExpiryDate != null;
    late DateTime? _careExpiryDate = widget.editing?.careExpiryDate;
    late int _statusIndex = widget.editing == null
        ? 0
        : AssetLifecycleStatus.values.indexOf(widget.editing!.status).clamp(0, 2);

    bool _nameError = false;
    bool _priceError = false;
    bool _dateError = false;
    bool _customCategoryError = false;

    @override
    void dispose() {
      _nameCtrl.dispose();
      _priceCtrl.dispose();
      _customCategoryCtrl.dispose();
      _noteCtrl.dispose();
      super.dispose();
    }

    void _showError(String message) {
      showTopSnackBar(context, message);
    }

    Future<void> _pickUpload() async {
      final path = await UploadService.pickImage();
      if (path != null && mounted) {
        setState(() => _attachmentPath = path);
      }
    }

    Future<void> _openTags() async {
      final result = await showModalBottomSheet<List<String>>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _TagPickerSheet(initialSelected: _selectedTags),
      );
      if (result != null && mounted) {
        setState(() => _selectedTags = result);
      }
    }

    void submit() {
      final name = _nameCtrl.text.trim();
      final priceText = _priceCtrl.text.trim();
      final price = double.tryParse(priceText);
      final category = _isCustomCategory
          ? _customCategoryCtrl.text.trim()
          : _category;

      setState(() {
        _nameError = name.isEmpty;
        _priceError = priceText.isNotEmpty && (price == null || price < 0);
        _dateError = _purchaseDate == null;
        _customCategoryError = _isCustomCategory && category.isEmpty;
      });

      if (_nameError) {
        _showError('请输入资产名称');
        return;
      }
      if (_priceError) {
        _showError('请输入正确的购买价格');
        return;
      }
      if (_dateError) {
        _showError('请选择购买日期');
        return;
      }
      if (_customCategoryError) {
        _showError('请输入自定义分类');
        return;
      }
      if (_isCustomCategory && !SettingsStore.instance.categories.contains(category)) {
        SettingsStore.instance.addCategory(category);
      }

      final editing = widget.editing;
      final status = AssetLifecycleStatus.values[_statusIndex];
      final asset = Asset(
        id: editing?.id ?? 'a${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        category: category,
        currency: editing?.currency ?? SettingsStore.instance.currency,
        purchasePrice: priceText.isEmpty ? 0 : price!,
        purchaseDate: _purchaseDate!,
        status: status,
        retiredDate: status == AssetLifecycleStatus.retired
            ? (editing?.retiredDate ?? DateTime.now())
            : null,
        careExpiryDate: _careEnabled ? _careExpiryDate : null,
        targetCpd: editing?.targetCpd,
        remark: _noteCtrl.text.trim(),
        icon: widget.icon,
        attachmentPath: _attachmentPath,
        tags: _selectedTags,
        createdAt: editing?.createdAt ?? DateTime.now(),
        saleRecords: editing?.saleRecords ?? const [],
      );

      if (editing != null) {
        AssetStore.instance.update(asset);
      } else {
        AssetStore.instance.add(asset);
      }
      final messenger = ScaffoldMessenger.of(context);
      final screenHeight = MediaQuery.sizeOf(context).height;
      final screenWidth = MediaQuery.sizeOf(context).width;
      Navigator.of(context).maybePop();
      // 先返回再提示：避免 SnackBar Hero 在路由转场中与旧页面重复导致冲突
      Future.delayed(const Duration(milliseconds: 350), () {
        messenger.showSnackBar(
          buildTopSnackBar(
            editing != null ? '已更新资产「$name」' : '已添加资产「$name」',
            screenHeight,
            screenWidth: screenWidth,
          ),
        );
      });
    }

    static String _cnDate(DateTime d) => '${d.year}年${d.month}月${d.day}日';

    @override
    Widget build(BuildContext context) {
      return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldLabel('资产名称', icon: '$_f/7.svg'),
            const SizedBox(height: 6.7),
            _FieldCard(
              height: 53.7,
              hasError: _nameError,
              child: _TextInput(
                hint: '如：iPhone 15 Pro',
                controller: _nameCtrl,
                onChanged: (_) => setState(() => _nameError = false),
              ),
            ),
            const SizedBox(height: _kSectionGap),

            _FieldLabel('购买价格', icon: '$_f/8.svg'),
            const SizedBox(height: 6.7),
            _FieldCard(
              hasError: _priceError,
              child: _MoneyInput(
                controller: _priceCtrl,
                onChanged: (_) => setState(() => _priceError = false),
              ),
            ),
            const SizedBox(height: _kSectionGap),

            _TwoColumns(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FieldLabel('购买日期', icon: '$_f/9.svg'),
                  _DateField(
                    icon: SvgPicture.asset('$_f/10.svg',
                        width: 16, height: 16),
                    placeholder: '2026年8月17日',
                    fontSize: 13.54,
                    height: 53.7,
                    formatter: _cnDate,
                    value: _purchaseDate,
                    hasError: _dateError,
                    onChanged: (d) => setState(() {
                      _purchaseDate = d;
                      _dateError = false;
                    }),
                  ),
                ],
              ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  _FieldLabel('分类', icon: '$_f/11.svg'),
                  Builder(builder: (context) {
                    final baseOptions = SettingsStore.instance.categories;
                    final safeOptions = [
                      ...baseOptions,
                      if (!baseOptions.contains('自定义')) '自定义',
                    ];
                    final value = _isCustomCategory
                        ? '自定义'
                        : safeOptions.contains(_category)
                            ? _category
                            : safeOptions.first;
                    return _DropdownCard(
                      value: value,
                      options: safeOptions,
                      onChanged: (v) => setState(() {
                        if (v == '自定义') {
                          _isCustomCategory = true;
                        } else {
                          _isCustomCategory = false;
                          _category = v;
                        }
                        _customCategoryError = false;
                      }),
                    );
                  }),
                ],
              ),
          ),
          if (_isCustomCategory) ...[
            const SizedBox(height: _kSectionGap),
            const _FieldLabel('自定义'),
            const SizedBox(height: 6.7),
            _FieldCard(
              hasError: _customCategoryError,
              child: _TextInput(
                hint: '请输入分类名称',
                controller: _customCategoryCtrl,
                onChanged: (_) =>
                    setState(() => _customCategoryError = false),
              ),
            ),
          ],
          const SizedBox(height: _kSectionGap),

          _ToggleRow(
            value: _careEnabled,
            onChanged: (v) => setState(() => _careEnabled = v),
          ),
          if (_careEnabled) ...[
            const SizedBox(height: _kSectionGap),
            _FieldLabel('Care到期时间', icon: '$_f/16.svg'),
            const SizedBox(height: 7.21),
              _DateField(
                icon: SvgPicture.asset('$_f/15.svg', width: 16, height: 16),
                placeholder: '选择到期日期',
                height: 53.7,
                formatter: _cnDate,
                value: _careExpiryDate,
                onChanged: (d) =>
                    setState(() => _careExpiryDate = d),
              ),
            ],
          const SizedBox(height: _kSectionGap),

          _FieldLabel('当前状态', icon: '$_f/17.svg'),
          const SizedBox(height: 6.7),
          _CapsuleGroup(
            options: const ['服役中', '已退役', '已卖出'],
            selectedIndex: _statusIndex,
            onChanged: (i) => setState(() => _statusIndex = i),
          ),
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('标签'),
          const SizedBox(height: 6.7),
          _TagEntry(
            tags: _selectedTags,
            onTap: _openTags,
          ),
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('备注'),
          _FieldCard(
            height: 104.9,
            child: _TextInput(
              hint: '添加文字、数字提示或各类备注信息...',
              controller: _noteCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              fontSize: 15.7,
            ),
          ),
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('上传图片'),
          const SizedBox(height: 6.7),
          _UploadBox(
            attachmentPath: _attachmentPath,
            onPick: _pickUpload,
            onRemove: () => setState(() => _attachmentPath = null),
          ),
          const SizedBox(height: 4.5),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 表单 · 添加订阅（add_subscription_screen.dart）
// ═══════════════════════════════════════════════════════════════════════════

  class _SubscriptionForm extends StatefulWidget {
    const _SubscriptionForm({
      super.key,
      required this.icon,
      this.editing,
    });

    /// 所选图标资源；null 表示默认日历图标
    final String? icon;

    /// 编辑模式：非 null 时回填表单，保存走更新
    final Subscription? editing;

    @override
    State<_SubscriptionForm> createState() => _SubscriptionFormState();
  }

class _SubscriptionFormState extends State<_SubscriptionForm> {
  static const _types = ['自动续费', '买断', '一次性'];
  static const _cycles = ['包月', '包季', '包年', '无'];
  static const _statuses = ['生效中', '已过期', '已取消', '暂停中'];
  static const _platforms = [
    '苹果',
    'Google Play',
    '支付宝',
    '微信支付',
    '华为应用市场',
    '小米应用商店',
    'Steam',
    '微软',
    'Adobe',
    '哔哩哔哩',
    '爱奇艺',
    '自定义',
  ];
  static const _currencies = [
    'CNY',
    'USD',
    'EUR',
    'JPY',
    'HKD',
    'GBP',
    '自定义',
  ];

    late final _nameCtrl =
        TextEditingController(text: widget.editing?.name ?? '');
    late final _amountCtrl = TextEditingController(
      text: widget.editing == null
          ? ''
          : (widget.editing!.amount == widget.editing!.amount.roundToDouble()
              ? widget.editing!.amount.toStringAsFixed(0)
              : widget.editing!.amount.toString()),
    );
    late final _noteCtrl =
        TextEditingController(text: widget.editing?.remark ?? '');

    late final _customPlatformCtrl = TextEditingController(
      text: widget.editing != null &&
              !_platforms.contains(widget.editing!.platform)
          ? widget.editing!.platform
          : '',
    );
    late final _customCurrencyCtrl = TextEditingController(
      text: widget.editing != null &&
              !_currencies.contains(widget.editing!.currency)
          ? widget.editing!.currency
          : '',
    );

    late String _platform = widget.editing == null
        ? '苹果'
        : _platforms.contains(widget.editing!.platform)
            ? widget.editing!.platform
            : '自定义';
    late String _currency = widget.editing == null
        ? 'CNY'
        : _currencies.contains(widget.editing!.currency)
            ? widget.editing!.currency
            : '自定义';
    late int _typeIndex =
        _types.indexOf(widget.editing?.type ?? '自动续费').clamp(0, 2);
    late int _cycleIndex =
        _cycles.indexOf(widget.editing?.cycle ?? '包月').clamp(0, 3);
    late int _statusIndex = _statuses
        .indexOf(widget.editing?.status ?? '生效中')
        .clamp(0, 3);
    late DateTime? _startDate = widget.editing?.firstDate;
    late DateTime? _endDate = widget.editing?.expiryDate;
    late DateTime? _nextDate = widget.editing?.nextChargeDate;
    late String? _attachmentPath = widget.editing?.attachmentPath;

  bool _nameError = false;
  bool _amountError = false;
  bool _dateError = false;
  bool _customPlatformError = false;
  bool _customCurrencyError = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _customPlatformCtrl.dispose();
    _customCurrencyCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    showTopSnackBar(context, message);
  }

  Future<void> _pickUpload() async {
    final path = await UploadService.pickImage();
    if (path != null && mounted) {
      setState(() => _attachmentPath = path);
    }
  }

  void submit() {
    final name = _nameCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    final amount = double.tryParse(amountText);
    final platform = _platform == '自定义'
        ? _customPlatformCtrl.text.trim()
        : _platform;
    final currency =
        _currency == '自定义' ? _customCurrencyCtrl.text.trim() : _currency;

    setState(() {
      _nameError = name.isEmpty;
      _amountError = amount == null || amount < 0;
      _dateError = _startDate == null || _endDate == null;
      _customPlatformError = _platform == '自定义' && platform.isEmpty;
      _customCurrencyError = _currency == '自定义' && currency.isEmpty;
    });

    if (_nameError) {
      _showError('请输入 APP / 服务名称');
      return;
    }
    if (_amountError) {
      _showError('请输入正确的订阅金额');
      return;
    }
    if (_dateError) {
      _showError('请选择首次订阅时间和当前周期到期时间');
      return;
    }
    if (_customPlatformError) {
      _showError('请输入自定义订阅平台');
      return;
    }
    if (_customCurrencyError) {
      _showError('请输入自定义币种');
      return;
    }

      final editing = widget.editing;
      final subscription = Subscription(
        id: editing?.id ?? 's${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        platform: platform,
      type: _types[_typeIndex],
      amount: amount!,
      currency: currency,
      cycle: _cycles[_cycleIndex],
      firstDate: _startDate,
      expiryDate: _endDate,
      nextChargeDate: _nextDate,
      status: _statuses[_statusIndex],
      remark: _noteCtrl.text.trim(),
      icon: widget.icon,
      attachmentPath: _attachmentPath,
      createdAt: DateTime.now(),
    );

      if (editing != null) {
        SubscriptionStore.instance.update(subscription);
      } else {
        SubscriptionStore.instance.add(subscription);
      }
      final messenger = ScaffoldMessenger.of(context);
      final screenHeight = MediaQuery.sizeOf(context).height;
      final screenWidth = MediaQuery.sizeOf(context).width;
      Navigator.of(context).maybePop();
      // 先返回再提示：避免 SnackBar Hero 在路由转场中冲突
      Future.delayed(const Duration(milliseconds: 350), () {
        messenger.showSnackBar(
          buildTopSnackBar(
            editing != null ? '已更新订阅「$name」' : '已添加订阅「$name」',
            screenHeight,
            screenWidth: screenWidth,
          ),
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    final calendarIcon = const Icon(
      Icons.calendar_today_outlined,
      size: 16.8,
      color: _C.primary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('APP / 服务名称'),
          const SizedBox(height: 6.7),
          _FieldCard(
            height: 53.7,
            hasError: _nameError,
            child: _TextInput(
              hint: '如：iCloud+ / Notion / Spotify',
              controller: _nameCtrl,
              onChanged: (_) => setState(() => _nameError = false),
            ),
          ),
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('订阅平台'),
          _DropdownCard(
            value: _platform,
            options: _platforms,
            onChanged: (v) => setState(() => _platform = v),
          ),
          if (_platform == '自定义') ...[
            const SizedBox(height: _kSectionGap),
            const _FieldLabel('自定义'),
            const SizedBox(height: 6.7),
            _FieldCard(
              hasError: _customPlatformError,
              child: _TextInput(
                hint: '请输入订阅平台',
                controller: _customPlatformCtrl,
                onChanged: (_) =>
                    setState(() => _customPlatformError = false),
              ),
            ),
          ],
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('订阅类型'),
          const SizedBox(height: 6.7),
          _CapsuleGroup(
            options: _types,
            selectedIndex: _typeIndex,
            onChanged: (i) => setState(() => _typeIndex = i),
          ),
          const SizedBox(height: _kSectionGap),

          _TwoColumns(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                    const _FieldLabel('订阅金额'),
                    const SizedBox(height: 6.7),
                    _FieldCard(
                      height: 53.7,
                      hasError: _amountError,
                      child: _MoneyInput(
                    controller: _amountCtrl,
                    onChanged: (_) => setState(() => _amountError = false),
                  ),
                ),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FieldLabel('币种'),
                _DropdownCard(
                  value: _currency,
                  options: _currencies,
                  onChanged: (v) => setState(() => _currency = v),
                ),
                if (_currency == '自定义') ...[
                  const SizedBox(height: 8),
                  const _FieldLabel('自定义'),
                  const SizedBox(height: 6.7),
                  _FieldCard(
                    hasError: _customCurrencyError,
                    child: _TextInput(
                      hint: '请输入币种',
                      controller: _customCurrencyCtrl,
                      onChanged: (_) =>
                          setState(() => _customCurrencyError = false),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('扣款周期'),
          const SizedBox(height: 6.7),
          _CapsuleGroup(
            options: _cycles,
            selectedIndex: _cycleIndex,
            onChanged: (i) => setState(() => _cycleIndex = i),
          ),
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('首次订阅时间'),
          _DateField(
            icon: calendarIcon,
            placeholder: '选择日期',
            height: 53.7,
            value: _startDate,
            onChanged: (d) => setState(() {
              _startDate = d;
              _dateError = false;
            }),
            hasError: _dateError && _startDate == null,
          ),
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('当前周期到期时间'),
          _DateField(
            icon: calendarIcon,
            placeholder: '选择到期日期',
            height: 53.7,
            value: _endDate,
            onChanged: (d) => setState(() {
              _endDate = d;
              _dateError = false;
            }),
            hasError: _dateError && _endDate == null,
          ),
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('下次自动扣款时间'),
          _DateField(
            icon: calendarIcon,
            placeholder: '选择到期日期',
            height: 53.7,
            value: _nextDate,
            onChanged: (d) => setState(() => _nextDate = d),
          ),
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('当前状态'),
          const SizedBox(height: 6.7),
          _CapsuleGroup(
            options: _statuses,
            selectedIndex: _statusIndex,
            onChanged: (i) => setState(() => _statusIndex = i),
            layout: _CapsuleLayout.grid2,
          ),
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('备注'),
          _FieldCard(
            height: 104.9,
            child: _TextInput(
              hint: '添加文字、数字提示或各类备注信息...',
              controller: _noteCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              fontSize: 15.7,
            ),
          ),
          const SizedBox(height: _kSectionGap),

          const _FieldLabel('截图 / 发票'),
          const SizedBox(height: 6.7),
          _UploadBox(
            attachmentPath: _attachmentPath,
            onPick: _pickUpload,
            onRemove: () => setState(() => _attachmentPath = null),
          ),
          const SizedBox(height: 4.5),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 表单 · 添加心愿（Figma 43_1372）
// ═══════════════════════════════════════════════════════════════════════════

  class _WishForm extends StatefulWidget {
    const _WishForm({super.key, required this.icon});

    final String icon;

    @override
    State<_WishForm> createState() => _WishFormState();
  }

  class _WishFormState extends State<_WishForm> {
    static const _f = 'assets/CodeBuddyAssets/43_1372';

    final _nameCtrl = TextEditingController();
    final _targetCtrl = TextEditingController();
    final _customCategoryCtrl = TextEditingController();

    DateTime? _addDate = DateTime.now();
    String _category =
        SettingsStore.instance.categories.firstOrNull ?? '其他';
    bool _isCustomCategory = false;

    bool _nameError = false;
    bool _targetError = false;
    bool _dateError = false;
    bool _customCategoryError = false;

    @override
    void dispose() {
      _nameCtrl.dispose();
      _targetCtrl.dispose();
      _customCategoryCtrl.dispose();
      super.dispose();
    }

    void _showError(String message) {
      showTopSnackBar(context, message);
    }

    void submit() {
      final name = _nameCtrl.text.trim();
      final targetText = _targetCtrl.text.trim();
      final target = double.tryParse(targetText);
      final category = _isCustomCategory
          ? _customCategoryCtrl.text.trim()
          : _category;

      setState(() {
        _nameError = name.isEmpty;
        _targetError = target == null || target <= 0;
        _dateError = _addDate == null;
        _customCategoryError = _isCustomCategory && category.isEmpty;
      });

      if (_nameError) {
        _showError('请输入心愿名称');
        return;
      }
      if (_targetError) {
        _showError('请输入正确的目标金额');
        return;
      }
      if (_dateError) {
        _showError('请选择添加日期');
        return;
      }
      if (_customCategoryError) {
        _showError('请输入自定义分类');
        return;
      }
      if (_isCustomCategory && !SettingsStore.instance.categories.contains(category)) {
        SettingsStore.instance.addCategory(category);
      }

      final item = WishlistItem(
        id: 'w${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        category: category,
        targetAmount: target!,
        savedAmount: 0,
        addDate: _addDate!,
        completed: false,
        icon: widget.icon,
        createdAt: DateTime.now(),
      );

      WishlistStore.instance.add(item);
      final messenger = ScaffoldMessenger.of(context);
      final screenHeight = MediaQuery.sizeOf(context).height;
      final screenWidth = MediaQuery.sizeOf(context).width;
      Navigator.of(context).maybePop();
      // 先返回再提示：避免 SnackBar Hero 在路由转场中冲突
      Future.delayed(const Duration(milliseconds: 350), () {
        messenger.showSnackBar(
          buildTopSnackBar(
            '已添加心愿「$name」',
            screenHeight,
            screenWidth: screenWidth,
          ),
        );
      });
    }

    static String _cnDate(DateTime d) => '${d.year}年${d.month}月${d.day}日';

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17.9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldLabel('心愿名称', icon: '$_f/6.svg'),
            const SizedBox(height: 6.7),
            _FieldCard(
              height: 53.7,
              hasError: _nameError,
              child: _TextInput(
                hint: '如：新款 MacBook Pro',
                controller: _nameCtrl,
                onChanged: (_) => setState(() => _nameError = false),
              ),
            ),
            const SizedBox(height: _kSectionGap),

            _FieldLabel('目标金额', icon: '$_f/7.svg'),
            const SizedBox(height: 6.7),
            _FieldCard(
              hasError: _targetError,
              child: _MoneyInput(
                controller: _targetCtrl,
                onChanged: (_) => setState(() => _targetError = false),
              ),
            ),
            const SizedBox(height: _kSectionGap),

            _TwoColumns(
              left: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FieldLabel('添加日期', icon: '$_f/8.svg'),
                  _DateField(
                    icon: SvgPicture.asset('$_f/9.svg',
                        width: 16, height: 16),
                    placeholder: '2026年8月17日',
                    fontSize: 13.54,
                    height: 53.7,
                    formatter: _cnDate,
                    value: _addDate,
                    hasError: _dateError,
                    onChanged: (d) => setState(() {
                      _addDate = d;
                      _dateError = false;
                    }),
                  ),
                ],
              ),
              right: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FieldLabel('分类', icon: '$_f/10.svg'),
                  Builder(builder: (context) {
                    final baseOptions = SettingsStore.instance.categories;
                    final safeOptions = [
                      ...baseOptions,
                      if (!baseOptions.contains('自定义')) '自定义',
                    ];
                    final value = _isCustomCategory
                        ? '自定义'
                        : safeOptions.contains(_category)
                            ? _category
                            : safeOptions.first;
                    return _DropdownCard(
                      value: value,
                      options: safeOptions,
                      onChanged: (v) => setState(() {
                        if (v == '自定义') {
                          _isCustomCategory = true;
                        } else {
                          _isCustomCategory = false;
                          _category = v;
                        }
                        _customCategoryError = false;
                      }),
                    );
                  }),
                ],
              ),
            ),
            if (_isCustomCategory) ...[
              const SizedBox(height: _kSectionGap),
              const _FieldLabel('自定义'),
              const SizedBox(height: 6.7),
              _FieldCard(
                hasError: _customCategoryError,
                child: _TextInput(
                  hint: '请输入分类名称',
                  controller: _customCategoryCtrl,
                  onChanged: (_) =>
                      setState(() => _customCategoryError = false),
                ),
              ),
            ],
            const SizedBox(height: 4.5),
          ],
        ),
      );
    }
  }

/// 输入 emoji 的弹窗：自己持有输入框控制器，随弹窗销毁时释放，
/// 避免在关闭动画期间销毁控制器触发框架断言。
class _EmojiInputDialog extends StatefulWidget {
  const _EmojiInputDialog();

  @override
  State<_EmojiInputDialog> createState() => _EmojiInputDialogState();
}

class _EmojiInputDialogState extends State<_EmojiInputDialog> {
  final _controller = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    final length = text.characters.length;
    if (text.isEmpty) {
      setState(() => _error = '请输入一个 emoji');
      return;
    }
    if (length != 1) {
      setState(() => _error = '只能输入一个 emoji');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '输入 emoji',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.manrope,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        inputFormatters: const [_EmojiOnlyInputFormatter()],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, height: 1.2),
        onChanged: (_) {
          if (_error.isNotEmpty) setState(() => _error = '');
        },
        decoration: InputDecoration(
          hintText: '例如 📱',
          hintStyle: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 20,
            color: AppColors.textHint,
          ),
          errorText: _error.isEmpty ? null : _error,
          errorStyle: const TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE3E8E6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF3DC88A),
              width: 1.5,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              color: AppColors.textHint,
            ),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(
            '确定',
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontWeight: FontWeight.w800,
              color: _C.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 只允许 emoji 字符输入：文字、数字等其他内容一律在输入框内不显示。
class _EmojiOnlyInputFormatter extends TextInputFormatter {
  const _EmojiOnlyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final filtered = newValue.text.characters
        .where(_isEmojiCluster)
        .join();
    if (filtered == newValue.text) return newValue;
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(
        offset: filtered.characters.length,
      ),
    );
  }
}

bool _isEmojiCluster(String cluster) {
  final runes = cluster.runes.toList();
  return runes.isNotEmpty && runes.any(_isEmojiCodePoint);
}

bool _isEmojiCodePoint(int r) {
  return (r >= 0x1F000 && r <= 0x1FAFF) || // Emoji 主要区块（含手机 📱）
      (r >= 0x1F1E6 && r <= 0x1F1FF) || // 区域指示符（旗帜）
      (r >= 0x2600 && r <= 0x27BF) || // 杂项符号与装饰符号
      (r >= 0x2B00 && r <= 0x2BFF) || // 杂项符号与箭头
      (r >= 0x2190 && r <= 0x21FF) || // 箭头
      (r >= 0x1F3FB && r <= 0x1F3FF) || // 肤色修饰符
      r == 0xFE0F || // 变体选择符
      r == 0x200D || // 零宽连接符（组合 emoji）
      r == 0x20E3; // 组合围键帽（数字键帽表情）
}
