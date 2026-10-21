import 'dart:async';

import 'package:app_links/app_links.dart';

import '../../utils/app_logger.dart';
import '../deep_link_service.dart';

/// [DeepLinkService] trên `app_links` 6.x: `uriLinkStream` phát cả link khởi
/// động (cold start) lẫn link mới (warm start, `onNewIntent` nhờ singleTop).
class AppLinksDeepLinkService implements DeepLinkService {
  AppLinksDeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream.handleError((Object error) {
        AppLogger.w('DeepLinkService', 'Deeplink stream error', error);
      });
}
