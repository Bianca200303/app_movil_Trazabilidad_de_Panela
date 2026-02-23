import 'package:intl/intl.dart';

/// Represents a product return record from a client
class ProductReturn {
  final String id;
  final String productionBatchId;
  final String cooperativeId;
  final String clientName;
  final DateTime returnDate;
  final double quantityKg;
  final int quantitySacks;
  final String returnReason;
  final String? observations;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductReturn({
    required this.id,
    required this.productionBatchId,
    required this.cooperativeId,
    required this.clientName,
    required this.returnDate,
    required this.quantityKg,
    required this.quantitySacks,
    required this.returnReason,
    this.observations,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ProductReturn from Supabase JSON response
  factory ProductReturn.fromJson(Map<String, dynamic> json) {
    return ProductReturn(
      id: json['id'] as String,
      productionBatchId: json['production_batch_id'] as String,
      cooperativeId: json['cooperative_id'] as String,
      clientName: json['client_name'] as String,
      returnDate: DateTime.parse(json['return_date'] as String),
      quantityKg: (json['quantity_kg'] as num).toDouble(),
      quantitySacks: json['quantity_sacks'] as int,
      returnReason: json['return_reason'] as String,
      observations: json['observations'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert ProductReturn to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'production_batch_id': productionBatchId,
      'cooperative_id': cooperativeId,
      'client_name': clientName,
      'return_date': returnDate.toIso8601String().split('T')[0],
      'quantity_kg': quantityKg,
      'quantity_sacks': quantitySacks,
      'return_reason': returnReason,
      'observations': observations,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Helper: formatted return date for display (DD/MM/YYYY)
  String get formattedReturnDate {
    return DateFormat('dd/MM/yyyy').format(returnDate);
  }

  /// Helper: display quantity (prioritize sacks if available)
  String get quantityDisplay {
    if (quantitySacks > 0) {
      return '$quantitySacks bolsas (${quantityKg.toStringAsFixed(2)} kg)';
    } else {
      return '${quantityKg.toStringAsFixed(2)} kg';
    }
  }

  @override
  String toString() =>
      'ProductReturn(id: $id, client: $clientName, quantity: $quantityDisplay)';
}

/// Request class for creating a new product return
class CreateProductReturnRequest {
  final String productionBatchId;
  final String clientName;
  final DateTime returnDate;
  final double quantityKg;
  final int quantitySacks;
  final String returnReason;
  final String? observations;
  final String cooperativeId;

  const CreateProductReturnRequest({
    required this.productionBatchId,
    required this.clientName,
    required this.returnDate,
    required this.quantityKg,
    required this.quantitySacks,
    required this.returnReason,
    this.observations,
    required this.cooperativeId,
  });

  /// Convert request to JSON for Supabase insert
  /// Note: created_by is auto-populated by database trigger
  Map<String, dynamic> toJson() {
    return {
      'production_batch_id': productionBatchId,
      'client_name': clientName,
      'return_date': returnDate.toIso8601String().split('T')[0],
      'quantity_kg': quantityKg,
      'quantity_sacks': quantitySacks,
      'return_reason': returnReason,
      if (observations != null && observations!.isNotEmpty)
        'observations': observations,
      'cooperative_id': cooperativeId,
      // created_by is auto-populated by database trigger
    };
  }

  @override
  String toString() =>
      'CreateProductReturnRequest(client: $clientName, quantity: ${quantitySacks > 0 ? '$quantitySacks bolsas' : '$quantityKg kg'})';
}
