/// 订阅记录模型（由「添加订阅」表单创建，展示在「订阅管理」列表）。
class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.platform,
    required this.type,
    required this.amount,
    required this.currency,
    required this.cycle,
    required this.firstDate,
    required this.expiryDate,
    this.nextChargeDate,
    required this.status,
    this.remark = '',
    this.icon,
    this.attachmentPath,
    this.notifyEnabled = true,
    this.notifyDaysBefore = 3,
    this.notifyHour = 9,
    required this.createdAt,
  });

  /// 唯一标识（编辑时按 id 替换）
  final String id;

  /// APP / 服务名称
  final String name;

  /// 订阅平台（苹果 / Google Play / ...）
  final String platform;

  /// 订阅类型：自动续费 / 买断 / 一次性
  final String type;

  /// 订阅金额
  final double amount;

  /// 币种（CNY / USD / ...）
  final String currency;

  /// 扣款周期：包月 / 包季 / 包年 / 无
  final String cycle;

  /// 首次订阅时间
  final DateTime? firstDate;

  /// 当前周期到期时间
  final DateTime? expiryDate;

  /// 下次自动扣款时间（可选）
  final DateTime? nextChargeDate;

  /// 当前状态：生效中 / 已过期 / 已取消 / 暂停中
  final String status;

  /// 备注
  final String remark;

  /// 所选图标资源路径；null 表示使用默认日历图标（Material Icons）
  final String? icon;

  /// 截图 / 发票附件本地路径（可选）
  final String? attachmentPath;

  /// 是否接收到期提醒
  final bool notifyEnabled;

  /// 提前几天提醒（1 / 3 / 7）
  final int notifyDaysBefore;

  /// 提醒时间（小时）
  final int notifyHour;

  /// 创建时间
  final DateTime createdAt;

  /// 累计订阅金额：从首次订阅到当前周期（或至今），按扣款周期估算的总花费。
  double get cumulativeAmount {
    final start = firstDate;
    final end = expiryDate ?? DateTime.now();
    if (cycle == '无' || start == null) return amount;
    var months =
        (end.year - start.year) * 12 + (end.month - start.month) + 1;
    if (months < 1) months = 1;
    switch (cycle) {
      case '包季':
        return amount * ((months + 2) ~/ 3);
      case '包年':
        return amount * ((months + 11) ~/ 12);
      default:
        return amount * months;
    }
  }

  /// 按扣款周期折算的月均金额（包月×1、包季÷3、包年÷12、无=0）。
  double get monthlyAmount {
    switch (cycle) {
      case '包季':
        return amount / 3;
      case '包年':
        return amount / 12;
      case '无':
        return 0;
      default:
        return amount;
    }
  }

  /// 备份/恢复用序列化
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform,
        'type': type,
        'amount': amount,
        'currency': currency,
        'cycle': cycle,
        'firstDate': firstDate?.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'nextChargeDate': nextChargeDate?.toIso8601String(),
        'status': status,
        'remark': remark,
        'icon': icon,
        'attachmentPath': attachmentPath,
        'notifyEnabled': notifyEnabled,
        'notifyDaysBefore': notifyDaysBefore,
        'notifyHour': notifyHour,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String,
        name: json['name'] as String,
        platform: json['platform'] as String? ?? '自定义',
        type: json['type'] as String? ?? '自动续费',
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'CNY',
        cycle: json['cycle'] as String? ?? '包月',
        firstDate: _date(json['firstDate']),
        expiryDate: _date(json['expiryDate']),
        nextChargeDate: _date(json['nextChargeDate']),
        status: json['status'] as String? ?? '生效中',
        remark: json['remark'] as String? ?? '',
        icon: json['icon'] as String?,
        attachmentPath: json['attachmentPath'] as String?,
        notifyEnabled: json['notifyEnabled'] as bool? ?? true,
        notifyDaysBefore: (json['notifyDaysBefore'] as num?)?.toInt() ?? 3,
        notifyHour: (json['notifyHour'] as num?)?.toInt() ?? 9,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);
}
