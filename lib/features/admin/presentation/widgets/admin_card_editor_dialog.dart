import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../models/cms_models.dart';
import '../../../../services/cms_content_service.dart';
import '../../../../services/content_storage_service.dart';

class AdminCardEditorDialog extends StatefulWidget {
  const AdminCardEditorDialog({
    super.key,
    required this.kind,
    required this.card,
    required this.isNew,
    required this.onSave,
    this.pickImages,
  });

  final CmsCardKind kind;
  final CmsCard card;
  final bool isNew;
  final Future<void> Function(
    CmsCard card,
    List<CardImageInput> images,
    Set<String> removedPaths,
  )
  onSave;
  final Future<List<XFile>> Function()? pickImages;

  @override
  State<AdminCardEditorDialog> createState() => _AdminCardEditorDialogState();
}

enum _CardSaveAction { save, publish, unpublish }

class _AdminCardEditorDialogState extends State<AdminCardEditorDialog> {
  final _formKey = GlobalKey<FormState>();
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
  late final _order = TextEditingController(text: widget.card.order.toString());
  late final List<CardImageInput> _images = widget.card.images
      .map(CardImageInput.existing)
      .toList();
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
      _order,
    ]) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _addImages() async {
    final files =
        await (widget.pickImages?.call() ??
            ContentStorageService().pickImages());
    if (files.isEmpty) return;
    if (_images.length + files.length > 10) {
      setState(() => _error = context.strings.cardImageLimitReached);
      return;
    }
    setState(() {
      _images.addAll(files.map(CardImageInput.newFile));
      _error = null;
    });
  }

  Future<void> _replaceImage(int index) async {
    final file = await ContentStorageService().pickImage();
    if (file == null) return;
    setState(() {
      final existing = _images[index].existing;
      if (existing != null) _removedPaths.add(existing.storagePath);
      _images[index] = CardImageInput.newFile(file);
      _error = null;
    });
  }

  void _removeImage(int index) {
    setState(() {
      final existing = _images[index].existing;
      if (existing != null) _removedPaths.add(existing.storagePath);
      _images.removeAt(index);
    });
  }

  void _moveImage(int index, int offset) {
    final nextIndex = index + offset;
    if (nextIndex < 0 || nextIndex >= _images.length) return;
    setState(() {
      final item = _images.removeAt(index);
      _images.insert(nextIndex, item);
    });
  }

  CmsCardValidationIssue? _validationIssue(bool publish) {
    final card = _draftCard(isPublished: publish);
    final basicIssue = card.validationIssue(forPublish: false);
    if (basicIssue != null) return basicIssue;
    if (!publish) return null;
    if (card.titleRu.trim().isEmpty) {
      return CmsCardValidationIssue.titleRuRequired;
    }
    if (card.titleEn.trim().isEmpty) {
      return CmsCardValidationIssue.titleEnRequired;
    }
    if (card.descriptionRu.trim().isEmpty) {
      return CmsCardValidationIssue.descriptionRuRequired;
    }
    if (card.descriptionEn.trim().isEmpty) {
      return CmsCardValidationIssue.descriptionEnRequired;
    }
    if (_images.isEmpty) return CmsCardValidationIssue.imageRequired;
    return _images.length > 10
        ? CmsCardValidationIssue.imageLimitExceeded
        : null;
  }

  CmsCard _draftCard({required bool isPublished}) => widget.card.copyWith(
    titleRu: _titleRu.text.trim(),
    titleEn: _titleEn.text.trim(),
    priceRu: _priceRu.text.trim(),
    priceEn: _priceEn.text.trim(),
    descriptionRu: _descriptionRu.text.trim(),
    descriptionEn: _descriptionEn.text.trim(),
    images: _images
        .map((item) => item.existing)
        .whereType<StoredMedia>()
        .toList(),
    isPublished: isPublished,
    order: int.tryParse(_order.text.trim()) ?? widget.card.order,
  );

  Future<void> _save(_CardSaveAction action) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final nextPublished = switch (action) {
      _CardSaveAction.save => widget.card.isPublished,
      _CardSaveAction.publish => true,
      _CardSaveAction.unpublish => false,
    };
    final issue = _validationIssue(nextPublished);
    if (issue != null) {
      setState(() => _error = _validationMessage(issue));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        _draftCard(isPublished: nextPublished),
        List.unmodifiable(_images),
        Set.unmodifiable(_removedPaths),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      debugPrint('CMS card save failed: ${error.runtimeType}');
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _messageFor(Object error) {
    if (error is CmsCardValidationException) {
      return _validationMessage(error.issue);
    }
    if (error is ContentStorageException) {
      return _storageMessage(error.failure);
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' ||
        'unauthorized' ||
        'unauthenticated' => context.strings.cmsPermissionDenied,
        'unavailable' ||
        'network-request-failed' ||
        'retry-limit-exceeded' => context.strings.cmsNetworkError,
        _ => context.strings.cmsWriteError,
      };
    }
    return context.strings.cmsWriteError;
  }

  String _validationMessage(CmsCardValidationIssue issue) => switch (issue) {
    CmsCardValidationIssue.draftTitleRequired =>
      context.strings.cmsDraftTitleRequired,
    CmsCardValidationIssue.titleRuRequired =>
      context.strings.cmsTitleRuRequired,
    CmsCardValidationIssue.titleEnRequired =>
      context.strings.cmsTitleEnRequired,
    CmsCardValidationIssue.descriptionRuRequired =>
      context.strings.cmsDescriptionRuRequired,
    CmsCardValidationIssue.descriptionEnRequired =>
      context.strings.cmsDescriptionEnRequired,
    CmsCardValidationIssue.imageRequired => context.strings.cmsImageRequired,
    CmsCardValidationIssue.imageLimitExceeded =>
      context.strings.cardImageLimitReached,
    CmsCardValidationIssue.invalidImage => context.strings.cmsInvalidImage,
  };

  String _storageMessage(ContentStorageFailure failure) => switch (failure) {
    ContentStorageFailure.unsupportedType =>
      context.strings.cmsUnsupportedImageType,
    ContentStorageFailure.imageTooLarge => context.strings.cmsImageTooLarge,
    ContentStorageFailure.videoTooLarge => context.strings.cmsWriteError,
  };

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        Expanded(
          child: Text(
            widget.isNew ? context.strings.addCard : context.strings.editCard,
          ),
        ),
        _PublicationStatus(isPublished: widget.card.isPublished),
      ],
    ),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_titleRu, context.strings.titleRuLabel),
              _field(_titleEn, context.strings.titleEnLabel),
              _field(_priceRu, context.strings.priceRuLabel),
              _field(_priceEn, context.strings.priceEnLabel),
              _field(
                _descriptionRu,
                context.strings.descriptionRuLabel,
                lines: 4,
              ),
              _field(
                _descriptionEn,
                context.strings.descriptionEnLabel,
                lines: 4,
              ),
              _field(
                _order,
                context.strings.displayOrderLabel,
                keyboardType: TextInputType.number,
                validator: (value) => int.tryParse(value?.trim() ?? '') == null
                    ? context.strings.validOrderRequired
                    : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(context.strings.imagesCount(_images.length)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _addImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(context.strings.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(context.strings.imageOrderHint),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  _images.length,
                  (index) => _ImageInputTile(
                    input: _images[index],
                    isCover: index == 0,
                    canMoveEarlier: index > 0,
                    canMoveLater: index < _images.length - 1,
                    disabled: _saving,
                    onMoveEarlier: () => _moveImage(index, -1),
                    onMoveLater: () => _moveImage(index, 1),
                    onReplace: () => _replaceImage(index),
                    onDelete: () => _removeImage(index),
                  ),
                ),
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
        child: Text(context.strings.cancel),
      ),
      TextButton(
        onPressed: _saving ? null : () => _save(_CardSaveAction.save),
        child: Text(context.strings.save),
      ),
      if (widget.card.isPublished)
        OutlinedButton(
          onPressed: _saving ? null : () => _save(_CardSaveAction.unpublish),
          child: Text(context.strings.unpublish),
        )
      else
        FilledButton(
          onPressed: _saving ? null : () => _save(_CardSaveAction.publish),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.strings.publish),
        ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      minLines: lines,
      maxLines: lines == 1 ? 1 : 6,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    ),
  );
}

class _PublicationStatus extends StatelessWidget {
  const _PublicationStatus({required this.isPublished});
  final bool isPublished;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      isPublished
          ? context.strings.publishedStatus
          : context.strings.draftStatus,
    ),
    backgroundColor: isPublished ? const Color(0xFFD8F5EF) : null,
  );
}

class _ImageInputTile extends StatelessWidget {
  const _ImageInputTile({
    required this.input,
    required this.isCover,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.disabled,
    required this.onMoveEarlier,
    required this.onMoveLater,
    required this.onReplace,
    required this.onDelete,
  });

  final CardImageInput input;
  final bool isCover;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final bool disabled;
  final VoidCallback onMoveEarlier;
  final VoidCallback onMoveLater;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 128,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.35,
              child: input.existing == null
                  ? Center(
                      child: Text(
                        input.file!.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Image.network(input.existing!.url, fit: BoxFit.cover),
            ),
            if (isCover)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.strings.coverImage,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            Wrap(
              spacing: 0,
              children: [
                IconButton(
                  tooltip: context.strings.moveEarlier,
                  onPressed: disabled || !canMoveEarlier ? null : onMoveEarlier,
                  icon: const Icon(Icons.arrow_back, size: 18),
                ),
                IconButton(
                  tooltip: context.strings.moveLater,
                  onPressed: disabled || !canMoveLater ? null : onMoveLater,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                ),
                IconButton(
                  tooltip: context.strings.replaceImage,
                  onPressed: disabled ? null : onReplace,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                ),
                IconButton(
                  tooltip: context.strings.deleteImage,
                  onPressed: disabled ? null : onDelete,
                  color: Colors.red,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
