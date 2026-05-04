part of 'sqflite_run_settings_repository.dart';

RunShoe _shoeFromRow(Map<String, Object?> row) {
  return RunShoe(
    id: row['id']! as String,
    name: row['name']! as String,
    brand: row['brand']! as String,
    distanceLimitKm: (row['distance_limit_km']! as num).toDouble(),
    retired: (row['retired']! as num).toInt() == 1,
    createdAt: DateTime.parse(row['created_at']! as String),
    deleted: ((row['deleted'] as num?)?.toInt() ?? 0) == 1,
    imagePath: row['image_path'] as String?,
  );
}

Map<String, Object?> _shoeRow(RunShoe shoe) {
  return <String, Object?>{
    'id': shoe.id,
    'name': shoe.name,
    'brand': shoe.brand,
    'distance_limit_km': shoe.distanceLimitKm,
    'retired': shoe.retired ? 1 : 0,
    'deleted': shoe.deleted ? 1 : 0,
    'image_path': shoe.imagePath,
    'created_at': shoe.createdAt.toIso8601String(),
  };
}
