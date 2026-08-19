import 'package:flutter/material.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../models/boat.dart';
import '../../../../models/content_image.dart';
import '../../../../models/tour.dart';
import '../../../../services/analytics_service.dart';

Future<void> showBoatDetails(BuildContext context, Boat boat) async {
  await AnalyticsService.detailOpen('boat');
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => _ContentDetailDialog(
      title: boat.name,
      subtitle: boat.subtitle,
      description: boat.description,
      gallery: boat.gallery,
      facts: [
        if (boat.lengthMeters != null)
          '${context.strings.length}: ${boat.lengthMeters} m',
        if (boat.capacityLabel.isNotEmpty) boat.capacityLabel,
        ...boat.specifications.map(
          (item) => '${item['label']}: ${item['value']}',
        ),
      ],
    ),
  );
}

Future<void> showTourDetails(BuildContext context, Tour tour) async {
  await AnalyticsService.detailOpen('tour');
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => _ContentDetailDialog(
      title: tour.name,
      subtitle: tour.timingLabel ?? context.strings.andamanSeaExperience,
      description: tour.fullDescription.isEmpty
          ? tour.shortDescription
          : tour.fullDescription,
      gallery: tour.gallery,
      facts: [
        ...tour.destinations,
        ...tour.highlights,
        ...tour.inclusions.map((item) => '${context.strings.included}: $item'),
        if (tour.priceLabel?.isNotEmpty ?? false) tour.priceLabel!,
      ],
    ),
  );
}

class _ContentDetailDialog extends StatefulWidget {
  const _ContentDetailDialog({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gallery,
    required this.facts,
  });

  final String title;
  final String subtitle;
  final String description;
  final List<ContentImage> gallery;
  final List<String> facts;

  @override
  State<_ContentDetailDialog> createState() => _ContentDetailDialogState();
}

class _ContentDetailDialogState extends State<_ContentDetailDialog> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: width < 700 ? 720 : 760,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Gallery(
                images: widget.gallery,
                index: _index,
                onChanged: (value) => setState(() => _index = value),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: context.strings.closeDetails,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    if (widget.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                    if (widget.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(widget.description),
                    ],
                    if (widget.facts.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.facts
                            .where((fact) => fact.isNotEmpty)
                            .map((fact) => Chip(label: Text(fact)))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.images,
    required this.index,
    required this.onChanged,
  });

  final List<ContentImage> images;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 300,
        color: const Color(0xFF0B6774),
        alignment: Alignment.center,
        child: const Icon(Icons.sailing, color: Colors.white, size: 70),
      );
    }
    return SizedBox(
      height: 360,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: onChanged,
            itemBuilder: (context, item) => Image.network(
              images[item].displayUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFF0B6774),
                child: Center(
                  child: Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  '${index + 1} / ${images.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
