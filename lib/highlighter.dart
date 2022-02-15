import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:collection';
import 'dart:ui' as ui;

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
    colorMap['\\b(for|if|then)\\b'] = function;
    colorMap['\\b(include|struct|bool|int|long|double|char|void)\\b'] = keyword;
  }

  List<InlineSpan> run(String text, int line, Document document) {
    TextStyle defaultStyle =
        TextStyle(fontFamily: 'FiraCode', fontSize: 18, color: foreground);
    List<InlineSpan> res = <InlineSpan>[];
    List<LineDecoration> decors = <LineDecoration>[];

    for (var exp in colorMap.keys) {
      RegExp regExp = new RegExp(exp, caseSensitive: false, multiLine: false);
      var matches = regExp.allMatches(text);
      matches.forEach((m) {
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

      // decorate
      decors.forEach((d) {
        if (i >= d.start && i <= d.end) {
          style = style.copyWith(color: d.color);
        }
      });

      // is within selection
      if (cur.hasSelection()) {
        if (line < cur.line ||
            (line == cur.line && i < cur.column) ||
            line > cur.anchorLine ||
            (line == cur.anchorLine && i + 1 > cur.anchorColumn)) {
        } else {
          style = style.copyWith(backgroundColor: selection.withOpacity(0.75));
        }
      }

      // is within caret
      if ((line == document.cursor.line && i == document.cursor.column)) {
        res.add(WidgetSpan(
            alignment: ui.PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
                decoration: BoxDecoration(
                    border: Border(
                        left: BorderSide(
                            width: 1.2, color: style.color ?? Colors.yellow))),
                child: Text(ch, style: style))));
        continue;
      }

      if (res.length != 0 && !(res[res.length - 1] is WidgetSpan)) {
        TextSpan prev = res[res.length - 1] as TextSpan;
        if (prev.style == style) {
          prevText += ch;
          res[res.length - 1] = TextSpan(text: prevText, style: style);
          continue;
        }
      }

      res.add(TextSpan(text: ch, style: style));
      prevText = ch;
    }

    // fallback
    if (res.length == 0) {
      res.add(TextSpan(text: text, style: defaultStyle));
    }
    return res;
  }
}
