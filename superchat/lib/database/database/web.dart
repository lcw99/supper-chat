import 'package:moor/moor_web.dart';

import '../chatdb.dart';

ChatDatabase constructDb({bool logStatements = false}) {
  return ChatDatabase(WebDatabase('chatdb', logStatements: logStatements));
}
