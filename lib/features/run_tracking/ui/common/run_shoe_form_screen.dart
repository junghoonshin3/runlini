import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/media/image_picker_client.dart';
import 'package:runlini/core/media/local_image_store.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_shoe_image_providers.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/common/run_shoe_form_fields.dart';
import 'package:runlini/features/run_tracking/ui/common/run_shoe_image_picker_panel.dart';

class RunShoeFormScreen extends ConsumerStatefulWidget {
  const RunShoeFormScreen({super.key, this.shoe});

  final RunShoe? shoe;

  @override
  ConsumerState<RunShoeFormScreen> createState() => _RunShoeFormScreenState();
}

class _RunShoeFormScreenState extends ConsumerState<RunShoeFormScreen> {
  final _brandController = TextEditingController();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController(text: '800');
  late final ImagePickerClient _imagePickerClient;
  late final LocalImageStore _imageStore;
  late final RunSettingsController _settingsController;
  bool _makeDefault = false;
  bool _saved = false;
  String? _imagePath;
  String? _originalImagePath;
  String? _errorText;

  bool get _isEditing => widget.shoe != null;

  @override
  void initState() {
    super.initState();
    _imagePickerClient = ref.read(imagePickerClientProvider);
    _imageStore = ref.read(localImageStoreProvider);
    _settingsController = ref.read(runSettingsControllerProvider.notifier);
    final shoe = widget.shoe;
    final settings = ref.read(runSettingsControllerProvider).value;
    if (shoe == null) {
      return;
    }
    _brandController.text = shoe.brand;
    _nameController.text = shoe.name;
    _limitController.text = shoe.distanceLimitKm.toStringAsFixed(0);
    _imagePath = shoe.imagePath;
    _originalImagePath = shoe.imagePath;
    _makeDefault = settings?.defaultShoeId == shoe.id && !shoe.retired;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _nameController.dispose();
    _limitController.dispose();
    if (!_saved && _imagePath != null && _imagePath != _originalImagePath) {
      unawaited(_imageStore.deleteImage(_imagePath));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(title: Text(_isEditing ? '러닝화 수정' : '러닝화 추가')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: FilledButton(
          key: const Key('save-shoe-button'),
          onPressed: _save,
          child: Text(_isEditing ? '수정 저장' : '저장'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('shoe-add-screen'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              _isEditing ? '러닝화 수정' : '새 러닝화',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            const Text('브랜드, 모델명, 교체 기준 거리를 기록해요.', style: _mutedStyle),
            const SizedBox(height: 18),
            RunShoeImagePickerPanel(
              imagePath: _imagePath,
              onPickImage: _pickImage,
              onRemoveImage: _removeImage,
            ),
            const SizedBox(height: 14),
            RunShoeFormPanel(
              title: '기본 정보',
              child: Column(
                children: [
                  RunShoeTextField(
                    key: const Key('shoe-brand-field'),
                    controller: _brandController,
                    label: '브랜드',
                    hint: 'Nike, Adidas, Asics',
                  ),
                  const SizedBox(height: 12),
                  RunShoeTextField(
                    key: const Key('shoe-name-field'),
                    controller: _nameController,
                    label: '모델 / 별명',
                    hint: 'Pegasus 41, Daily Trainer',
                  ),
                  const SizedBox(height: 12),
                  RunShoeTextField(
                    key: const Key('shoe-limit-field'),
                    controller: _limitController,
                    label: '교체 기준 거리 (km)',
                    hint: '800',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RunShoeFormPanel(
              title: '사용 설정',
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  key: const Key('shoe-default-switch'),
                  value: _makeDefault,
                  onChanged: widget.shoe?.retired == true
                      ? null
                      : (value) => setState(() => _makeDefault = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('기본 러닝화로 설정'),
                  subtitle: Text(
                    widget.shoe?.retired == true
                        ? '은퇴한 러닝화는 기본값으로 선택할 수 없어요.'
                        : '다음 러닝 저장 시 이 신발을 자동으로 연결해요.',
                    style: _mutedStyle,
                  ),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(_errorText!, style: _errorStyle),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final limit = double.tryParse(_limitController.text.trim());
    if (name.isEmpty) {
      setState(() => _errorText = '모델명이나 별명을 입력해 주세요.');
      return;
    }
    if (limit == null || limit <= 0) {
      setState(() => _errorText = '교체 기준 거리를 숫자로 입력해 주세요.');
      return;
    }

    final defaultShoeId = ref
        .read(runSettingsControllerProvider)
        .value
        ?.defaultShoeId;
    final normalizedBrand = brand.isEmpty ? 'Runlini' : brand;
    final existing = widget.shoe;
    final savedShoe = existing == null
        ? await _settingsController.addShoe(
            name: name,
            brand: normalizedBrand,
            distanceLimitKm: limit,
            imagePath: _imagePath,
          )
        : existing.copyWith(
            name: name,
            brand: normalizedBrand,
            distanceLimitKm: limit,
            imagePath: _imagePath,
            clearImagePath: _imagePath == null,
          );
    if (existing != null) {
      await _settingsController.updateShoe(savedShoe);
    }
    await _syncDefaultShoe(savedShoe, existing, defaultShoeId);
    _saved = true;
    final originalPath = _originalImagePath;
    if (originalPath != null && originalPath != _imagePath) {
      unawaited(_imageStore.deleteImage(originalPath));
    }
    if (mounted) {
      Navigator.of(context).pop(savedShoe);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _imagePickerClient.pickGalleryImage();
    if (picked == null || !mounted) {
      return;
    }
    final currentImagePath = _imagePath;
    final savedPath = await _imageStore.saveShoeImage(picked);
    if (!mounted) {
      unawaited(_imageStore.deleteImage(savedPath));
      return;
    }
    if (currentImagePath != null && currentImagePath != _originalImagePath) {
      await _imageStore.deleteImage(currentImagePath);
    }
    if (!mounted) {
      unawaited(_imageStore.deleteImage(savedPath));
      return;
    }
    setState(() {
      _imagePath = savedPath;
      _errorText = null;
    });
  }

  Future<void> _removeImage() async {
    final currentImagePath = _imagePath;
    if (currentImagePath != null && currentImagePath != _originalImagePath) {
      await _imageStore.deleteImage(currentImagePath);
    }
    if (mounted) {
      setState(() => _imagePath = null);
    }
  }

  Future<void> _syncDefaultShoe(
    RunShoe savedShoe,
    RunShoe? existing,
    String? defaultShoeId,
  ) async {
    if (_makeDefault && !savedShoe.retired) {
      await _settingsController.setDefaultShoeId(savedShoe.id);
      return;
    }
    if (existing != null && defaultShoeId == existing.id) {
      await _settingsController.setDefaultShoeId(null);
    }
  }
}

const _mutedStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w700,
);

const _errorStyle = TextStyle(
  color: AppColors.electricRed,
  fontWeight: FontWeight.w900,
);
