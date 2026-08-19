import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/cms_models.dart';
import '../../../../services/content_storage_service.dart';

class AdminCardEditorDialog extends StatefulWidget {
  const AdminCardEditorDialog({
    super.key,
    required this.kind,
    required this.card,
    required this.isNew,
    required this.onSave,
  });

  final CmsCardKind kind;
  final CmsCard card;
  final bool isNew;
  final Future<void> Function(
    CmsCard card,
    List<XFile> newImages,
    Set<String> removedPaths,
  )
  onSave;

  @override
  State<AdminCardEditorDialog> createState() => _AdminCardEditorDialogState();
}

class _AdminCardEditorDialogState extends State<AdminCardEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _storage = ContentStorageService();
  late final _titleRu = TextEditingController(text: widget.card.titleRu);
  late final _titleEn = TextEditingController(text: widget.card.titleEn);
  late final _priceRu = TextEditingController(text: widget.card.priceRu);
  late final _priceEn = TextEditingController(text: widget.card.priceEn);
  late final _descriptionRu = TextEditingController(
    text: widget.card.descriptionRu,
  );
  late final _descriptionEn = TextEditingController(
    text: widget.card.descriptionEn,
  );
  late final List<StoredMedia> _images = [...widget.card.images];
  final List<XFile> _newImages = [];
  final Set<String> _removedPaths = {};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final item in [
      _titleRu,
      _titleEn,
      _priceRu,
      _priceEn,
      _descriptionRu,
      _descriptionEn,
    ]) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _addImages() async {
    final files = await _storage.pickImages();
    if (files.isEmpty) return;
    if (_images.length + _newImages.length + files.length > 10) {
      setState(() => _error = 'Можно добавить не более 10 изображений.');
      return;
    }
    setState(() {
      _newImages.addAll(files);
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_images.isEmpty && _newImages.isEmpty) {
      setState(() => _error = 'Добавьте хотя бы одно изображение.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        widget.card.copyWith(
          titleRu: _titleRu.text.trim(),
          titleEn: _titleEn.text.trim(),
          priceRu: _priceRu.text.trim(),
          priceEn: _priceEn.text.trim(),
          descriptionRu: _descriptionRu.text.trim(),
          descriptionEn: _descriptionEn.text.trim(),
          images: _images,
        ),
        _newImages,
        _removedPaths,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Не удалось сохранить карточку.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.isNew ? 'Добавить карточку' : 'Редактировать карточку'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_titleRu, 'Название (RU)', required: true),
              _field(_titleEn, 'Название (EN)'),
              _field(_priceRu, 'Стоимость (RU)'),
              _field(_priceEn, 'Стоимость (EN)'),
              _field(_descriptionRu, 'Описание (RU)', required: true, lines: 4),
              _field(_descriptionEn, 'Описание (EN)', lines: 4),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Изображения (${_images.length + _newImages.length}/10)',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _addImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final image in _images)
                    _ExistingImage(
                      image: image,
                      onDelete: _saving
                          ? null
                          : () => setState(() {
                              _images.remove(image);
                              _removedPaths.add(image.storagePath);
                            }),
                    ),
                  for (var index = 0; index < _newImages.length; index++)
                    Chip(
                      label: Text(
                        _newImages[index].name,
                        overflow: TextOverflow.ellipsis,
                      ),
                      deleteIcon: const Icon(Icons.close, color: Colors.red),
                      onDeleted: _saving
                          ? null
                          : () => setState(() => _newImages.removeAt(index)),
                    ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Сохранить'),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      minLines: lines,
      maxLines: lines == 1 ? 1 : 6,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'Обязательное поле.'
                : null
          : null,
    ),
  );
}

class _ExistingImage extends StatelessWidget {
  const _ExistingImage({required this.image, required this.onDelete});
  final StoredMedia image;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 96,
    height: 76,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.network(image.url, fit: BoxFit.cover),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: onDelete,
            color: Colors.red,
            icon: const Icon(Icons.close),
            tooltip: 'Удалить изображение',
          ),
        ),
      ],
    ),
  );
}
