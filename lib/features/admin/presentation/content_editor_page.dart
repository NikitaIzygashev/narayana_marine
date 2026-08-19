import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../models/boat.dart';
import '../../../models/content_image.dart';
import '../../../models/tour.dart';
import '../../../services/content_repository.dart';
import '../../../services/image_upload_service.dart';
import 'image_manager.dart';

class ContentEditorPage extends StatefulWidget {
  const ContentEditorPage({super.key, this.boat, this.tour, this.isBoat = true})
    : assert(boat == null || tour == null);
  final Boat? boat;
  final Tour? tour;
  final bool isBoat;

  @override
  State<ContentEditorPage> createState() => _ContentEditorPageState();
}

class _ContentEditorPageState extends State<ContentEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ContentRepository();
  final _id = TextEditingController();
  final _name = TextEditingController();
  final _subtitle = TextEditingController();
  final _description = TextEditingController();
  final _length = TextEditingController();
  final _capacity = TextEditingController();
  final _specifications = TextEditingController();
  final _shortDescription = TextEditingController();
  final _destinations = TextEditingController();
  final _highlights = TextEditingController();
  final _timing = TextEditingController();
  final _itinerary = TextEditingController();
  final _inclusions = TextEditingController();
  final _price = TextEditingController();
  late bool _isBoat;
  late bool _isNew;
  Boat? _boat;
  Tour? _tour;
  bool _published = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isBoat = widget.boat != null
        ? true
        : (widget.tour != null ? false : widget.isBoat);
    _boat = widget.boat;
    _tour = widget.tour;
    _isNew = _boat == null && _tour == null;
    if (_boat != null) _populateBoat(_boat!);
    if (_tour != null) _populateTour(_tour!);
  }

  void _populateBoat(Boat value) {
    _id.text = value.id;
    _name.text = value.name;
    _subtitle.text = value.subtitle;
    _description.text = value.description;
    _length.text = value.lengthMeters?.toString() ?? '';
    _capacity.text = value.capacityLabel;
    _specifications.text = value.specifications
        .map((item) => '${item['label']}: ${item['value']}')
        .join('\n');
    _published = value.isPublished;
  }

  void _populateTour(Tour value) {
    _id.text = value.id;
    _name.text = value.name;
    _shortDescription.text = value.shortDescription;
    _description.text = value.fullDescription;
    _destinations.text = value.destinations.join('\n');
    _highlights.text = value.highlights.join('\n');
    _timing.text = value.timingLabel ?? '';
    _itinerary.text = value.itinerary
        .map(
          (item) =>
              '${item['time'] ?? ''} | ${item['title'] ?? ''} | ${item['description'] ?? ''}',
        )
        .join('\n');
    _inclusions.text = value.inclusions.join('\n');
    _price.text = value.priceLabel ?? '';
    _published = value.isPublished;
  }

  @override
  void dispose() {
    for (final controller in [
      _id,
      _name,
      _subtitle,
      _description,
      _length,
      _capacity,
      _specifications,
      _shortDescription,
      _destinations,
      _highlights,
      _timing,
      _itinerary,
      _inclusions,
      _price,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _stableId() => _id.text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  List<String> _lines(TextEditingController controller) => controller.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  List<Map<String, String>> _pairs(TextEditingController controller) =>
      _lines(controller)
          .map((line) {
            final split = line.split(':');
            return {
              'label': split.first.trim(),
              'value': split.skip(1).join(':').trim(),
            };
          })
          .where(
            (item) => item['label']!.isNotEmpty && item['value']!.isNotEmpty,
          )
          .toList();
  List<Map<String, String>> _itineraryItems() => _lines(_itinerary)
      .map((line) {
        final split = line.split('|').map((item) => item.trim()).toList();
        return {
          'time': split.isEmpty ? '' : split[0],
          'title': split.length > 1 ? split[1] : '',
          'description': split.length > 2 ? split.skip(2).join(' | ') : '',
        };
      })
      .where((item) => item['title']!.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final id = _isNew ? _stableId() : (_boat?.id ?? _tour!.id);
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(id)) {
      setState(() => _error = context.strings.invalidStableId);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isBoat) {
        final value = Boat(
          id: id,
          name: _name.text.trim(),
          subtitle: _subtitle.text.trim(),
          description: _description.text.trim(),
          lengthMeters: double.tryParse(_length.text.trim()),
          capacityLabel: _capacity.text.trim(),
          specifications: _pairs(_specifications),
          gallery: _boat?.gallery ?? const [],
          coverImageId: _boat?.coverImageId,
          isPublished: _published,
          sortOrder: _boat?.sortOrder ?? 10,
        );
        await _repository.saveBoat(value, isNew: _isNew);
        _boat = value;
      } else {
        final value = Tour(
          id: id,
          name: _name.text.trim(),
          shortDescription: _shortDescription.text.trim(),
          fullDescription: _description.text.trim(),
          destinations: _lines(_destinations),
          highlights: _lines(_highlights),
          timingLabel: _timing.text.trim().isEmpty ? null : _timing.text.trim(),
          itinerary: _itineraryItems(),
          inclusions: _lines(_inclusions),
          priceLabel: _price.text.trim().isEmpty ? null : _price.text.trim(),
          gallery: _tour?.gallery ?? const [],
          coverImageId: _tour?.coverImageId,
          isPublished: _published,
          sortOrder: _tour?.sortOrder ?? 10,
        );
        await _repository.saveTour(value, isNew: _isNew);
        _tour = value;
      }
      if (mounted) {
        setState(() {
          _isNew = false;
          _id.text = id;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.strings.contentSaved)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.strings.couldNotSaveContent);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _galleryChanged(
    List<ContentImage> gallery,
    String? coverImageId,
  ) async {
    if (_isNew) {
      return;
    }
    if (_isBoat) {
      await _repository.updateBoatGallery(_boat!.id, gallery, coverImageId);
      if (mounted) {
        setState(
          () => _boat = _boat!.copyWith(
            gallery: gallery,
            coverImageId: coverImageId,
            clearCover: coverImageId == null,
          ),
        );
      }
    } else {
      await _repository.updateTourGallery(_tour!.id, gallery, coverImageId);
      if (mounted) {
        setState(
          () => _tour = _tour!.copyWith(
            gallery: gallery,
            coverImageId: coverImageId,
            clearCover: coverImageId == null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final title = strings.contentEditorTitle(isNew: _isNew, isBoat: _isBoat);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(strings.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _heading(strings.identity),
            TextFormField(
              controller: _id,
              enabled: _isNew,
              decoration: InputDecoration(labelText: strings.stableIdLabel),
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.requiredField
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: strings.name),
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.requiredField
                  : null,
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.publishedActive),
              subtitle: Text(strings.publishedHint),
              value: _published,
              onChanged: (value) => setState(() => _published = value),
            ),
            const Divider(height: 42),
            if (_isBoat) ..._boatFields() else ..._tourFields(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : Text(strings.saveContent),
            ),
            const SizedBox(height: 34),
            const Divider(),
            if (_isNew)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(strings.saveBeforeGallery),
              )
            else
              ImageManager(
                contentId: _boat?.id ?? _tour!.id,
                kind: _isBoat ? ContentKind.boats : ContentKind.tours,
                gallery: _boat?.gallery ?? _tour!.gallery,
                coverImageId: _boat?.coverImageId ?? _tour!.coverImageId,
                onChanged: _galleryChanged,
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _boatFields() {
    final strings = context.strings;
    return [
      _heading(strings.boatDetails),
      TextFormField(
        controller: _subtitle,
        decoration: InputDecoration(labelText: strings.subtitleType),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _description,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(labelText: strings.description),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _length,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: strings.lengthOptional),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _capacity,
        decoration: InputDecoration(labelText: strings.capacityLabel),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _specifications,
        minLines: 3,
        maxLines: 8,
        decoration: InputDecoration(
          labelText: strings.specifications,
          helperText: strings.onePerLineLabelValue,
        ),
      ),
    ];
  }

  List<Widget> _tourFields() {
    final strings = context.strings;
    return [
      _heading(strings.experienceDetails),
      TextFormField(
        controller: _shortDescription,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(labelText: strings.shortDescription),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _description,
        minLines: 4,
        maxLines: 8,
        decoration: InputDecoration(labelText: strings.fullDescription),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _destinations,
        minLines: 2,
        maxLines: 6,
        decoration: InputDecoration(
          labelText: strings.destinations,
          helperText: strings.onePerLine,
        ),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _highlights,
        minLines: 2,
        maxLines: 6,
        decoration: InputDecoration(
          labelText: strings.highlights,
          helperText: strings.onePerLine,
        ),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _timing,
        decoration: InputDecoration(labelText: strings.timingLabelOptional),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _itinerary,
        minLines: 3,
        maxLines: 8,
        decoration: InputDecoration(
          labelText: strings.itinerary,
          helperText: strings.onePerLineItinerary,
        ),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _inclusions,
        minLines: 2,
        maxLines: 6,
        decoration: InputDecoration(
          labelText: strings.inclusions,
          helperText: strings.onePerLine,
        ),
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _price,
        decoration: InputDecoration(labelText: strings.priceLabelOptional),
      ),
    ];
  }

  Widget _heading(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(value, style: Theme.of(context).textTheme.titleLarge),
  );
}
