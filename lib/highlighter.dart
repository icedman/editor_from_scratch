import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:collection';

import 'document.dart';
import 'view.dart';

Color foreground = Color(0xfff8f8f2);
Color background = Color(0xff272822);
Color comment = Color(0xff88846f);
Color selection = Color(0xff44475a);
Color function = Color(0xff50fa7b);
Color keyword = Color(0xffff79c6);

class LineDecoration {
  int start = 0;
  int end = 0;
  Color color = Colors.white;
  Color background = Colors.white;
  bool underline = false;
  bool italic = false;
}

class Highlighter {
  HashMap<String, Color> colorMap = HashMap<String, Color>();

  Highlighter() {
    colorMap.clear();
    colorMap['(for|if|then) '] = function;
    colorMap['(struct|bool|int|long|double|char|void) '] = keyword;
  }

  List<TextSpan> run(String text, int line, Document document) {
    TextStyle defaultStyle =
        TextStyle(fontFamily: 'FiraCode', fontSize: 18, color: foreground);
    List<TextSpan> res = <TextSpan>[];
    List<LineDecoration> decors = <LineDecoration>[];

    for (var exp in colorMap.keys) {
      RegExp regExp = new RegExp(exp, caseSensitive: false, multiLine: false);
      var matches = regExp.allMatches(text);
      matches.forEach((m) {
        //var g = m.groups([0,1]);
        if (m.start == m.end) return;
        LineDecoration d = LineDecoration();
        d.start = m.start;
        d.end = m.end - 1;
        d.color = colorMap[exp] ?? foreground;
        decors.add(d);
      });
    }

    text += ' ';

    String prevText = '';
    for (int i = 0; i < text.length; i++) {
      String ch = text[i];
      TextStyle style = defaultStyle.copyWith();

      Cursor cur = document.cursor.normalized();

      bool withinSelection = false;
      bool isCaret =
          (line == document.cursor.line && i == document.cursor.column);

      // decorate
      decors.forEach((d) {
        if (i >= d.start && i <= d.end) {
          style = style.copyWith(color: d.color);
        }
      });

      if (cur.hasSelection()) {
        withinSelection = true;
        if (line < cur.line ||
            (line == cur.line && i < cur.column) ||
            line > cur.anchorLine ||
            (line == cur.anchorLine && i + 1 > cur.anchorColumn)) {
          withinSelection = false;
        }
      }

      if (withinSelection) {
        style = style.copyWith(backgroundColor: selection.withOpacity(0.75));
      }
      if (isCaret) {
        style = style.copyWith(
            backgroundColor: function.withOpacity(0.5),
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.solid);
      }

      if (res.length != 0) {
        TextSpanWrapper prev = res[res.length - 1] as TextSpanWrapper;
        if (prev.style == style) {
          prevText += ch;
          res[res.length - 1] =
              TextSpanWrapper(text: prevText, style: style, line: line);
          continue;
        }
      }

      res.add(TextSpanWrapper(text: ch, style: style, line: line, position: i));
      prevText = ch;
    }

    // fallback
    if (res.length == 0) {
      res.add(TextSpanWrapper(text: text, style: defaultStyle));
    }
    return res;
  }
}
