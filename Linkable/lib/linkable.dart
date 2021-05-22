library linkable;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkable/constants.dart';
import 'package:linkable/emailParser.dart';
import 'package:linkable/httpParser.dart';
import 'package:linkable/link.dart';
import 'package:linkable/mentionParser.dart';
import 'package:linkable/parser.dart';
import 'package:linkable/telParser.dart';
import 'package:url_launcher/url_launcher.dart';

typedef void LinkClickCallback(String text, String type);
class Linkable extends StatelessWidget {
  final String text;
  final textColor;
  final linkColor;
  final style;
  final textAlign;
  final textDirection;
  final maxLines;
  final overflow;
  final textScaleFactor;
  final softWrap;
  final strutStyle;
  final locale;
  final textWidthBasis;
  final textHeightBehavior;
  final LinkClickCallback linkClickCallback;

  List<Parser> _parsers = List<Parser>();
  List<Link> _links = List<Link>();

  Linkable({
    Key key,
    @required this.text,
    this.textColor = Colors.black,
    this.linkColor = Colors.blue,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.linkClickCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    init();
    return RichText(
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      text: TextSpan(
        text: '',
        style: style,
        children: _getTextSpans(),
      ),
    );
  }

  _getTextSpans() {
    List<TextSpan> _textSpans = [];
    int i = 0;
    int pos = 0;
    while (i < text.length) {
      _textSpans.add(_text(text.substring(
          i,
          pos < _links.length && i <= _links[pos].regExpMatch.start
              ? _links[pos].regExpMatch.start
              : text.length)));
      if (pos < _links.length && i <= _links[pos].regExpMatch.start) {
        _textSpans.add(_link(
            text.substring(
                _links[pos].regExpMatch.start, _links[pos].regExpMatch.end),
            _links[pos].type));
        i = _links[pos].regExpMatch.end;
        pos++;
      } else {
        i = text.length;
      }
    }
    return _textSpans;
  }

  _text(String text) {
    return TextSpan(text: text, style: TextStyle(color: textColor));
  }

  _link(String text, String type) {
    if (type == mention)
      text = text.substring(1, text.length - 1);
      return TextSpan(
        text: text,
        style: TextStyle(color: linkColor),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (linkClickCallback != null)
              linkClickCallback(text, type);
          }
      );
  }

  init() {
    _addParsers();
    _parseLinks();
    _filterLinks();
  }

  _addParsers() {
    _parsers.add(MentionParser(text));
    _parsers.add(EmailParser(text));
    _parsers.add(HttpParser(text));
    _parsers.add(TelParser(text));
  }

  _parseLinks() {
    for (Parser parser in _parsers) {
      _links.addAll(parser.parse().toList());
    }
  }

  _filterLinks() {
    _links.sort(
            (Link a, Link b) =>
            a.regExpMatch.start.compareTo(b.regExpMatch.start));

    List<Link> _filteredLinks = List<Link>();
    if (_links.length > 0) {
      _filteredLinks.add(_links[0]);
    }

    for (int i = 0; i < _links.length - 1; i++) {
      if (_links[i + 1].regExpMatch.start > _links[i].regExpMatch.end) {
        _filteredLinks.add(_links[i + 1]);
      }
    }
    _links = _filteredLinks;
  }
}
