import 'package:linkable/constants.dart';
import 'package:linkable/link.dart';
import 'package:linkable/parser.dart';

class MentionParser implements Parser {
  String text;

  MentionParser(this.text);

  parse() {
    String pattern = r"%.*?#";

    RegExp regExp = RegExp(pattern);

    Iterable<RegExpMatch> _allMatches = regExp.allMatches(text);
    List<Link> _links = List<Link>();
    for (RegExpMatch match in _allMatches) {
      _links.add(Link(regExpMatch: match, type: mention));
    }
    return _links;
  }
}
