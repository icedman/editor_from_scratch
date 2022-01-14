import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'document.dart';
import 'view.dart';

class LineDecoration {
	int start = 0;
	int end = 0;
	Color color = Colors.white;
	Color background = Colors.white;
	bool underline = false;
	bool italic = false;
}

class Highlighter {
	List<TextSpan> run(String text, int line, Document document) {
	    TextStyle defaultStyle = TextStyle(fontSize: 20, color: Colors.black);
		List<TextSpan> res = <TextSpan>[];
		List<LineDecoration> decors = <LineDecoration>[];

		String prevText = '';
		for(int i=0; i<text.length; i++) {
			String ch = text[i];
			TextStyle style = defaultStyle.copyWith();

			Cursor cur = document.cursor.normalized();

			bool withinSelection = false;
			bool isCaret = (line == document.cursor.line && i == document.cursor.column);

			// decorate

			if (cur.hasSelection()) {
				withinSelection = true;
				if (line < cur.line || (line == cur.line && i < cur.column) ||
					line > cur.anchorLine || (line == cur.anchorLine && i > cur.anchorColumn)) {
					withinSelection = false;
				}
			}

			if (withinSelection) {
				style = style.copyWith(backgroundColor: Colors.grey.withOpacity(0.75));
			}
			if (isCaret) {
				style = style.copyWith(decoration: TextDecoration.underline,
			          decorationStyle: TextDecorationStyle.solid);
			}

			if (res.length != 0) {
				TextSpanWrapper prev = res[res.length - 1] as TextSpanWrapper;
				if (prev.style == style) {
					prevText += ch;
					res[res.length - 1] = TextSpanWrapper(text: prevText, style: style, line: line);
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