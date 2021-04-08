import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;

final Uri serverUri = Uri.parse("https://chat.smallet.co");
final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);

