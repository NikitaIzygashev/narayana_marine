import 'package:flutter/material.dart';

import '../../../models/content_image.dart';
import '../../../services/image_upload_service.dart';

class ImageManager extends StatefulWidget {
  const ImageManager({
    super.key,
    required this.contentId,
    required this.kind,
    required this.gallery,
    required this.coverImageId,
    required this.onChanged,
  });

  final String contentId;
  final ContentKind kind;
  final List<ContentImage> gallery;
  final String? coverImageId;
  final Future<void> Function(List<ContentImage> gallery, String? coverImageId)
  onChanged;

  @override
  State<ImageManager> createState() => _ImageManagerState();
}

class _ImageManagerState extends State<ImageManager> {
  final _service = ImageUploadService();
  bool _busy = false;
  String? _error;

  Future<void> _add() async {
    if (widget.gallery.length >= 10) {
      setState(
        () => _error = 'A boat or tour can have a maximum of 10 images.',
      );
      return;
    }
    final file = await _service.pickImage();
    if (file == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uploaded = await _service.upload(
        kind: widget.kind,
        contentId: widget.contentId,
        file: file,
      );
      final gallery = [...widget.gallery, uploaded];
      await widget.onChanged(gallery, widget.coverImageId ?? uploaded.id);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(ContentImage image) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.deleteImage(image);
      final gallery = widget.gallery
          .where((item) => item.id != image.id)
          .toList();
      final cover = widget.coverImageId == image.id
          ? (gallery.isEmpty ? null : gallery.first.id)
          : widget.coverImageId;
      await widget.onChanged(gallery, cover);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not delete image: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(ContentImage image, int offset) async {
    final oldIndex = widget.gallery.indexWhere((item) => item.id == image.id);
    final newIndex = oldIndex + offset;
    if (newIndex < 0 || newIndex >= widget.gallery.length) return;
    final gallery = [...widget.gallery];
    final item = gallery.removeAt(oldIndex);
    gallery.insert(newIndex, item);
    setState(() => _busy = true);
    try {
      await widget.onChanged(gallery, widget.coverImageId);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Gallery (${widget.gallery.length}/10)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _add,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Upload image'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'Uploads are converted to optimized JPEG display and thumbnail files.',
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      if (_busy)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: LinearProgressIndicator(),
        ),
      const SizedBox(height: 12),
      if (widget.gallery.isEmpty)
        const Text('No images uploaded yet.')
      else
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.gallery.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isCover = item.id == widget.coverImageId;
            return SizedBox(
              width: 180,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.4,
                      child: Image.network(
                        item.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: Colors.black12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        spacing: 2,
                        runSpacing: 2,
                        children: [
                          TextButton(
                            onPressed: _busy || isCover
                                ? null
                                : () =>
                                      widget.onChanged(widget.gallery, item.id),
                            child: Text(isCover ? 'Cover image' : 'Set cover'),
                          ),
                          IconButton(
                            tooltip: 'Move earlier',
                            onPressed: _busy || index == 0
                                ? null
                                : () => _move(item, -1),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          IconButton(
                            tooltip: 'Move later',
                            onPressed:
                                _busy || index == widget.gallery.length - 1
                                ? null
                                : () => _move(item, 1),
                            icon: const Icon(Icons.arrow_forward),
                          ),
                          IconButton(
                            tooltip: 'Delete image',
                            onPressed: _busy ? null : () => _delete(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
    ],
  );
}
