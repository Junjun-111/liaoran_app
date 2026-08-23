import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../services/ai_matting_service.dart';
import '../services/aliyun_client.dart';
import '../theme/app_theme.dart';
import '../widgets/top_snackbar.dart';

/// 图标调整页：选完照片后进入。
///
/// - AI 自动抠图 → 自动裁掉透明边缘 → 居中放入显示区；
/// - 显示区支持单指拖动、双指缩放（InteractiveViewer），图片停在哪就在哪；
/// - 底部工具：框选（四角端点可拉伸、中间可拖动移动）、缩放滑杆；
/// - “使用原图”：回到用户第一次选的原始照片；
/// - “再次抠图”：框选后不会自动二次抠图，需要时点“再次抠图”；
/// - “使用原图 / 重新抠图”：底部按钮在原始照片与 AI 抠图之间切换；
/// - 保存 = 所见即所得：显示区里露出的部分原样保存。
class IconMattingEditorPage extends StatefulWidget {
  const IconMattingEditorPage({super.key, required this.sourcePath});

  final String sourcePath;

  @override
  State<IconMattingEditorPage> createState() => _IconMattingEditorPageState();
}

class _IconMattingEditorPageState extends State<IconMattingEditorPage> {
  final TransformationController _tc = TransformationController();

  String? _originalPath;
  Uint8List? _displayBytes;
  img.Image? _image;
  bool _usingOriginal = false;

  bool _loading = true;
  String? _error;

  double _sliderValue = 1;

  bool _cropMode = false;
  bool _zoomTool = false;
  Rect? _cropRect;
  Offset? _cropStart;
  int? _dragHandle;
  bool _dragMove = false;
  Offset? _dragStart;
  Rect? _dragStartRect;

  Size _frameSize = const Size(300, 300);

  @override
  void initState() {
    super.initState();
    _originalPath = widget.sourcePath;
    _runInitialMatte();
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  // ── 抠图 ────────────────────────────────────────────────

  Future<void> _runInitialMatte() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final path = await AiMattingService.matte(sourcePath: _originalPath!);
      await _loadMatted(path);
    } on AiMattingException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('网络异常，抠图失败');
    }
  }

  Future<void> _loadMatted(String path) async {
    final bytes = await File(path).readAsBytes();
    final (trimmed, trimmedPng) = await compute(_decodeTrimEncodeSync, bytes);
    final saved = await AiMattingService.savePng(
      trimmedPng,
      prefix: 'icon_final',
    );
    await _showImage(saved, trimmedPng, trimmed);
  }

  /// 展示一张图片并保存为当前图标；切换图片时视图回到居中适配。
  Future<void> _showImage(
    String path,
    Uint8List bytes,
    img.Image decoded, {
    bool resetTransform = true,
  }) async {
    if (!mounted) return;
    if (resetTransform) _tc.value = Matrix4.identity();
    setState(() {
      _displayBytes = bytes;
      _image = decoded;
      _usingOriginal = false;
      _cropMode = false;
      _zoomTool = false;
      _cropRect = null;
      _cropStart = null;
      _dragHandle = null;
      _dragMove = false;
      _loading = false;
    });
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  void _snack(String message) {
    showTopSnackBar(context, message);
  }

  // ── 使用原图 / 重新抠图 ─────────────────────────────────

  Future<void> _useOriginal() async {
    final src = _originalPath;
    if (src == null || _loading) return;
    setState(() {
      _loading = true;
      _cropMode = false;
      _zoomTool = false;
      _cropRect = null;
    });
    try {
      final bytes = await File(src).readAsBytes();
      final (decoded, png) = await compute(_decodeEncodeSync, bytes);
      final saved = await AiMattingService.savePng(
        png,
        prefix: 'icon_original',
      );
      await _showImage(saved, png, decoded);
      if (mounted) {
        setState(() => _usingOriginal = true);
      }
    } on AiMattingException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('原图读取失败');
      }
    }
  }

  Future<void> _redoMatte() async {
    if (_usingOriginal) {
      await _runInitialMatte();
    }
  }

  // ── 框选裁剪 ────────────────────────────────────────────

  void _enterCropMode() {
    setState(() {
      _cropMode = true;
      _zoomTool = false;
      _cropRect = null;
      _cropStart = null;
      _dragHandle = null;
      _dragMove = false;
    });
  }

  void _exitCropMode() {
    setState(() {
      _cropMode = false;
      _cropRect = null;
      _cropStart = null;
      _dragHandle = null;
      _dragMove = false;
    });
  }

  Future<void> _applyCrop() async {
    final rect = _cropRect;
    final image = _image;
    if (rect == null || image == null) return;

    final tl = _screenToImage(rect.topLeft);
    final br = _screenToImage(rect.bottomRight);
    var ix = tl.dx.round();
    var iy = tl.dy.round();
    var iw = br.dx.round() - ix;
    var ih = br.dy.round() - iy;
    ix = ix.clamp(0, image.width - 1);
    iy = iy.clamp(0, image.height - 1);
    iw = (ix + iw).clamp(0, image.width) - ix;
    ih = (iy + ih).clamp(0, image.height) - iy;
    if (iw < 8 || ih < 8) {
      _snack('框选区域太小，请重新框选');
      return;
    }

    setState(() {
      _loading = true;
      _cropMode = false;
      _cropRect = null;
      _cropStart = null;
      _dragHandle = null;
      _dragMove = false;
    });
    try {
      final (cropped, png) =
          await compute(_cropEncodeSync, (image, ix, iy, iw, ih));
      // 框选什么样就是什么样：直接保存选区内容，不再自动二次抠图
      final saved = await AiMattingService.savePng(
        png,
        prefix: 'icon_crop',
      );
      await _showImage(saved, png, cropped);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('裁剪失败，请重试');
      }
    }
  }

  /// “再次抠图”：对当前图片（框选后的结果）重新跑一次 AI 抠图。
  Future<void> _rematteCurrent() async {
    final image = _image;
    if (image == null || _loading) return;
    setState(() {
      _loading = true;
      _cropMode = false;
      _zoomTool = false;
      _cropRect = null;
    });
    try {
      final jpg = await compute(_compositeJpgSync, image);
      final path = await AiMattingService.matteBytes(jpg);
      await _loadMatted(path);
    } on AiMattingException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('抠图失败，请重试');
      }
    }
  }

  /// 将当前图片顺时针旋转 90°（可无限次点击，累计旋转）。
  Future<void> _rotate90() async {
    final image = _image;
    if (image == null || _loading) return;
    setState(() => _loading = true);
    try {
      final (rotated, png) = await compute(_rotate90Sync, image);
      final saved = await AiMattingService.savePng(png, prefix: 'icon_rotated');
      await _showImage(saved, png, rotated);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('旋转失败，请重试');
      }
    }
  }

  // ── 图片显示辅助 ────────────────────────────────────────

  Size _baseSize() {
    final image = _image;
    final fw = _frameSize.width;
    final fh = _frameSize.height;
    if (image == null || image.width <= 0 || image.height <= 0) {
      return Size(fw, fh);
    }
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final scale = (fw / iw) < (fh / ih) ? fw / iw : fh / ih;
    return Size(iw * scale, ih * scale);
  }

  /// 最小缩放：保证图片显示尺寸不小于 30×30。
  double get _minScale {
    final base = _baseSize();
    if (base.width <= 0 || base.height <= 0) return 0.1;
    return math
        .max(30 / base.width, 30 / base.height)
        .clamp(0.05, 1.0)
        .toDouble();
  }

  /// 屏幕坐标 → 图片像素坐标（考虑 InteractiveViewer 的缩放与位移）。
  Offset _screenToImage(Offset p) {
    final image = _image;
    if (image == null) return Offset.zero;
    final inv = _tc.value.clone()..invert();
    final local = MatrixUtils.transformPoint(inv, p);
    final base = _baseSize();
    final imgLeft = (_frameSize.width - base.width) / 2;
    final imgTop = (_frameSize.height - base.height) / 2;
    final x = (local.dx - imgLeft).clamp(0.0, base.width);
    final y = (local.dy - imgTop).clamp(0.0, base.height);
    return Offset(
      base.width <= 0 ? 0 : x / base.width * image.width,
      base.height <= 0 ? 0 : y / base.height * image.height,
    );
  }

  // ── 框选交互：新建 / 移动 / 拉伸四角端点 ─────────────────

  int? _hitHandle(Offset p) {
    final r = _cropRect;
    if (r == null) return null;
    const hit = 28.0;
    final positions = _handlePositions(r);
    for (var i = 0; i < positions.length; i++) {
      if ((p - positions[i]).distance <= hit) return i;
    }
    return null;
  }

  /// 8 个手柄：4 角 + 4 边中点。
  List<Offset> _handlePositions(Rect r) => [
        r.topLeft,
        r.topRight,
        r.bottomLeft,
        r.bottomRight,
        Offset(r.center.dx, r.top), // 4: 上边中点
        Offset(r.right, r.center.dy), // 5: 右边中点
        Offset(r.center.dx, r.bottom), // 6: 下边中点
        Offset(r.left, r.center.dy), // 7: 左边中点
      ];

  void _cropPanStart(Offset p) {
    final r = _cropRect;
    setState(() {
      final handle = r == null ? null : _hitHandle(p);
      if (handle != null) {
        _cropStart = null;
        _dragHandle = handle;
        _dragMove = false;
        _dragStart = p;
        _dragStartRect = r;
      } else if (r != null && r.contains(p)) {
        // 点在选区中间：拖动 = 移动选区
        _cropStart = null;
        _dragHandle = null;
        _dragMove = true;
        _dragStart = p;
        _dragStartRect = r;
      } else {
        // 点在选区外：重新框选
        _dragHandle = null;
        _dragMove = false;
        _dragStart = null;
        _dragStartRect = null;
        _cropStart = p;
        _cropRect = Rect.fromPoints(p, p);
      }
    });
  }

  void _cropPanUpdate(Offset p) {
    setState(() {
      final start = _cropStart;
      if (start != null) {
        _cropRect = _normalizeRect(Rect.fromPoints(start, p));
        return;
      }
      if (_dragHandle != null && _dragStart != null && _dragStartRect != null) {
        _cropRect = _resizeByHandle(
          _dragStartRect!,
          _dragHandle!,
          _dragStart!,
          p,
        );
      } else if (_dragMove && _dragStart != null && _dragStartRect != null) {
        _cropRect = _moveRect(_dragStartRect!, p - _dragStart!);
      }
    });
  }

  Rect _normalizeRect(Rect r) {
    final l = math.min(r.left, r.right);
    final t = math.min(r.top, r.bottom);
    final ri = math.max(r.left, r.right);
    final b = math.max(r.top, r.bottom);
    return Rect.fromLTRB(
      l.clamp(0.0, _frameSize.width),
      t.clamp(0.0, _frameSize.height),
      ri.clamp(0.0, _frameSize.width),
      b.clamp(0.0, _frameSize.height),
    );
  }

  Rect _moveRect(Rect r, Offset delta) {
    var moved = r.shift(delta);
    moved = Rect.fromLTRB(
      moved.left.clamp(0.0, _frameSize.width),
      moved.top.clamp(0.0, _frameSize.height),
      moved.right.clamp(0.0, _frameSize.width),
      moved.bottom.clamp(0.0, _frameSize.height),
    );
    var dx = 0.0;
    var dy = 0.0;
    if (moved.left < 0) dx = -moved.left;
    if (moved.top < 0) dy = -moved.top;
    if (moved.right > _frameSize.width) dx = _frameSize.width - moved.right;
    if (moved.bottom > _frameSize.height) dy = _frameSize.height - moved.bottom;
    return moved.shift(Offset(dx, dy));
  }

  Rect _resizeByHandle(Rect r, int handle, Offset start, Offset current) {
    var l = r.left;
    var t = r.top;
    var ri = r.right;
    var b = r.bottom;
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    switch (handle) {
      case 0: // 左上
        l += dx;
        t += dy;
        break;
      case 1: // 右上
        ri += dx;
        t += dy;
        break;
      case 2: // 左下
        l += dx;
        b += dy;
        break;
      case 4: // 上边
        t += dy;
        break;
      case 5: // 右边
        ri += dx;
        break;
      case 6: // 下边
        b += dy;
        break;
      case 7: // 左边
        l += dx;
        break;
      default: // 右下
        ri += dx;
        b += dy;
    }
    l = l.clamp(0.0, _frameSize.width);
    ri = ri.clamp(0.0, _frameSize.width);
    t = t.clamp(0.0, _frameSize.height);
    b = b.clamp(0.0, _frameSize.height);
    if (ri - l < 24) {
      if (handle == 0 || handle == 2 || handle == 7) {
        l = (ri - 24).clamp(0.0, _frameSize.width);
      } else {
        ri = (l + 24).clamp(0.0, _frameSize.width);
      }
    }
    if (b - t < 24) {
      if (handle == 0 || handle == 1 || handle == 4) {
        t = (b - 24).clamp(0.0, _frameSize.height);
      } else {
        b = (t + 24).clamp(0.0, _frameSize.height);
      }
    }
    return Rect.fromLTRB(l, t, ri, b);
  }

  // ── 界面 ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(child: _buildBody()),
            _bottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Color(0xFF444444),
            ),
          ),
          const Expanded(
            child: Text(
              '调整图标',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _save,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF5DDBA0), Color(0xFF2BAF74)],
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 44,
              color: Color(0xFFC7C7CC),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.manrope,
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _runInitialMatte,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  '重试',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = (constraints.maxWidth - 48).clamp(240.0, 360.0);
              _frameSize = Size(side, side);
              return _buildFrame();
            },
          ),
        ),
        if (_cropMode) ...[
          Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: Text(
              _cropRect == null
                  ? '在图片上拖动，框选要保留的区域'
                  : '拖动白点（四角 + 四边）调整选区，中间拖动可移动选区',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.manrope,
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _cropAction(label: '取消', onTap: _exitCropMode),
                const SizedBox(width: 12),
                _cropAction(
                  label: '确定',
                  primary: true,
                  enabled: _cropRect != null,
                  onTap: _applyCrop,
                ),
              ],
            ),
          ),
        ],
        if (_loading)
          Container(
            color: Colors.white.withValues(alpha: 0.88),
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'AI 抠图中…',
                  style: TextStyle(
                    fontFamily: AppFonts.manrope,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFrame() {
    final bytes = _displayBytes;
    final base = _baseSize();

    return Container(
      width: _frameSize.width,
      height: _frameSize.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8E6), width: 1.2),
      ),
      child: Stack(
        children: [
          if (bytes != null)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _cropMode,
                child: InteractiveViewer(
                  transformationController: _tc,
                  minScale: _minScale,
                  maxScale: 5,
                  boundaryMargin: const EdgeInsets.all(200),
                  onInteractionEnd: (_) => setState(
                    () => _sliderValue = _tc.value.getMaxScaleOnAxis(),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: base.width,
                      height: base.height,
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_cropMode)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => _cropPanStart(d.localPosition),
                onPanUpdate: (d) => _cropPanUpdate(d.localPosition),
                onPanEnd: (_) => setState(() => _cropStart = null),
                onPanCancel: () => setState(() => _cropStart = null),
                child: CustomPaint(
                  painter: _CropOverlayPainter(_cropRect),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F2F1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_zoomTool)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.remove, size: 18, color: Color(0xFF8E8E93)),
                  Expanded(
                    child: Slider(
                      min: _minScale,
                      max: 5,
                      value: _sliderValue.clamp(_minScale, 5.0),
                      activeColor: AppColors.primary,
                      inactiveColor: const Color(0xFFE3E8E6),
                      thumbColor: AppColors.primary,
                      onChanged: _setScaleFromSlider,
                    ),
                  ),
                  const Icon(Icons.add, size: 18, color: Color(0xFF8E8E93)),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _toolButton(
                label: '框选',
                icon: Icons.crop_free,
                selected: _cropMode,
                onTap: _cropMode ? _exitCropMode : _enterCropMode,
              ),
              const SizedBox(width: 18),
              _toolButton(
                label: '旋转',
                icon: Icons.rotate_90_degrees_ccw,
                selected: false,
                onTap: _rotate90,
              ),
              const SizedBox(width: 18),
              _toolButton(
                label: '缩放',
                icon: Icons.zoom_in,
                selected: _zoomTool,
                onTap: () => setState(() {
                  _zoomTool = !_zoomTool;
                  _cropMode = false;
                }),
              ),
              const SizedBox(width: 18),
              _toolButton(
                label: '再次抠图',
                icon: Icons.auto_fix_high,
                selected: false,
                onTap: _rematteCurrent,
              ),
              const SizedBox(width: 18),
              _toolButton(
                label: _usingOriginal ? '重新抠图' : '使用原图',
                icon: _usingOriginal ? Icons.auto_awesome : Icons.photo_outlined,
                selected: false,
                onTap: _usingOriginal ? _redoMatte : _useOriginal,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _setScaleFromSlider(double v) {
    final vv = v.clamp(_minScale, 5.0);
    final center = Offset(_frameSize.width / 2, _frameSize.height / 2);
    // 以显示区中心为锚点缩放：中心点的内容始终停在中心，不会乱窜、不会吸回
    final inv = _tc.value.clone()..invert();
    final p = MatrixUtils.transformPoint(inv, center);
    final newT = center - Offset(vv * p.dx, vv * p.dy);
    _tc.value = Matrix4.diagonal3Values(vv, vv, 1)
      ..setTranslationRaw(newT.dx, newT.dy, 0);
    setState(() => _sliderValue = vv);
  }

  Widget _cropAction({
    required String label,
    required VoidCallback onTap,
    bool primary = false,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 92,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary
              ? (enabled ? AppColors.primary : const Color(0xFFC7D9D2))
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary ? Colors.transparent : const Color(0xFFE3E8E6),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.manrope,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: primary ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
      ),
    );
  }

  Widget _toolButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0x2E3DC88A)
                  : const Color(0xFFF4FAF8),
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: AppColors.primary, width: 1.4)
                  : null,
            ),
            child: Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.manrope,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    // 所见即所得：保存当前显示区内可见的图片部分（挪到哪就存哪）
    final image = _image;
    if (image == null || _loading) return;
    final tl = _screenToImage(Offset.zero);
    final br = _screenToImage(Offset(_frameSize.width, _frameSize.height));
    var ix = tl.dx.floor().clamp(0, image.width - 1);
    var iy = tl.dy.floor().clamp(0, image.height - 1);
    var ix2 = br.dx.ceil().clamp(0, image.width);
    var iy2 = br.dy.ceil().clamp(0, image.height);
    if (ix2 - ix < 2) ix2 = (ix + 2).clamp(0, image.width);
    if (iy2 - iy < 2) iy2 = (iy + 2).clamp(0, image.height);
    try {
      final (visible, png) = await compute(
        _cropEncodeSync,
        (image, ix, iy, ix2 - ix, iy2 - iy),
      );
      final saved = await AiMattingService.savePng(
        png,
        prefix: 'icon_saved',
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      _snack('保存失败，请重试');
    }
  }
}

/// 框选遮罩：框外变暗 + 白色边框 + 四角实心小白点。
class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter(this.rect);

  final Rect? rect;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white;
    final handleFill = Paint()..color = Colors.white;
    if (rect != null) {
      final r = rect!;
      full
        ..addRect(r)
        ..fillType = PathFillType.evenOdd;
      canvas.drawRect(r, border);
      // 四角
      final corners = [
        r.topLeft,
        r.topRight,
        r.bottomLeft,
        r.bottomRight,
      ];
      for (final c in corners) {
        canvas.drawCircle(c, 6, handleFill);
      }
      // 四边中点（略向内侧偏移，避免被边框裁掉）
      final inset = 3.0;
      final edges = [
        Offset(r.center.dx, r.top + inset),
        Offset(r.right - inset, r.center.dy),
        Offset(r.center.dx, r.bottom - inset),
        Offset(r.left + inset, r.center.dy),
      ];
      for (final c in edges) {
        canvas.drawCircle(c, 5, handleFill);
      }
    }
    canvas.drawPath(full, dim);
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) =>
      oldDelegate.rect != rect;
}

// ── 后台 isolate 图片处理（避免界面线程卡顿） ──────────────

/// 解码 + 裁透明边 + 编码 PNG。
(img.Image, Uint8List) _decodeTrimEncodeSync(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const AiMattingException('抠图结果异常，请重试');
  final trimmed = _trimTransparentSync(decoded);
  final png = img.encodePng(trimmed);
  return (trimmed, Uint8List.fromList(png));
}

/// 解码 + 编码 PNG（原图）。
(img.Image, Uint8List) _decodeEncodeSync(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const AiMattingException('无法读取原图');
  final png = img.encodePng(decoded);
  return (decoded, Uint8List.fromList(png));
}

/// 按选区裁剪 + 编码 PNG。
(img.Image, Uint8List) _cropEncodeSync(
  (img.Image, int, int, int, int) args,
) {
  final (image, x, y, w, h) = args;
  final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
  final png = img.encodePng(cropped);
  return (cropped, Uint8List.fromList(png));
}

/// 透明图合成到白底并编码 JPG（再次抠图用）。
Uint8List _compositeJpgSync(img.Image image) {
  final canvas = img.Image(width: image.width, height: image.height);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, image);
  return Uint8List.fromList(img.encodeJpg(canvas, quality: 88));
}

/// 裁掉透明边缘，让主图居中占满显示区。
img.Image _trimTransparentSync(img.Image src) {
  var minX = src.width;
  var minY = src.height;
  var maxX = 0;
  var maxY = 0;
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      if (src.getPixel(x, y).a > 16) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX <= minX || maxY <= minY) return src;
  const pad = 2;
  minX = (minX - pad).clamp(0, src.width - 1);
  minY = (minY - pad).clamp(0, src.height - 1);
  maxX = (maxX + pad).clamp(0, src.width - 1);
  maxY = (maxY + pad).clamp(0, src.height - 1);
  return img.copyCrop(
    src,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}
/// 后台 isolate：图片顺时针旋转 90° 并编码 PNG。
(img.Image, Uint8List) _rotate90Sync(img.Image image) {
  final rotated = img.copyRotate(image, angle: 90);
  final png = img.encodePng(rotated);
  return (rotated, Uint8List.fromList(png));
}
