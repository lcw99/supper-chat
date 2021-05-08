export 'platform_depended_stub.dart'
  if (dart.library.io) 'platform_depended_io.dart'
  if (dart.library.html) 'platform_depended_web.dart';

