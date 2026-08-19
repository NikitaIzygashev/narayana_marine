import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_strings.dart';

Future<void> showFullscreenImageViewer(
  BuildContext context, {
  required List<String> imageUrls,
  int initialIndex = 0,
}) {
  if (imageUrls.isEmpty) return Future.value();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.strings.closeImageViewer,
    barrierColor: Colors.black87,
    pageBuilder: (context, _, _) =>
        FullscreenImageViewer(imageUrls: imageUrls, initialIndex: initialIndex),
  );
}

class FullscreenImageViewer extends StatefulWidget {
  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _goTo(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= widget.imageUrls.length) return;
    _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final hasMultipleImages = widget.imageUrls.length > 1;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        if (hasMultipleImages) ...{
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _goTo(_index - 1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _goTo(_index + 1),
        },
      },
      child: Focus(
        autofocus: true,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.imageUrls.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) => GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _close,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: GestureDetector(
                            onTap: () {},
                            child: Image.network(
                              widget.imageUrls[index],
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              errorBuilder: (_, _, _) =>
                                  const _ViewerFallback(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    tooltip: strings.closeImageViewer,
                    onPressed: _close,
                    icon: const Icon(Icons.close),
                  ),
                ),
                if (hasMultipleImages) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton.filled(
                        tooltip: strings.previousImage,
                        onPressed: _index == 0 ? null : () => _goTo(_index - 1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton.filled(
                        tooltip: strings.nextImage,
                        onPressed: _index == widget.imageUrls.length - 1
                            ? null
                            : () => _goTo(_index + 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            '${_index + 1} / ${widget.imageUrls.length}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewerFallback extends StatelessWidget {
  const _ViewerFallback();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 56),
  );
}
