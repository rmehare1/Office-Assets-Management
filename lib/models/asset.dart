import 'package:flutter/material.dart';

class Asset {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String? categoryIconStr;
  final String statusId;
  final String statusName;
  final String? statusColorStr;
  final String assignedTo;
  final String assignedToName;
  final String serialNumber;
  final String locationId;
  final String locationName;
  final DateTime purchaseDate;
  final double purchasePrice;
  final String? imageUrl;
  final String? notes;
  final String? barcodeValue;
  final DateTime? lastServiceDate;

  const Asset({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.categoryIconStr,
    required this.statusId,
    required this.statusName,
    this.statusColorStr,
    required this.assignedTo,
    required this.assignedToName,
    required this.serialNumber,
    required this.locationId,
    required this.locationName,
    required this.purchaseDate,
    required this.purchasePrice,
    this.imageUrl,
    this.notes,
    this.barcodeValue,
    this.lastServiceDate,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] as String? ?? '',
      categoryName: json['category'] as String? ?? 'Unknown',
      categoryIconStr: json['category_icon'] as String?,
      statusId: json['status_id'] as String? ?? '',
      statusName: json['status'] as String? ?? 'Unknown',
      statusColorStr: json['status_color'] as String?,
      assignedTo: json['assigned_to'] as String? ?? '',
      assignedToName: json['assigned_to_name'] as String? ?? '',
      serialNumber: json['serial_number'] as String,
      locationId: json['location_id'] as String? ?? '',
      locationName: json['location_name'] as String? ?? json['location'] as String? ?? '',
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      purchasePrice: double.parse(json['purchase_price'].toString()),
      imageUrl: json['image_url'] as String?,
      notes: json['notes'] as String?,
      barcodeValue: json['barcode_value'] as String?,
      lastServiceDate: json['last_service_date'] != null ? DateTime.parse(json['last_service_date'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'status_id': statusId,
      'assigned_to': assignedTo.isEmpty ? null : assignedTo,
      'serial_number': serialNumber,
      'location_id': locationId.isEmpty ? null : locationId,
      'location_name': locationName,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      'purchase_price': purchasePrice,
      'image_url': imageUrl,
      'notes': notes,
      'barcode_value': barcodeValue,
      'last_service_date': lastServiceDate?.toIso8601String().split('T')[0],
    };
  }

  /// Generates a JSON string with all asset data for QR code encoding.
  String toQrJson() {
    final data = <String, dynamic>{
      'serial_number': serialNumber,
      'name': name,
      'category': categoryName,
      'category_id': categoryId,
      'location': locationName,
      'purchase_price': purchasePrice,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      'status': statusName,
      'status_id': statusId,
      if (assignedTo.isNotEmpty) 'assigned_to': assignedTo,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
    // Use a simple JSON-like format
    final buffer = StringBuffer('{');
    final entries = data.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      if (e.value is String) {
        buffer.write('"${e.key}":"${e.value}"');
      } else {
        buffer.write('"${e.key}":${e.value}');
      }
      if (i < entries.length - 1) buffer.write(',');
    }
    buffer.write('}');
    return buffer.toString();
  }

  Asset copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryName,
    String? categoryIconStr,
    String? statusId,
    String? statusName,
    String? statusColorStr,
    String? assignedTo,
    String? assignedToName,
    String? serialNumber,
    String? locationId,
    String? locationName,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? imageUrl,
    String? notes,
    String? barcodeValue,
    DateTime? lastServiceDate,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIconStr: categoryIconStr ?? this.categoryIconStr,
      statusId: statusId ?? this.statusId,
      statusName: statusName ?? this.statusName,
      statusColorStr: statusColorStr ?? this.statusColorStr,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      serialNumber: serialNumber ?? this.serialNumber,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
    );
  }

  IconData get categoryIcon {
    switch (categoryIconStr) {
      case 'laptop_mac': return Icons.laptop_mac;
      case 'monitor': return Icons.monitor;
      case 'phone_android': return Icons.phone_android;
      case 'chair': return Icons.chair;
      case 'headphones': return Icons.headphones;
      default: return Icons.devices_other;
    }
  }

  Color get statusColor {
    if (statusColorStr != null && statusColorStr!.startsWith('0x')) {
      try {
        return Color(int.parse(statusColorStr!));
      } catch (e) {
        return Colors.grey;
      }
    }
    return Colors.grey;
  }

  String get statusLabel => statusName;
  String get categoryLabel => categoryName;
}
