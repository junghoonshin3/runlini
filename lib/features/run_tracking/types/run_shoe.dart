import 'package:flutter/foundation.dart';

@immutable
class RunShoe {
  const RunShoe({
    required this.id,
    required this.name,
    required this.brand,
    required this.distanceLimitKm,
    required this.retired,
    required this.createdAt,
    this.deleted = false,
    this.imagePath,
  });

  final String id;
  final String name;
  final String brand;
  final double distanceLimitKm;
  final bool retired;
  final DateTime createdAt;
  final bool deleted;
  final String? imagePath;

  RunShoe copyWith({
    String? id,
    String? name,
    String? brand,
    double? distanceLimitKm,
    bool? retired,
    DateTime? createdAt,
    bool? deleted,
    String? imagePath,
    bool clearImagePath = false,
  }) {
    return RunShoe(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      distanceLimitKm: distanceLimitKm ?? this.distanceLimitKm,
      retired: retired ?? this.retired,
      createdAt: createdAt ?? this.createdAt,
      deleted: deleted ?? this.deleted,
      imagePath: clearImagePath ? null : imagePath ?? this.imagePath,
    );
  }
}
