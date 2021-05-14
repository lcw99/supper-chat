import 'package:rocket_chat_connector_flutter/services/authentication_service.dart';
import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/services/message_service.dart';
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rc;

Uri rocketServerUri = Uri();

void setServerUri(_serverUri) => rocketServerUri = _serverUri;
final rc.HttpService rocketHttpService = rc.HttpService(rocketServerUri);

DateTime? jsonToDateTime(json) => json != null
    ? (json is String
        ? DateTime.parse(json).toUtc()
        : DateTime.fromMillisecondsSinceEpoch(json['\$date']! is String
              ? int.parse(json['\$date'])
              : json['\$date'], isUtc: true)
      )
    : null;

UserService getUserService() {
      return UserService(rocketHttpService);
}

MessageService getMessageService() {
      return MessageService(rocketHttpService);
}

ChannelService getChannelService() {
      return ChannelService(rocketHttpService);
}

AuthenticationService getAuthenticationService() {
      return AuthenticationService(rocketHttpService);
}
