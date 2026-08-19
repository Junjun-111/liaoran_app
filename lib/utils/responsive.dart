/// 屏幕尺寸响应式工具
///
/// 自动识别屏幕宽度并划分断点，配合内容最大宽度约束，
/// 让首页在手机 / 平板 / 桌面端均保持合理比例与协调间距。
///
/// 断点（参考 Material 3 窗口尺寸类 + 通用实践）：
/// - 手机（compact）：宽 < 600
/// - 平板（medium）：600 ≤ 宽 < 1024
/// - 桌面（expanded）：宽 ≥ 1024
class Responsive {
  Responsive._();

  /// 手机与平板的分界宽度
  static const double _mobileBreakpoint = 600;

  /// 平板与桌面的分界宽度
  static const double _tabletBreakpoint = 1024;

  /// 宽屏（平板 / 桌面）时内容区最大宽度
  ///
  /// 取 480：略大于设计基准 440，既保留移动端紧凑感，
  /// 又能在宽屏上居中留白、避免卡片被拉得过宽。
  static const double contentMaxWidth = 480;

  /// 是否手机（窄屏）
  static bool isMobile(double width) => width < _mobileBreakpoint;

  /// 是否平板
  static bool isTablet(double width) =>
      width >= _mobileBreakpoint && width < _tabletBreakpoint;

  /// 是否桌面（宽屏）
  static bool isDesktop(double width) => width >= _tabletBreakpoint;

  /// 是否宽屏（平板及以上）：内容需居中并约束最大宽度
  static bool isWide(double width) => width >= _mobileBreakpoint;

  /// 获取内容区最大宽度
  ///
  /// 窄屏返回 [double.infinity]（不限制，撑满屏幕）；
  /// 宽屏返回 [contentMaxWidth]（居中约束）。
  static double contentWidthFor(double width) =>
      isWide(width) ? contentMaxWidth : double.infinity;
}
