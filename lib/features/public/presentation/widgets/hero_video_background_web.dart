// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

class HeroVideoBackground extends StatefulWidget {
  const HeroVideoBackground({super.key, required this.url});
  final String url;

  @override
  State<HeroVideoBackground> createState() => _HeroVideoBackgroundState();
}

class _HeroVideoBackgroundState extends State<HeroVideoBackground> {
  late final String _viewType = 'hero-video-${Object().hashCode}';

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final video = html.VideoElement()
        ..src = widget.url
        ..autoplay = true
        ..muted = true
        ..loop = true
        ..controls = false
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      return video;
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
