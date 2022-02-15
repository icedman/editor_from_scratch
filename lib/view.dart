import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';

import 'document.dart';
import 'highlighter.dart';

class DocumentProvider extends ChangeNotifier {
  Document doc = Document();

  Future<bool> openFile(String path) async {
    File f = await File(path);
    await f.openRead().map(utf8.decode).transform(LineSplitter()).forEach((l) {
      doc.insertText(l);
      doc.insertNewLine();
    });
    doc.moveCursorToStartOfDocument();
    touch();
    return true;
  }

  void touch() {
    notifyListeners();
  }
}

class ViewLine extends StatelessWidget {
  ViewLine({this.lineNumber = 0, this.text = ''});

  int lineNumber = 0;
  String text = '';

  @override
  Widget build(BuildContext context) {
    DocumentProvider doc = Provider.of<DocumentProvider>(context);
    Highlighter hl = Provider.of<Highlighter>(context);
    List<InlineSpan> spans = hl.run(text, lineNumber, doc.doc);

    final gutterStyle =
        TextStyle(fontFamily: 'FiraCode', fontSize: 16, color: comment);
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: ' ${doc.doc.lines.length} ', style: gutterStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    double gutterWidth = textPainter.size.width;

    return Stack(children: [
      Padding(
          padding: EdgeInsets.only(left: gutterWidth),
          child: RichText(text: TextSpan(children: spans), softWrap: true)),
      Container(
          width: gutterWidth,
          alignment: Alignment.centerRight,
          child: Text('${lineNumber + 1} ', style: gutterStyle)),
    ]);
  }
}

class View extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DocumentProvider doc = Provider.of<DocumentProvider>(context);
    Document d = doc.doc;
    return ListView.builder(
        itemCount: d.lines.length,
        itemBuilder: (BuildContext context, int index) {
          return ViewLine(lineNumber: index, text: d.lines[index]);
        });
  }
}
