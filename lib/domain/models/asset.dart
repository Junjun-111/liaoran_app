import 'asset_lifecycle_status.dart';

/// 资产领域模型（对应「有数」的万物资产化）。
///
/// 包含完整生命周期所需字段：买入信息、当前状态、退役日期、
/// 目标日均成本（回本判定）、Care 关注到期时间、卖出记录等。
class Asset {
  const Asset({
    required this.id,
    required this.name,
    required this.category,
    required this.currency,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.status,
    this.retiredDate,
    this.careExpiryDate,
    this.targetCpd,
    this.remark = '',
    this.icon,
    this.attachmentPath,
    this.tags = const [],
    required this.createdAt,
    this.saleRecords = const [],
    this.investments = const [],
    this.maintenanceRecords = const [],
    this.costBasisIncludesInvestment = false,
  });

  final String id;
  final String name;

  /// 分类（取值见 `Dictionaries.assetCategories`）
  final String category;

  /// 币种（默认 CNY，后续可由设置页货币单位接管）
  final String currency;

  /// 买入价
  final double purchasePrice;

  /// 买入日期
  final DateTime purchaseDate;

  /// 当前生命周期状态
  final AssetLifecycleStatus status;

  /// 退役日期（仅 [AssetLifecycleStatus.retired] 时有效）
  final DateTime? retiredDate;

  /// Care 到期时间；非 null 表示已开启重点关注
  final DateTime? careExpiryDate;

  /// 目标日均成本（回本判定用）；null 表示未设置
  final double? targetCpd;

  /// 备注
  final String remark;

  /// 图标资源路径；null 表示使用默认资产图标
  final String? icon;

  /// 附件图片本地路径
  final String? attachmentPath;

  /// 用户标签
  final List<String> tags;

  final DateTime createdAt;

  /// 卖出记录（可多条，取最新一条参与计算）
  final List<SaleRecord> saleRecords;

  /// 后续投入记录（配件、维修、升级等追加投入）
  final List<InvestmentRecord> investments;

  /// 维修 / 保养记录（花费计入累计投入）
  final List<MaintenanceRecord> maintenanceRecords;

  /// 日均成本是否按「累计价值」计算（买入价 + 累计投入 + 维修保养）。
  /// 开启后日均成本反映每天实际花了多少钱；关闭则按买入价计算。
  final bool costBasisIncludesInvestment;

  /// 累计投入金额
  double get cumulativeInvestment =>
      investments.fold(0.0, (sum, r) => sum + r.amount) +
      maintenanceRecords.fold(0.0, (sum, r) => sum + r.cost);

  /// 维修 / 保养总花费
  double get totalMaintenanceCost =>
      maintenanceRecords.fold(0.0, (sum, r) => sum + r.cost);

  /// 日均成本计算基数：
  /// 开启「按累计价值计算」时返回累计价值（买入价 + 累计投入 + 维修保养），
  /// 否则返回买入价。
  double get costBasis =>
      costBasisIncludesInvestment ? purchasePrice + cumulativeInvestment : purchasePrice;

  /// 最近一次卖出记录（按卖出日期取最新；无记录时 null）
  SaleRecord? get latestSale {
    if (saleRecords.isEmpty) return null;
    return saleRecords.reduce(
      (a, b) => a.saleDate.isAfter(b.saleDate) ? a : b,
    );
  }

  static const Object _unset = Object();

  /// 不可变复制：仅替换传入的字段。
  ///
  /// 可空字段（退役日期 / Care / 目标成本 / 图标 / 附件）用哨兵值区分
  /// “不修改”与“显式清空为 null”。
  Asset copyWith({
    String? name,
    String? category,
    String? currency,
    double? purchasePrice,
    DateTime? purchaseDate,
    AssetLifecycleStatus? status,
    Object? retiredDate = _unset,
    Object? careExpiryDate = _unset,
    Object? targetCpd = _unset,
    String? remark,
    Object? icon = _unset,
    Object? attachmentPath = _unset,
    List<String>? tags,
    List<SaleRecord>? saleRecords,
    List<InvestmentRecord>? investments,
    List<MaintenanceRecord>? maintenanceRecords,
    bool? costBasisIncludesInvestment,
  }) {
    return Asset(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      status: status ?? this.status,
      retiredDate:
          retiredDate == _unset ? this.retiredDate : retiredDate as DateTime?,
      careExpiryDate: careExpiryDate == _unset
          ? this.careExpiryDate
          : careExpiryDate as DateTime?,
      targetCpd:
          targetCpd == _unset ? this.targetCpd : targetCpd as double?,
      remark: remark ?? this.remark,
      icon: icon == _unset ? this.icon : icon as String?,
      attachmentPath:
          attachmentPath == _unset ? this.attachmentPath : attachmentPath as String?,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      saleRecords: saleRecords ?? this.saleRecords,
      investments: investments ?? this.investments,
      maintenanceRecords: maintenanceRecords ?? this.maintenanceRecords,
      costBasisIncludesInvestment:
          costBasisIncludesInvestment ?? this.costBasisIncludesInvestment,
    );
  }

  /// 备份/恢复用序列化
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'currency': currency,
        'purchasePrice': purchasePrice,
        'purchaseDate': purchaseDate.toIso8601String(),
        'status': status.label,
        'retiredDate': retiredDate?.toIso8601String(),
        'careExpiryDate': careExpiryDate?.toIso8601String(),
        'targetCpd': targetCpd,
        'remark': remark,
        'icon': icon,
        'attachmentPath': attachmentPath,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'saleRecords': [for (final r in saleRecords) r.toJson()],
        'investments': [for (final r in investments) r.toJson()],
        'maintenanceRecords': [
          for (final r in maintenanceRecords) r.toJson(),
        ],
        'costBasisIncludesInvestment': costBasisIncludesInvestment,
      };

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        currency: json['currency'] as String? ?? 'CNY',
        purchasePrice: (json['purchasePrice'] as num).toDouble(),
        purchaseDate: DateTime.parse(json['purchaseDate'] as String),
        status: AssetLifecycleStatus.fromLabel(json['status'] as String? ?? '服役中'),
        retiredDate: json['retiredDate'] == null
            ? null
            : DateTime.parse(json['retiredDate'] as String),
        careExpiryDate: json['careExpiryDate'] == null
            ? null
            : DateTime.parse(json['careExpiryDate'] as String),
        targetCpd: (json['targetCpd'] as num?)?.toDouble(),
        remark: json['remark'] as String? ?? '',
        icon: json['icon'] as String?,
        attachmentPath: json['attachmentPath'] as String?,
        tags: [for (final t in (json['tags'] as List? ?? const [])) t as String],
        createdAt: DateTime.parse(json['createdAt'] as String),
        saleRecords: [
          for (final r in (json['saleRecords'] as List? ?? const []))
            SaleRecord.fromJson(r as Map<String, dynamic>),
        ],
        investments: [
          for (final r in (json['investments'] as List? ?? const []))
            InvestmentRecord.fromJson(r as Map<String, dynamic>),
        ],
        maintenanceRecords: [
          for (final r in (json['maintenanceRecords'] as List? ?? const []))
            MaintenanceRecord.fromJson(r as Map<String, dynamic>),
        ],
        costBasisIncludesInvestment:
            json['costBasisIncludesInvestment'] as bool? ?? false,
      );
}

/// 卖出记录（闲置流转复盘：卖出价 + 卖出日期 + 备注）。
class SaleRecord {
  const SaleRecord({
    required this.salePrice,
    required this.saleDate,
    this.remark = '',
    required this.createdAt,
  });

  /// 二手卖出价
  final double salePrice;

  /// 卖出日期
  final DateTime saleDate;

  /// 备注（平台、买家等）
  final String remark;

  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'salePrice': salePrice,
        'saleDate': saleDate.toIso8601String(),
        'remark': remark,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SaleRecord.fromJson(Map<String, dynamic> json) => SaleRecord(
        salePrice: (json['salePrice'] as num).toDouble(),
        saleDate: DateTime.parse(json['saleDate'] as String),
        remark: json['remark'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
/// 后续投入记录（累计投入 = 各条金额之和）。
class InvestmentRecord {
  const InvestmentRecord({
    required this.amount,
    required this.date,
    this.remark = '',
    required this.createdAt,
  });

  /// 投入金额
  final double amount;

  /// 投入日期
  final DateTime date;

  /// 备注（用途等）
  final String remark;

  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'date': date.toIso8601String(),
        'remark': remark,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InvestmentRecord.fromJson(Map<String, dynamic> json) =>
      InvestmentRecord(
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        remark: json['remark'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// 维修 / 保养记录（维修保养花费计入资产累计投入）。
class MaintenanceRecord {
  const MaintenanceRecord({
    required this.cost,
    required this.date,
    this.description = '',
    required this.createdAt,
  });

  /// 维修 / 保养花费
  final double cost;

  /// 维修 / 保养日期
  final DateTime date;

  /// 维修 / 保养说明（如：换电池、常规保养）
  final String description;

  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'cost': cost,
        'date': date.toIso8601String(),
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      MaintenanceRecord(
        cost: (json['cost'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
