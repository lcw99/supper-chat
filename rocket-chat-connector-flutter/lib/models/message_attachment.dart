import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:rocket_chat_connector_flutter/models/message_attachment_field.dart';

import 'image_dimensions.dart';

class MessageAttachment {
  String? audioUrl;
  String? authorIcon;
  String? authorLink;
  String? authorName;
  bool? collapsed;
  String? color;
  List<MessageAttachmentField>? fields;
  String? imageUrl;
  String? messageLink;
  String? text;
  String? description;
  String? imagePreview;
  String? thumbUrl;
  String? title;
  String? titleLink;
  bool? titleLinkDownload;
  DateTime? ts;
  String? videoUrl;
  ImageDimensions? imageDimensions;
  String? type;

  MessageAttachment({
    this.audioUrl,
    this.authorIcon,
    this.authorLink,
    this.authorName,
    this.collapsed,
    this.color,
    this.fields,
    this.imageUrl,
    this.messageLink,
    this.text,
    this.description,
    this.imagePreview,
    this.thumbUrl,
    this.title,
    this.titleLink,
    this.titleLinkDownload,
    this.ts,
    this.videoUrl,
    this.imageDimensions,
    this.type,
  });

  MessageAttachment.fromMap(Map<String, dynamic> json) {
    if (json != null) {
      audioUrl = json['audio_url'];
      authorIcon = json['author_icon'];
      authorLink = json['author_link'];
      authorName = json['author_name'];
      collapsed = json['collapsed'];
      color = json['color'];

      if (json['fields'] != null) {
        List<dynamic> jsonList = json['fields'].runtimeType == String //
            ? jsonDecode(json['fields'])
            : json['fields'];
        fields = jsonList
            .where((json) => json != null)
            .map((json) => MessageAttachmentField.fromMap(json))
            .toList();
      } else {
        fields = null;
      }

      imageUrl = json['image_url'];
      messageLink = json['message_link'];
      text = json['text'];
      description = json['description'];
      imagePreview = json['image_preview'];
      thumbUrl = json['thumb_url'];
      title = json['title'];
      titleLink = json['title_link'];
      titleLinkDownload = json['title_link_download'];
      ts = DateTime.parse(json['ts']);
      videoUrl = json['video_url'];

      imageDimensions = json['image_dimensions'] != null
          ? ImageDimensions.fromMap(json['image_dimensions'])
          : null;
    }
    type = json['type'];
  }

  Map<String, dynamic> toMap() => {
        'audio_url': audioUrl,
        'author_icon': authorIcon,
        'author_link': authorLink,
        'author_name': authorName,
        'collapsed': collapsed,
        'color': color,
        'fields': fields
                ?.where((json) => json != null)
                ?.map((field) => field.toMap())
                ?.toList() ??
            [],
        'image_url': imageUrl,
        'message_link': messageLink,
        'text': text,
        'description': description,
        'image_preview': imagePreview,
        'thumb_url': thumbUrl,
        'title': title,
        'title_link': titleLink,
        'title_link_download': titleLinkDownload,
        'ts': ts != null ? ts!.toIso8601String() : null,
        'video_url': videoUrl,
        'image_dimensions': imageDimensions != null ? imageDimensions!.toMap(): null,
        'type': type,
      };

  @override
  String toString() {
    return '{"audioUrl": "$audioUrl", "authorIcon": "$authorIcon", "authorLink": "$authorLink", "authorName": "$authorName", "collapsed": "$collapsed", '
        '"color": "$color", "fields": "$fields", "imageUrl": "$imageUrl", "messageLink": "$messageLink", "text": "$text", "description": "$description", '
        '"image_preview": "$imagePreview", "thumbUrl": "$thumbUrl", "title": "$title", '
        '"titleLink": "$titleLink", "titleLinkDownload": "$titleLinkDownload", "ts": "$ts", "videoUrl": "$videoUrl", "imageDimensions": $imageDimensions'
        '"type": $type}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAttachment &&
          runtimeType == other.runtimeType &&
          audioUrl == other.audioUrl &&
          authorIcon == other.authorIcon &&
          authorLink == other.authorLink &&
          authorName == other.authorName &&
          collapsed == other.collapsed &&
          color == other.color &&
          DeepCollectionEquality().equals(fields, other.fields) &&
          imageUrl == other.imageUrl &&
          messageLink == other.messageLink &&
          text == other.text &&
          description == other.description &&
          imagePreview == other.imagePreview &&
          thumbUrl == other.thumbUrl &&
          title == other.title &&
          titleLink == other.titleLink &&
          titleLinkDownload == other.titleLinkDownload &&
          ts == other.ts &&
          imageDimensions == other.imageDimensions &&
          videoUrl == other.videoUrl &&
          type == other.type;

  @override
  int get hashCode =>
      audioUrl.hashCode ^
      authorIcon.hashCode ^
      authorLink.hashCode ^
      authorName.hashCode ^
      collapsed.hashCode ^
      color.hashCode ^
      fields.hashCode ^
      imageUrl.hashCode ^
      messageLink.hashCode ^
      text.hashCode ^
      description.hashCode ^
      imagePreview.hashCode ^
      thumbUrl.hashCode ^
      title.hashCode ^
      titleLink.hashCode ^
      titleLinkDownload.hashCode ^
      ts.hashCode ^
      imageDimensions.hashCode ^
      videoUrl.hashCode ^
      type.hashCode;
}