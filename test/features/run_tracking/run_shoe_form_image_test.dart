import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/core/media/image_picker_client.dart';
import 'package:runlini/core/media/local_image_store.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_shoe_image_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/common/run_shoe_form_screen.dart';

void main() {
  testWidgets('picks, previews, saves, and removes a running shoe image', (
    tester,
  ) async {
    final imageFile = (await tester.runAsync(_writeTinyPng))!;
    addTearDown(() => imageFile.parent.delete(recursive: true));
    final repository = _FakeRunSettingsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSettingsRepositoryProvider.overrideWithValue(repository),
          imagePickerClientProvider.overrideWithValue(
            _FakeImagePickerClient(imageFile.path),
          ),
          localImageStoreProvider.overrideWithValue(_FakeLocalImageStore()),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const _FormLauncher()),
      ),
    );
    await tester.tap(find.byKey(const Key('open-shoe-form-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shoe-image-picker-button')));
    await tester.pump();
    expect(find.byKey(const Key('shoe-image-preview')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('shoe-brand-field')), 'Nike');
    await tester.enterText(find.byKey(const Key('shoe-name-field')), 'Pegasus');
    await tester.tap(find.byKey(const Key('save-shoe-button')));
    await tester.pump();
    expect(repository.shoes.single.imagePath, imageFile.path);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSettingsRepositoryProvider.overrideWithValue(repository),
          imagePickerClientProvider.overrideWithValue(
            _FakeImagePickerClient(imageFile.path),
          ),
          localImageStoreProvider.overrideWithValue(_FakeLocalImageStore()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: _FormLauncher(shoe: repository.shoes.single),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-shoe-form-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shoe-image-preview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shoe-image-remove-button')));
    await tester.pump();
    expect(find.byKey(const Key('shoe-image-preview')), findsNothing);
    await tester.tap(find.byKey(const Key('save-shoe-button')));
    await tester.pump();
    expect(repository.shoes.single.imagePath, isNull);
  });

  testWidgets('cleans up a picked image when closing without saving', (
    tester,
  ) async {
    final imageFile = (await tester.runAsync(_writeTinyPng))!;
    addTearDown(() => imageFile.parent.delete(recursive: true));
    final imageStore = _FakeLocalImageStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSettingsRepositoryProvider.overrideWithValue(
            _FakeRunSettingsRepository(),
          ),
          imagePickerClientProvider.overrideWithValue(
            _FakeImagePickerClient(imageFile.path),
          ),
          localImageStoreProvider.overrideWithValue(imageStore),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const _FormLauncher()),
      ),
    );
    await tester.tap(find.byKey(const Key('open-shoe-form-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shoe-image-picker-button')));
    await tester.pump();
    expect(find.byKey(const Key('shoe-image-preview')), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(imageStore.deletedPaths, [imageFile.path]);
    expect(tester.takeException(), isNull);
  });
}

class _FormLauncher extends StatelessWidget {
  const _FormLauncher({this.shoe});

  final RunShoe? shoe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const Key('open-shoe-form-button'),
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => RunShoeFormScreen(shoe: shoe),
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );
  }
}

Future<File> _writeTinyPng() async {
  final directory = await Directory.systemTemp.createTemp('runlini-shoe-image');
  final file = File('${directory.path}/shoe.png');
  await file.writeAsBytes(_tinyPngBytes);
  return file;
}

class _FakeImagePickerClient implements ImagePickerClient {
  const _FakeImagePickerClient(this.path);

  final String path;

  @override
  Future<XFile?> pickGalleryImage() async => XFile(path);
}

class _FakeLocalImageStore extends LocalImageStore {
  final List<String> deletedPaths = <String>[];

  @override
  Future<String> saveShoeImage(XFile source, {String? replacingPath}) async {
    return source.path;
  }

  @override
  Future<void> deleteImage(String? path) async {
    if (path != null) {
      deletedPaths.add(path);
    }
  }
}

class _FakeRunSettingsRepository implements RunSettingsRepository {
  RunSettingsState settings = const RunSettingsState();
  final List<RunShoe> shoes = <RunShoe>[];

  @override
  Future<RunSettingsState> loadSettings() async => settings;

  @override
  Future<void> saveSettings(RunSettingsState settings) async {
    this.settings = settings;
  }

  @override
  Future<List<RunShoe>> listShoes() async => List<RunShoe>.unmodifiable(shoes);

  @override
  Future<void> saveShoe(RunShoe shoe) async {
    shoes.removeWhere((existing) => existing.id == shoe.id);
    shoes.add(shoe);
  }

  @override
  Future<void> retireShoe(String id) async {}

  @override
  Future<void> deleteShoe(String id) async {}
}

const _tinyPngBytes = <int>[
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1f,
  0x15,
  0xc4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0a,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9c,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0d,
  0x0a,
  0x2d,
  0xb4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];
