import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/site_contact.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/boat.dart';
import '../../../models/google_reviews.dart';
import '../../../models/media_content.dart';
import '../../../models/tour.dart';
import '../../../services/analytics_service.dart';
import '../../../services/content_repository.dart';
import '../../../services/google_reviews_service.dart';
import 'widgets/content_detail_dialog.dart';

const _headerOffset = 96.0;
const _googleReviewTextStyle = TextStyle(
  fontFamilyFallback: ['NotoSansThai', 'NotoColorEmoji'],
);

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.repository, this.googleReviewsService});

  final ContentRepository? repository;
  final GoogleReviewsService? googleReviewsService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ContentRepository _repository =
      widget.repository ?? ContentRepository();
  late final GoogleReviewsService _googleReviewsService =
      widget.googleReviewsService ?? FirebaseGoogleReviewsService();
  final _scrollController = ScrollController();
  final _toursKey = GlobalKey();
  final _whyKey = GlobalKey();
  final _fleetKey = GlobalKey();
  final _contactKey = GlobalKey();
  late Future<List<Boat>> _boats = _repository.fetchPublishedBoats();
  late Future<List<Tour>> _tours = _repository.fetchPublishedTours();
  late Future<List<MediaContent>> _media = _repository
      .fetchPublishedMediaContent();
  Future<GoogleReviewsData?>? _reviews;
  String? _reviewsLanguage;
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateHeaderState);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateHeaderState)
      ..dispose();
    super.dispose();
  }

  void _updateHeaderState() {
    final value = _scrollController.hasClients && _scrollController.offset > 8;
    if (value != _hasScrolled && mounted) setState(() => _hasScrolled = value);
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final target = key.currentContext;
    if (target == null || !_scrollController.hasClients) return;

    final renderObject = target.findRenderObject();
    if (renderObject == null) return;

    final viewport = RenderAbstractViewport.of(renderObject);
    final position = _scrollController.position;

    final revealOffset = viewport.getOffsetToReveal(renderObject, 0).offset;

    final targetOffset = (revealOffset - _headerOffset)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();

    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _boats = _repository.fetchPublishedBoats();
      _tours = _repository.fetchPublishedTours();
      _media = _repository.fetchPublishedMediaContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.strings.locale.languageCode;
    if (_reviewsLanguage != languageCode) {
      _reviewsLanguage = languageCode;
      _reviews = _googleReviewsService.fetchReviews(languageCode: languageCode);
    }
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _Hero(
                    onTours: () => _scrollTo(_toursKey),
                    onCharter: () => _scrollTo(_fleetKey),
                  ),
                ),
                SliverToBoxAdapter(child: _About()),
                SliverToBoxAdapter(key: _whyKey, child: _WhyNarayana()),
                SliverToBoxAdapter(
                  key: _toursKey,
                  child: _AsyncTours(future: _tours),
                ),
                SliverToBoxAdapter(
                  key: _fleetKey,
                  child: _AsyncFleet(future: _boats),
                ),
                SliverToBoxAdapter(child: _MediaContentSection(future: _media)),
                const SliverToBoxAdapter(child: _B2B()),
                SliverToBoxAdapter(child: _GoogleReviews(future: _reviews!)),
                SliverToBoxAdapter(
                  key: _contactKey,
                  child: _Contact(reviewsFuture: _reviews!),
                ),
              ],
            ),
          ),
          _StickyHeader(
            hasScrolled: _hasScrolled,
            onTours: () => _scrollTo(_toursKey),
            onWhyUs: () => _scrollTo(_whyKey),
            onFleet: () => _scrollTo(_fleetKey),
            onBook: () => _scrollTo(_contactKey),
          ),
        ],
      ),
    );
  }
}

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.hasScrolled,
    required this.onTours,
    required this.onWhyUs,
    required this.onFleet,
    required this.onBook,
  });

  final bool hasScrolled;
  final VoidCallback onTours;
  final VoidCallback onWhyUs;
  final VoidCallback onFleet;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: hasScrolled
            ? AppTheme.navy.withValues(alpha: .88)
            : Colors.transparent,
        boxShadow: hasScrolled
            ? const [BoxShadow(color: Colors.black26, blurRadius: 18)]
            : null,
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: hasScrolled ? 10 : 0,
            sigmaY: hasScrolled ? 10 : 0,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                pageGutter(context),
                14,
                pageGutter(context),
                14,
              ),
              child: _Nav(
                onTours: onTours,
                onWhyUs: onWhyUs,
                onFleet: onFleet,
                onBook: onBook,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onTours, required this.onCharter});

  final VoidCallback onTours;
  final VoidCallback onCharter;

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    final narrow = isNarrow(context);
    final strings = context.strings;
    return Container(
      constraints: BoxConstraints(
        minHeight: narrow
            ? 590
            : compact
            ? 620
            : 720,
      ),
      padding: EdgeInsets.fromLTRB(
        pageGutter(context),
        narrow
            ? 148
            : compact
            ? 166
            : 210,
        pageGutter(context),
        70,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.navy, AppTheme.sea, Color(0xFF2E8B99)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.heroEyebrow,
            style: const TextStyle(
              color: AppTheme.aqua,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.heroTitle,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: narrow
                  ? 38
                  : compact
                  ? 44
                  : 72,
              height: .98,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.heroServices,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 570,
            child: Text(
              strings.heroDescription,
              style: const TextStyle(
                color: Color(0xFFE4FAF8),
                fontSize: 18,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () {
                  AnalyticsService.cta('explore_tours');
                  onTours();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.aqua,
                  foregroundColor: AppTheme.navy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 17,
                  ),
                ),
                child: Text(strings.exploreTours),
              ),
              OutlinedButton(
                onPressed: () {
                  AnalyticsService.cta('private_charter');
                  onCharter();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 17,
                  ),
                ),
                child: Text(strings.privateCharter),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({
    required this.onTours,
    required this.onWhyUs,
    required this.onFleet,
    required this.onBook,
  });

  final VoidCallback onTours;
  final VoidCallback onWhyUs;
  final VoidCallback onFleet;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final controller = LocaleScope.controllerOf(context);
    final compact = MediaQuery.sizeOf(context).width < 960;
    final narrow = isNarrow(context);
    final actions = [
      _HeaderAction(strings.toursNav, onTours),
      _HeaderAction(strings.whyUs, onWhyUs),
      _HeaderAction(strings.ourFleetNav, onFleet),
    ];
    return Row(
      children: [
        _BrandBlock(compact: compact, narrow: narrow),

        const Spacer(),

        if (compact) ...[
          _LanguageSelector(
            controller: controller,
            compact: true,
            narrow: narrow,
          ),
          SizedBox(width: narrow ? 2 : 6),
          _MobileNavigationMenu(
            tooltip: strings.openNavigation,
            actions: [...actions, _HeaderAction(strings.bookNow, onBook)],
          ),
        ] else ...[
          _LanguageSelector(controller: controller),
          const SizedBox(width: 8),
          for (final action in actions)
            TextButton(
              onPressed: action.onTap,
              style: _headerLinkStyle,
              child: Text(action.label),
            ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onBook,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.aqua,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            ),
            child: Text(strings.bookNow),
          ),
        ],
      ],
    );
  }

  static final _headerLinkStyle = TextButton.styleFrom(
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );
}

class _HeaderAction {
  const _HeaderAction(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
}

class _MobileNavigationMenu extends StatefulWidget {
  const _MobileNavigationMenu({required this.tooltip, required this.actions});

  final String tooltip;
  final List<_HeaderAction> actions;

  @override
  State<_MobileNavigationMenu> createState() => _MobileNavigationMenuState();
}

class _MobileNavigationMenuState extends State<_MobileNavigationMenu> {
  final _link = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  void _toggle() {
    if (_entry != null) {
      _close();
      return;
    }

    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 6),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 176,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white54),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.actions
                        .map(
                          (action) => _MobileNavigationOption(
                            action: action,
                            onSelected: _close,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _link,
    child: Tooltip(
      message: widget.tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.white12,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.menu, color: Colors.white),
          ),
        ),
      ),
    ),
  );
}

class _MobileNavigationOption extends StatelessWidget {
  const _MobileNavigationOption({
    required this.action,
    required this.onSelected,
  });

  final _HeaderAction action;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        onSelected();
        action.onTap();
      },
      hoverColor: Colors.white12,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            action.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _LanguageSelector extends StatefulWidget {
  const _LanguageSelector({
    required this.controller,
    this.compact = false,
    this.narrow = false,
  });
  final LocaleController controller;
  final bool compact;
  final bool narrow;

  @override
  State<_LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<_LanguageSelector> {
  final _link = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  void _toggle() {
    if (_entry != null) {
      _close();
      return;
    }
    final strings = context.strings;
    final width = _selectorWidth;
    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 6),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white54),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LanguageOption(
                        label: strings.englishLanguage,
                        selected: widget.controller.locale == AppLocale.english,
                        onTap: () async {
                          await widget.controller.setLocale(AppLocale.english);
                          _close();
                        },
                      ),
                      _LanguageOption(
                        label: strings.russianLanguage,
                        selected: widget.controller.locale == AppLocale.russian,
                        onTap: () async {
                          await widget.controller.setLocale(AppLocale.russian);
                          _close();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final active = widget.controller.locale == AppLocale.russian
        ? strings.russianLanguage
        : strings.englishLanguage;
    return CompositedTransformTarget(
      link: _link,
      child: SizedBox(
        width: _selectorWidth,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            hoverColor: Colors.white12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        active,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double get _selectorWidth => widget.compact
      ? widget.narrow
            ? 92
            : 112
      : 148;
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      hoverColor: Colors.white12,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.aqua : Colors.white,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, color: AppTheme.aqua, size: 17),
          ],
        ),
      ),
    ),
  );
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({this.compact = false, this.narrow = false});

  final bool compact;
  final bool narrow;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Narayana Marine',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo.png',
          width: narrow
              ? 30
              : compact
              ? 34
              : 44,
          height: narrow
              ? 30
              : compact
              ? 34
              : 44,
          fit: BoxFit.contain,
        ),

        if (!narrow) ...[
          SizedBox(width: compact ? 7 : 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NARAYANA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : 17,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: compact ? .8 : 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'MARINE',
                style: TextStyle(
                  color: AppTheme.aqua,
                  fontSize: compact ? 7 : 9,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: compact ? 2 : 3,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.color});
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    color: color,
    padding: EdgeInsets.symmetric(
      horizontal: pageGutter(context),
      vertical: isCompact(context) ? 60 : 92,
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: child,
    ),
  );
}

class _About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(strings.aboutEyebrow),
          const SizedBox(height: 14),
          Text(
            strings.aboutTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 18),
          SizedBox(width: 760, child: Text(strings.aboutBody)),
        ],
      ),
    );
  }
}

class _WhyNarayana extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return _Section(
      color: AppTheme.sand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(strings.whyEyebrow),
          const SizedBox(height: 14),
          Text(
            strings.whyTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: strings.whyValues
                .map(
                  (value) => Chip(
                    avatar: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Text(strings.whyNote),
        ],
      ),
    );
  }
}

class _AsyncTours extends StatelessWidget {
  const _AsyncTours({required this.future});
  final Future<List<Tour>> future;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return _Section(
      color: const Color(0xFFF7FAFA),
      child: FutureBuilder<List<Tour>>(
        future: future,
        builder: (context, snapshot) => _ContentState<Tour>(
          snapshot: snapshot,
          label: strings.toursEyebrow,
          title: strings.toursTitle,
          builder: (tour) => _TourCard(tour: tour),
        ),
      ),
    );
  }
}

class _AsyncFleet extends StatelessWidget {
  const _AsyncFleet({required this.future});
  final Future<List<Boat>> future;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return _Section(
      child: FutureBuilder<List<Boat>>(
        future: future,
        builder: (context, snapshot) => _ContentState<Boat>(
          snapshot: snapshot,
          label: strings.fleetEyebrow,
          title: strings.fleetTitle,
          builder: (boat) => _BoatCard(boat: boat),
        ),
      ),
    );
  }
}

class _ContentState<T> extends StatelessWidget {
  const _ContentState({
    required this.snapshot,
    required this.label,
    required this.title,
    required this.builder,
  });
  final AsyncSnapshot<List<T>> snapshot;
  final String label;
  final String title;
  final Widget Function(T item) builder;

  @override
  Widget build(BuildContext context) {
    final items = snapshot.data ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(label),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 30),
        if (snapshot.connectionState != ConnectionState.done)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          )
        else if (snapshot.hasError || items.isEmpty)
          const _DevelopmentState()
        else
          _ResponsiveGrid(
            itemCount: items.length,
            itemBuilder: (index) => builder(items[index]),
          ),
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.itemCount,
    required this.itemBuilder,
    this.aspectRatio = .83,
  });
  final int itemCount;
  final Widget Function(int index) itemBuilder;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 700
          ? 1
          : constraints.maxWidth < 1000
          ? 2
          : 3;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio: aspectRatio,
        ),
        itemBuilder: (context, index) => itemBuilder(index),
      );
    },
  );
}

class _BoatCard extends StatelessWidget {
  const _BoatCard({required this.boat});
  final Boat boat;
  @override
  Widget build(BuildContext context) => _ContentCard(
    imageUrl: boat.coverImage?.thumbnailUrl,
    title: boat.name,
    subtitle: [
      boat.subtitle,
      if (boat.lengthMeters != null) '${boat.lengthMeters} m',
      boat.capacityLabel,
    ].where((value) => value.isNotEmpty).join(' • '),
    description: boat.description,
    onTap: () => showBoatDetails(context, boat),
  );
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.tour});
  final Tour tour;
  @override
  Widget build(BuildContext context) => _ContentCard(
    imageUrl: tour.coverImage?.thumbnailUrl,
    title: tour.name,
    subtitle: tour.timingLabel ?? context.strings.earlyBirdAdventure,
    description: tour.shortDescription,
    onTap: () => showTourDetails(context, tour),
  );
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  });
  final String? imageUrl;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _NetworkMedia(url: imageUrl)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.sea,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Text(
                    context.strings.viewDetails,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _NetworkMedia extends StatelessWidget {
  const _NetworkMedia({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) => url == null || url!.isEmpty
      ? const _ImagePlaceholder()
      : Image.network(
          url!,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _ImagePlaceholder(),
        );
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppTheme.sea,
    child: Center(child: Icon(Icons.sailing, color: Colors.white, size: 54)),
  );
}

class _MediaContentSection extends StatelessWidget {
  const _MediaContentSection({required this.future});
  final Future<List<MediaContent>> future;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return _Section(
      color: AppTheme.sand,
      child: FutureBuilder<List<MediaContent>>(
        future: future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <MediaContent>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow(strings.contentEyebrow),
              const SizedBox(height: 14),
              Text(
                strings.contentTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 30),
                _ResponsiveGrid(
                  itemCount: items.length,
                  aspectRatio: 1.05,
                  itemBuilder: (index) => _MediaCard(item: items[index]),
                ),
              ] else if (snapshot.connectionState == ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.only(top: 22),
                  child: _DevelopmentState(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.item});
  final MediaContent item;

  Future<void> _open(BuildContext context) async {
    if (item.type == MediaContentType.video) {
      await launchUrl(
        Uri.parse(item.mediaUrl),
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960, maxHeight: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Image.network(
                  item.mediaUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                ),
              ),
              if (item
                      .titleFor(context.strings.locale.languageCode)
                      ?.isNotEmpty ??
                  false)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    item.titleFor(context.strings.locale.languageCode)!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = item.titleFor(context.strings.locale.languageCode);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _NetworkMedia(
              url: item.type == MediaContentType.video
                  ? item.thumbnailUrl
                  : item.mediaUrl,
            ),
            if (item.type == MediaContentType.video)
              const Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 34),
                ),
              ),
            if (title?.isNotEmpty ?? false)
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: double.infinity,
                  color: Colors.black45,
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _B2B extends StatelessWidget {
  const _B2B();
  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return _Section(
      color: AppTheme.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(strings.b2bEyebrow, light: true),
          const SizedBox(height: 14),
          Text(
            strings.b2bTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 760,
            child: Text(
              strings.b2bBody,
              style: const TextStyle(color: Color(0xFFE4FAF8), fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleReviews extends StatelessWidget {
  const _GoogleReviews({required this.future});
  final Future<GoogleReviewsData?> future;

  @override
  Widget build(BuildContext context) => FutureBuilder<GoogleReviewsData?>(
    future: future,
    builder: (context, snapshot) {
      final data = snapshot.data;
      final strings = context.strings;
      return _Section(
        color: AppTheme.sand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Eyebrow(strings.reviewsEyebrow),
            const SizedBox(height: 14),
            Text(
              strings.reviewsTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            if (data == null || data.rating <= 0)
              SizedBox(width: 650, child: Text(strings.reviewsUnavailable))
            else ...[
              _GoogleRating(data: data),
              if (data.reviews.isNotEmpty) ...[
                const SizedBox(height: 22),
                _GoogleReviewCards(reviews: data.reviews),
              ],
            ],
            const SizedBox(height: 24),
            _LinkButton(
              label: strings.readAllReviews,
              uri: SiteContact.googleMapsUri,
              event: 'google_reviews',
            ),
          ],
        ),
      );
    },
  );
}

class _GoogleRating extends StatelessWidget {
  const _GoogleRating({required this.data});
  final GoogleReviewsData data;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _RatingStars(rating: data.rating),
      const SizedBox(width: 10),
      Text(
        data.rating.toStringAsFixed(1),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ],
  );
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});
  final double rating;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      final value = rating - index;
      return Icon(
        value >= .75
            ? Icons.star
            : value >= .25
            ? Icons.star_half
            : Icons.star_border,
        color: const Color(0xFFE0A63A),
        size: 21,
      );
    }),
  );
}

class _GoogleReviewCards extends StatelessWidget {
  const _GoogleReviewCards({required this.reviews});
  final List<GoogleReview> reviews;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 16,
      runSpacing: 16,
      children: reviews
          .map(
            (review) => SizedBox(
              width: constraints.maxWidth < 400 ? constraints.maxWidth : 360,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _GoogleReviewAvatar(authorName: review.authorName),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              review.authorName,
                              style: _googleReviewTextStyle.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _RatingStars(rating: review.rating),
                      if (review.relativeDate?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            review.relativeDate!,
                            style: _googleReviewTextStyle,
                          ),
                        ),
                      if (review.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            review.text,
                            style: _googleReviewTextStyle,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          context.strings.reviewFromGoogle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _GoogleReviewAvatar extends StatelessWidget {
  const _GoogleReviewAvatar({required this.authorName});

  final String authorName;

  @override
  Widget build(BuildContext context) {
    final trimmedName = authorName.trim();
    final initial = trimmedName.isEmpty
        ? '?'
        : String.fromCharCode(trimmedName.runes.first).toUpperCase();
    return CircleAvatar(
      backgroundColor: AppTheme.sea,
      child: Text(
        initial,
        style: _googleReviewTextStyle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.reviewsFuture});
  final Future<GoogleReviewsData?> reviewsFuture;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Eyebrow(strings.contactEyebrow),
          const SizedBox(height: 14),
          Text(
            strings.contactTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          FutureBuilder<GoogleReviewsData?>(
            future: reviewsFuture,
            builder: (context, snapshot) =>
                _LocationCard(verifiedAddress: snapshot.data?.formattedAddress),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ContactAction(
                  icon: const FaIcon(FontAwesomeIcons.instagram, size: 20),
                  label: 'Instagram',
                  onTap: () => _launch(SiteContact.instagramUri),
                ),
                _ContactAction(
                  icon: const FaIcon(FontAwesomeIcons.facebookF, size: 20),
                  label: 'Facebook',
                  onTap: () => _launch(SiteContact.facebookUri),
                ),
                const SizedBox(height: 20),
                _ContactLabel(label: strings.emailLabel),
                _TextAction(
                  label: SiteContact.primaryEmail,
                  onTap: () => _launch(SiteContact.emailUri),
                ),
                _TextAction(
                  label: SiteContact.secondaryEmail,
                  onTap: () => _launch(SiteContact.secondaryEmailUri),
                ),
                const SizedBox(height: 20),
                _ContactLabel(label: strings.whatsappLabel),
                _TextAction(
                  label: SiteContact.phone,
                  onTap: () => _launch(SiteContact.whatsappUri),
                ),
                const SizedBox(height: 20),
                _ContactLabel(label: strings.lineLabel),
                _TextAction(
                  label: SiteContact.phone,
                  onTap: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: SiteContact.phone),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.numberCopied)),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({this.verifiedAddress});
  final String? verifiedAddress;
  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final hasVerifiedAddress = verifiedAddress?.isNotEmpty ?? false;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Card(
        child: InkWell(
          onTap: () async {
            await AnalyticsService.cta('google_maps_location');
            await launchUrl(
              SiteContact.googleMapsUri,
              mode: LaunchMode.externalApplication,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.sea,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.ourAddress,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(verifiedAddress ?? SiteContact.address),
                      const SizedBox(height: 4),
                      const Text(SiteContact.location),
                      if (!hasVerifiedAddress) ...[
                        const SizedBox(height: 4),
                        Text(
                          strings.addressNeedsVerification,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        strings.openInGoogleMaps,
                        style: const TextStyle(
                          color: AppTheme.sea,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            IconTheme(
              data: const IconThemeData(color: AppTheme.sea),
              child: icon,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );
}

class _ContactLabel extends StatelessWidget {
  const _ContactLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(color: AppTheme.sea, fontWeight: FontWeight.w800),
    ),
  );
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          decoration: TextDecoration.underline,
          decorationColor: Colors.black,
        ),
      ),
    ),
  );
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.uri,
    required this.event,
  });
  final String label;
  final Uri uri;
  final String event;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: () async {
      await AnalyticsService.cta(event);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    },
    child: Text(label),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.value, {this.light = false});
  final String value;
  final bool light;
  @override
  Widget build(BuildContext context) => Text(
    value,
    style: TextStyle(
      color: light ? AppTheme.aqua : AppTheme.sea,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.6,
    ),
  );
}

class _DevelopmentState extends StatelessWidget {
  const _DevelopmentState();
  @override
  Widget build(BuildContext context) => Text(
    context.strings.sectionInDevelopment,
    style: const TextStyle(color: Colors.black54),
  );
}
