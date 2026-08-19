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
import '../../../models/cms_models.dart';
import '../../../models/google_reviews.dart';
import '../../../services/analytics_service.dart';
import '../../../services/content_repository.dart';
import '../../../services/content_storage_service.dart';
import '../../../services/cms_content_service.dart';
import '../../../services/google_reviews_service.dart';
import '../../admin/presentation/widgets/admin_card_editor_dialog.dart';
import '../../../services/auth_service.dart';
import 'widgets/hero_video_background.dart';

const _headerOffset = 96.0;
const _googleReviewTextStyle = TextStyle(
  fontFamilyFallback: ['NotoSansThai', 'NotoColorEmoji'],
);

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.repository,
    this.googleReviewsService,
    this.adminMode = false,
    this.authService,
  });

  final ContentRepository? repository;
  final GoogleReviewsService? googleReviewsService;
  final bool adminMode;
  final AuthService? authService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ContentRepository _repository =
      widget.repository ?? ContentRepository();
  late final GoogleReviewsService _googleReviewsService =
      widget.googleReviewsService ?? FirebaseGoogleReviewsService();
  late final CmsContentService _cms = CmsContentService(
    repository: _repository,
  );
  final _storage = ContentStorageService();
  final _scrollController = ScrollController();
  final _toursKey = GlobalKey();
  final _whyKey = GlobalKey();
  final _fleetKey = GlobalKey();
  final _contactKey = GlobalKey();
  late Future<HeroMedia?> _hero = _repository.fetchHero();
  late Future<List<CmsCard>> _cmsTours = _repository.fetchCmsCards(
    CmsCardKind.tours,
    admin: widget.adminMode,
  );
  late Future<List<CmsCard>> _cmsFleet = _repository.fetchCmsCards(
    CmsCardKind.boats,
    admin: widget.adminMode,
  );
  late Future<List<GalleryItem>> _gallery = _repository.fetchGallery(
    admin: widget.adminMode,
  );
  late Future<List<ServiceItem>> _services = _repository.fetchServices();
  Future<GoogleReviewsData?>? _reviews;
  String? _reviewsLanguage;
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateHeaderState);
    if (widget.adminMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cms
            .cleanPendingDeletes()
            .then((_) {
              if (mounted) _refresh();
            })
            .catchError((_) {});
      });
    }
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
      _hero = _repository.fetchHero();
      _cmsTours = _repository.fetchCmsCards(
        CmsCardKind.tours,
        admin: widget.adminMode,
      );
      _cmsFleet = _repository.fetchCmsCards(
        CmsCardKind.boats,
        admin: widget.adminMode,
      );
      _gallery = _repository.fetchGallery(admin: widget.adminMode);
      _services = _repository.fetchServices();
    });
  }

  Future<void> _replaceHero(SiteMediaType type) async {
    final file = type == SiteMediaType.video
        ? await _storage.pickVideo()
        : await _storage.pickImage();
    if (file == null) return;
    try {
      await _cms.replaceHero(file);
      _refresh();
    } catch (_) {
      if (mounted) _message('Не удалось загрузить файл.');
    }
  }

  Future<void> _editCard(CmsCardKind kind, [CmsCard? existing]) async {
    final isNew = existing == null;
    final card =
        existing ??
        CmsCard(
          id: _repository.newId(kind),
          titleRu: '',
          titleEn: '',
          priceRu: '',
          priceEn: '',
          descriptionRu: '',
          descriptionEn: '',
          images: const [],
          order: DateTime.now().millisecondsSinceEpoch,
          isPublished: true,
          pendingStorageDeletes: const [],
        );
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => AdminCardEditorDialog(
        kind: kind,
        card: card,
        isNew: isNew,
        onSave: (next, files, removed) => _cms.saveCard(
          kind: kind,
          card: next,
          isNew: isNew,
          newImages: files,
          removedStoragePaths: removed,
        ),
      ),
    );
    if (changed == true) {
      _refresh();
    }
  }

  Future<void> _deleteCard(CmsCardKind kind, CmsCard card) async {
    if (!await _confirmDelete(
      'Удалить карточку?',
      'Файлы этой карточки также будут удалены с сервера.',
    )) {
      return;
    }
    try {
      await _cms.deleteCard(kind, card);
      _refresh();
    } catch (_) {
      if (mounted) {
        _message(
          'Не удалось удалить карточку. Очистка будет повторена при следующем входе.',
        );
      }
    }
  }

  Future<void> _addGallery() async {
    final current = await _gallery;
    if (current.length >= 12) {
      _message('Можно добавить не более 12 изображений.');
      return;
    }
    final file = await _storage.pickImage();
    if (file == null) {
      return;
    }
    try {
      await _cms.addGalleryImage(
        file: file,
        order: DateTime.now().millisecondsSinceEpoch,
      );
      _refresh();
    } catch (_) {
      if (mounted) {
        _message('Не удалось загрузить изображение.');
      }
    }
  }

  Future<void> _deleteGallery(GalleryItem item) async {
    if (!await _confirmDelete(
      'Удалить изображение?',
      'Файл также будет удалён с сервера.',
    )) {
      return;
    }
    try {
      await _cms.deleteGalleryItem(item);
      _refresh();
    } catch (_) {
      if (mounted) {
        _message('Не удалось удалить изображение.');
      }
    }
  }

  Future<void> _addService(String ru, String en) async {
    final value = ru.trim();
    if (value.isEmpty) {
      _message('Введите услугу.');
      return;
    }
    final existing = await _services;
    if (existing.any((item) => item.textRu.trim() == value)) {
      _message('Такая услуга уже существует.');
      return;
    }
    await _repository.saveService(
      ServiceItem(
        id: _repository.newServiceId(),
        textRu: value,
        textEn: en.trim(),
        order: DateTime.now().millisecondsSinceEpoch,
      ),
      isNew: true,
    );
    _refresh();
  }

  Future<void> _deleteService(ServiceItem item) async {
    try {
      await _repository.deleteService(item.id);
      _refresh();
    } catch (_) {
      if (mounted) _message('Не удалось удалить услугу.');
    }
  }

  Future<bool> _confirmDelete(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        ),
      ) ??
      false;

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

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
                  child: _AsyncHero(
                    future: _hero,
                    adminMode: widget.adminMode,
                    onReplace: _replaceHero,
                    onTours: () => _scrollTo(_toursKey),
                    onCharter: () => _scrollTo(_fleetKey),
                  ),
                ),
                SliverToBoxAdapter(child: _About()),
                SliverToBoxAdapter(
                  key: _whyKey,
                  child: _CmsWhyNarayana(
                    future: _services,
                    adminMode: widget.adminMode,
                    onAdd: _addService,
                    onDelete: _deleteService,
                  ),
                ),
                SliverToBoxAdapter(
                  key: _toursKey,
                  child: _CmsCardsSection(
                    future: _cmsTours,
                    kind: CmsCardKind.tours,
                    adminMode: widget.adminMode,
                    onAdd: () => _editCard(CmsCardKind.tours),
                    onEdit: (item) => _editCard(CmsCardKind.tours, item),
                    onDelete: (item) => _deleteCard(CmsCardKind.tours, item),
                  ),
                ),
                SliverToBoxAdapter(
                  key: _fleetKey,
                  child: _CmsCardsSection(
                    future: _cmsFleet,
                    kind: CmsCardKind.boats,
                    adminMode: widget.adminMode,
                    onAdd: () => _editCard(CmsCardKind.boats),
                    onEdit: (item) => _editCard(CmsCardKind.boats, item),
                    onDelete: (item) => _deleteCard(CmsCardKind.boats, item),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CmsGallerySection(
                    future: _gallery,
                    adminMode: widget.adminMode,
                    onAdd: _addGallery,
                    onDelete: _deleteGallery,
                  ),
                ),
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
          if (widget.adminMode)
            Positioned(
              right: 12,
              bottom: 12,
              child: FilledButton.icon(
                onPressed: widget.authService?.signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Выйти'),
              ),
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

class _AsyncHero extends StatelessWidget {
  const _AsyncHero({
    required this.future,
    required this.adminMode,
    required this.onReplace,
    required this.onTours,
    required this.onCharter,
  });

  final Future<HeroMedia?> future;
  final bool adminMode;
  final Future<void> Function(SiteMediaType type) onReplace;
  final VoidCallback onTours;
  final VoidCallback onCharter;

  @override
  Widget build(BuildContext context) => FutureBuilder<HeroMedia?>(
    future: future,
    builder: (context, snapshot) => _Hero(
      media: snapshot.data,
      adminMode: adminMode,
      onReplace: onReplace,
      onTours: onTours,
      onCharter: onCharter,
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.media,
    required this.adminMode,
    required this.onReplace,
    required this.onTours,
    required this.onCharter,
  });

  final HeroMedia? media;
  final bool adminMode;
  final Future<void> Function(SiteMediaType type) onReplace;
  final VoidCallback onTours;
  final VoidCallback onCharter;

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    final narrow = isNarrow(context);
    final strings = context.strings;
    final content = Container(
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
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.navy, AppTheme.sea, Color(0xFF2E8B99)],
              ),
            ),
          ),
        ),
        if (media?.media.type == SiteMediaType.image)
          Positioned.fill(
            child: Image.network(
              media!.media.url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.expand(),
            ),
          ),
        if (media?.media.type == SiteMediaType.video)
          Positioned.fill(child: HeroVideoBackground(url: media!.media.url)),
        if (media != null)
          const Positioned.fill(child: ColoredBox(color: Color(0x66000000))),
        content,
        if (adminMode)
          Positioned(
            right: pageGutter(context),
            bottom: 20,
            child: PopupMenuButton<SiteMediaType>(
              onSelected: onReplace,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: SiteMediaType.image,
                  child: Text('Загрузить изображение'),
                ),
                PopupMenuItem(
                  value: SiteMediaType.video,
                  child: Text('Загрузить видео'),
                ),
              ],
              child: IgnorePointer(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    media == null ? 'Загрузить файл' : 'Обновить файл',
                  ),
                ),
              ),
            ),
          ),
      ],
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

class _CmsWhyNarayana extends StatefulWidget {
  const _CmsWhyNarayana({
    required this.future,
    required this.adminMode,
    required this.onAdd,
    required this.onDelete,
  });
  final Future<List<ServiceItem>> future;
  final bool adminMode;
  final Future<void> Function(String ru, String en) onAdd;
  final Future<void> Function(ServiceItem item) onDelete;

  @override
  State<_CmsWhyNarayana> createState() => _CmsWhyNarayanaState();
}

class _CmsWhyNarayanaState extends State<_CmsWhyNarayana> {
  final _ru = TextEditingController();
  final _en = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ru.dispose();
    _en.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onAdd(_ru.text, _en.text);
      if (mounted) {
        _ru.clear();
        _en.clear();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return _Section(
      color: AppTheme.sand,
      child: FutureBuilder<List<ServiceItem>>(
        future: widget.future,
        builder: (context, snapshot) {
          final values = snapshot.data ?? const <ServiceItem>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Eyebrow(strings.whyEyebrow),
              const SizedBox(height: 14),
              Text(
                strings.whyTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (widget.adminMode) ...[
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final vertical = constraints.maxWidth < 620;
                    final ruField = TextField(
                      controller: _ru,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Услуга (RU)',
                      ),
                    );
                    final enField = TextField(
                      controller: _en,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                      decoration: const InputDecoration(
                        labelText: 'Service (EN), optional',
                      ),
                    );
                    final button = FilledButton.icon(
                      onPressed: _saving ? null : _add,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить услугу'),
                    );
                    return vertical
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ruField,
                              const SizedBox(height: 10),
                              enField,
                              const SizedBox(height: 10),
                              button,
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: ruField),
                              const SizedBox(width: 10),
                              Expanded(child: enField),
                              const SizedBox(width: 10),
                              button,
                            ],
                          );
                  },
                ),
              ],
              const SizedBox(height: 30),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (values.isEmpty)
                const _DevelopmentState()
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: values
                      .map(
                        (value) => Chip(
                          avatar: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: Text(
                            value.textFor(strings.locale.languageCode),
                          ),
                          deleteIcon: widget.adminMode
                              ? const Icon(Icons.close, color: Colors.red)
                              : null,
                          onDeleted: widget.adminMode
                              ? () => widget.onDelete(value)
                              : null,
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 18),
              Text(strings.whyNote),
            ],
          );
        },
      ),
    );
  }
}

class _CmsCardsSection extends StatelessWidget {
  const _CmsCardsSection({
    required this.future,
    required this.kind,
    required this.adminMode,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });
  final Future<List<CmsCard>> future;
  final CmsCardKind kind;
  final bool adminMode;
  final VoidCallback onAdd;
  final Future<void> Function(CmsCard item) onEdit;
  final Future<void> Function(CmsCard item) onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final tours = kind == CmsCardKind.tours;
    return _Section(
      color: tours ? const Color(0xFFF7FAFA) : null,
      child: FutureBuilder<List<CmsCard>>(
        future: future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <CmsCard>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Eyebrow(
                          tours ? strings.toursEyebrow : strings.fleetEyebrow,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          tours ? strings.toursTitle : strings.fleetTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  if (adminMode)
                    FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить карточку'),
                    ),
                ],
              ),
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
                  itemBuilder: (index) => _CmsContentCard(
                    item: items[index],
                    adminMode: adminMode,
                    onEdit: () => onEdit(items[index]),
                    onDelete: () => onDelete(items[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CmsContentCard extends StatelessWidget {
  const _CmsContentCard({
    required this.item,
    required this.adminMode,
    required this.onEdit,
    required this.onDelete,
  });
  final CmsCard item;
  final bool adminMode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final language = context.strings.locale.languageCode;
    return Stack(
      children: [
        _ContentCard(
          imageUrl: item.images.isEmpty ? null : item.images.first.url,
          title: item.titleFor(language),
          subtitle: item.priceFor(language),
          description: item.descriptionFor(language),
          onTap: () => _showCmsDetails(context, item, language),
        ),
        if (adminMode)
          Positioned(
            top: 6,
            right: 6,
            child: Wrap(
              spacing: 2,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    tooltip: 'Редактировать',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    tooltip: 'Удалить',
                    onPressed: onDelete,
                    color: Colors.red,
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _showCmsDetails(
    BuildContext context,
    CmsCard item,
    String language,
  ) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: PageView(
                children: item.images
                    .map(
                      (image) => Image.network(
                        image.url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                      ),
                    )
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.titleFor(language),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (item.priceFor(language).isNotEmpty)
                    Text(
                      item.priceFor(language),
                      style: const TextStyle(
                        color: AppTheme.sea,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (item.descriptionFor(language).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(item.descriptionFor(language)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CmsGallerySection extends StatelessWidget {
  const _CmsGallerySection({
    required this.future,
    required this.adminMode,
    required this.onAdd,
    required this.onDelete,
  });
  final Future<List<GalleryItem>> future;
  final bool adminMode;
  final VoidCallback onAdd;
  final Future<void> Function(GalleryItem item) onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return _Section(
      color: AppTheme.sand,
      child: FutureBuilder<List<GalleryItem>>(
        future: future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <GalleryItem>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Eyebrow(strings.contentEyebrow),
                        const SizedBox(height: 14),
                        Text(
                          strings.contentTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  if (adminMode)
                    FilledButton.icon(
                      onPressed: items.length >= 12 ? null : onAdd,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Добавить изображение'),
                    ),
                ],
              ),
              if (adminMode && items.length >= 12)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('Можно добавить не более 12 изображений.'),
                ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 30),
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(
                        right: index == items.length - 1 ? 0 : 16,
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.15,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                items[index].media.url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const _ImagePlaceholder(),
                              ),
                            ),
                            if (adminMode)
                              Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  onPressed: () => onDelete(items[index]),
                                  icon: const Icon(Icons.close),
                                  color: Colors.red,
                                  tooltip: 'Удалить изображение',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
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

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.itemCount, required this.itemBuilder});
  final int itemCount;
  final Widget Function(int index) itemBuilder;

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
          childAspectRatio: .83,
        ),
        itemBuilder: (context, index) => itemBuilder(index),
      );
    },
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
