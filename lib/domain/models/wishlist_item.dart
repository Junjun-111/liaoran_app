/// 心愿清单领域模型。
///
/// 目标金额 + 已攒金额 → 攒钱进度；completed 标记完成。
class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.name,
    required this.category,
    required this.targetAmount,
    this.savedAmount = 0,
    required this.addDate,
    this.targetDate,
    this.completed = false,
    this.icon,
    this.remark = '',
    this.transactions = const [],
    required this.createdAt,
  });

  final String id;
  final String name;

  /// 分类（取值见 `Dictionaries.assetCategories`）
  final String category;

  /// 目标金额
  final double targetAmount;

  /// 已攒金额
  final double savedAmount;

  /// 添加日期
  final DateTime addDate;

  /// 期望完成日期（可选）
  final DateTime? targetDate;

  /// 是否已完成
  final bool completed;

  /// 图标资源路径
  final String? icon;

  final String remark;

  /// 资金存取流水（按时间追加）
  final List<WishTransaction> transactions;

  final DateTime createdAt;

  /// 攒钱进度 0.0~1.0（已完成恒为 1）
  double get progress {
    if (completed) return 1.0;
    if (targetAmount <= 0) return 0.0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  }

  static const Object _unset = Object();

  WishlistItem copyWith({
    String? name,
    String? category,
    double? targetAmount,
    double? savedAmount,
    DateTime? addDate,
    Object? targetDate = _unset,
    bool? completed,
    Object? icon = _unset,
    String? remark,
    List<WishTransaction>? transactions,
  }) {
    return WishlistItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      addDate: addDate ?? this.addDate,
      targetDate:
          targetDate == _unset ? this.targetDate : targetDate as DateTime?,
      completed: completed ?? this.completed,
      icon: icon == _unset ? this.icon : icon as String?,
      remark: remark ?? this.remark,
      transactions: transactions ?? this.transactions,
      createdAt: createdAt,
    );
  }

  /// 备份/恢复用序列化
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'addDate': addDate.toIso8601String(),
        'targetDate': targetDate?.toIso8601String(),
        'completed': completed,
        'icon': icon,
        'remark': remark,
        'transactions': [for (final t in transactions) t.toJson()],
        'createdAt': createdAt.toIso8601String(),
      };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? '其他',
        targetAmount: (json['targetAmount'] as num).toDouble(),
        savedAmount: (json['savedAmount'] as num?)?.toDouble() ?? 0,
        addDate: DateTime.parse(json['addDate'] as String),
        targetDate: json['targetDate'] == null
            ? null
            : DateTime.parse(json['targetDate'] as String),
        completed: json['completed'] as bool? ?? false,
        icon: json['icon'] as String?,
        remark: json['remark'] as String? ?? '',
        transactions: [
          for (final t in (json['transactions'] as List? ?? const []))
            WishTransaction.fromJson(t as Map<String, dynamic>),
        ],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// 心愿资金流水类型
enum WishTransactionType { deposit, withdraw }

/// 心愿资金流水记录
class WishTransaction {
  const WishTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
  });

  final String id;
  final WishTransactionType type;

  /// 正数金额；展示时根据类型显示存入或取出
  final double amount;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory WishTransaction.fromJson(Map<String, dynamic> json) =>
      WishTransaction(
        id: json['id'] as String,
        type: WishTransactionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => WishTransactionType.deposit,
        ),
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );
}
