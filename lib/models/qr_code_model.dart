// lib/models/qr_code_model.dart

class QRCodeModel {
  final String id;
  final String code;
  final String type;
  final DateTime generatedAt;
  final String? assignedTo; // User ID if scanned/used
  final DateTime? scannedAt;
  final String? plantId; // Associated plant ID
  final bool isUsed;
  final String? batchId; // For bulk generation tracking

  QRCodeModel({
    required this.id,
    required this.code,
    required this.type,
    required this.generatedAt,
    this.assignedTo,
    this.scannedAt,
    this.plantId,
    this.isUsed = false,
    this.batchId,
  });

  factory QRCodeModel.fromJson(Map<String, dynamic> json) {
    return QRCodeModel(
      id: json['\$id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? 'plant',
      generatedAt: DateTime.parse(json['generatedAt'] ??
          json['\$createdAt'] ??
          DateTime.now().toIso8601String()),
      assignedTo: json['assignedTo'],
      scannedAt:
          json['scannedAt'] != null ? DateTime.parse(json['scannedAt']) : null,
      plantId: json['plantId'],
      isUsed: json['isUsed'] ?? false,
      batchId: json['batchId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'type': type,
      'generatedAt': generatedAt.toIso8601String(),
      'assignedTo': assignedTo,
      'scannedAt': scannedAt?.toIso8601String(),
      'plantId': plantId,
      'isUsed': isUsed,
      'batchId': batchId,
    };
  }

  QRCodeModel copyWith({
    String? id,
    String? code,
    String? type,
    DateTime? generatedAt,
    String? assignedTo,
    DateTime? scannedAt,
    String? plantId,
    bool? isUsed,
    String? batchId,
  }) {
    return QRCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      generatedAt: generatedAt ?? this.generatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      scannedAt: scannedAt ?? this.scannedAt,
      plantId: plantId ?? this.plantId,
      isUsed: isUsed ?? this.isUsed,
      batchId: batchId ?? this.batchId,
    );
  }
}
