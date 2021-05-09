import 'package:rocket_chat_connector_flutter/services/message_service.dart';
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rc;

Uri rocketServerUri = Uri();

void setServerUri(_serverUri) => rocketServerUri = _serverUri;

DateTime? jsonToDateTime(json) => json != null
    ? (json is String
        ? DateTime.parse(json).toUtc()
        : DateTime.fromMillisecondsSinceEpoch(json['\$date']! is String
              ? int.parse(json['\$date'])
              : json['\$date'], isUtc: true)
      )
    : null;

UserService getUserService() {
      final rc.HttpService rocketHttpService = rc.HttpService(rocketServerUri);
      return UserService(rocketHttpService);
}

MessageService getMessageService() {
      final rc.HttpService rocketHttpService = rc.HttpService(rocketServerUri);
      return MessageService(rocketHttpService);
}

