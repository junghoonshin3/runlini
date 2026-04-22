import 'dart:io';

void main() {
  final errors = <String>[];

  _checkRequiredPaths(errors);
  _checkFeatureStructure(errors);
  _checkImports(errors);
  _checkFileLengths(errors);

  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln('error: $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Runlini guardrails passed.');
}

void _checkRequiredPaths(List<String> errors) {
  const requiredPaths = <String>[
    'AGENTS.md',
    'PLANS.md',
    'ARCHITECTURE.md',
    'docs/design-docs/core-beliefs.md',
    'docs/product-specs/phase-roadmap.md',
    'docs/platform/permissions.md',
    'docs/testing/field-test-protocol.md',
    'docs/exec-plans/active/runlini-agent-first-bootstrap.md',
    'tool/guardrails.dart',
  ];

  for (final path in requiredPaths) {
    if (!FileSystemEntity.typeSync(path).existsInRepo) {
      errors.add('Missing required repo artifact: $path');
    }
  }
}

void _checkFeatureStructure(List<String> errors) {
  final featuresDir = Directory('lib/features');
  if (!featuresDir.existsSync()) {
    errors.add('Missing lib/features directory.');
    return;
  }

  const allowedLayers = <String>{'repo', 'service', 'state', 'types', 'ui'};

  for (final entity in featuresDir.listSync().whereType<Directory>()) {
    for (final child in entity.listSync().whereType<Directory>()) {
      if (!allowedLayers.contains(_basename(child.path))) {
        errors.add(
          'Unexpected feature layer ${child.path}. Allowed layers: ${allowedLayers.join(', ')}',
        );
      }
    }
  }
}

void _checkImports(List<String> errors) {
  final layerRanks = <String, int>{
    'types': 0,
    'repo': 1,
    'service': 2,
    'state': 3,
    'ui': 4,
  };
  final importPattern = RegExp("^import 'package:runlini/([^']+)';");

  for (final file in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) {
      continue;
    }

    final normalizedPath = file.path.replaceAll('\\', '/');
    final sourceParts = normalizedPath.split('/');
    if (sourceParts.length < 4 || sourceParts[1] != 'features') {
      continue;
    }

    final sourceFeature = sourceParts[2];
    final sourceLayer = sourceParts[3];

    for (final line in file.readAsLinesSync()) {
      final match = importPattern.firstMatch(line.trim());
      if (match == null) {
        continue;
      }

      final importParts = match.group(1)!.split('/');
      if (importParts.first != 'features' || importParts.length < 3) {
        continue;
      }

      final targetFeature = importParts[1];
      final targetLayer = importParts[2];
      final sourceRank = layerRanks[sourceLayer];
      final targetRank = layerRanks[targetLayer];

      if (sourceFeature == targetFeature &&
          sourceRank != null &&
          targetRank != null &&
          sourceRank < targetRank) {
        errors.add(
          'Layer violation in ${file.path}: $sourceLayer cannot import $targetLayer.',
        );
      }
    }
  }

  for (final file in Directory(
    'lib/core',
  ).listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) {
      continue;
    }

    for (final line in file.readAsLinesSync()) {
      final match = importPattern.firstMatch(line.trim());
      if (match == null) {
        continue;
      }

      final importParts = match.group(1)!.split('/');
      if (importParts.first != 'features' || importParts.length < 3) {
        continue;
      }

      final targetLayer = importParts[2];
      if (targetLayer != 'types') {
        errors.add(
          'Core layer may only import feature types: ${file.path} -> ${match.group(1)}',
        );
      }
    }
  }
}

void _checkFileLengths(List<String> errors) {
  const maxDartFileLines = 300;

  for (final root in const <String>['lib', 'test', 'tool']) {
    final directory = Directory(root);
    if (!directory.existsSync()) {
      continue;
    }

    for (final file in directory.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }

      final lineCount = file.readAsLinesSync().length;
      if (lineCount > maxDartFileLines) {
        errors.add(
          '${file.path} is $lineCount lines. Split it to stay at or below '
          '$maxDartFileLines lines.',
        );
      }
    }
  }
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').last;
}

extension on FileSystemEntityType {
  bool get existsInRepo => this != FileSystemEntityType.notFound;
}
