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
