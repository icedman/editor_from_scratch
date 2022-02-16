import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import 'document.dart';
import 'view.dart';
import 'highlighter.dart';

Offset screenToCursor(RenderObject? obj, Offset pos) {
  List<RenderParagraph> pars = <RenderParagraph>[];
  findRenderParagraphs(obj, pars);

  RenderParagraph? targetPar;
  int line = -1;
  int column = -1;

  for (final p in pars) {
    TextSpan t = p.text as TextSpan;
    Rect bounds = const Offset(0, 0) & p.size;
    Offset offsetForCaret = p.localToGlobal(
        p.getOffsetForCaret(const TextPosition(offset: 0), bounds));
    Rect _bounds = offsetForCaret & Size(p.size.width * 10, p.size.height);
    if (_bounds.inflate(2).contains(pos)) {
      targetPar = p;
      break;
    }
  }

  if (targetPar == null) return Offset(-1, -1);

  Rect bounds = const Offset(0, 0) & targetPar.size;
  TextSpan? t = targetPar.text as TextSpan;
  List<InlineSpan> children = t.children ?? <InlineSpan>[];

  double fw = 0;
  double fh = 0;

  int textOffset = 0;
  bool found = false;
  for (var p in children) {
    if (found && line != -1) break;
    if (p is CustomWidgetSpan) {
      line = (p as CustomWidgetSpan).line;
      continue;
    }
    if (!(p is TextSpan) || found) {
      continue;
    }

    if (fw == 0) {
      Size size = getTextExtents(' ', p.style ?? TextStyle());
      fw = size.width;
      fh = size.height;
    }

    String txt = (p as TextSpan).text ?? '';
    for (int i = 0; i < txt.length; i++) {
      Offset offsetForCaret = targetPar.localToGlobal(targetPar
          .getOffsetForCaret(TextPosition(offset: textOffset), bounds));
      Rect _bounds = offsetForCaret & Size(fw, fh);
      if (_bounds.inflate(2).contains(Offset(pos.dx + 1, pos.dy + 1))) {
        column = textOffset;
        found = true;
        break;
      }
      textOffset++;
    }
  }

  if (found) {
    return Offset(textOffset.toDouble(), line.toDouble());
  }

  return Offset(column.toDouble(), line.toDouble());
}

void findRenderParagraphs(RenderObject? obj, List<RenderParagraph> res) {
  if (obj is RenderParagraph) {
    res.add(obj);
    return;
  }
  obj?.visitChildren((child) {
    findRenderParagraphs(child, res);
  });
}

class InputListener extends StatefulWidget {
  InputListener({required Widget this.child});

  late Widget child;

  @override
  _InputListener createState() => _InputListener();
}

class _InputListener extends State<InputListener> {
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }

    DocumentProvider doc = Provider.of<DocumentProvider>(context);
    Document d = doc.doc;

    return GestureDetector(
        child: Focus(
            child: widget.child,
            focusNode: focusNode,
            autofocus: true,
            onKey: (FocusNode node, RawKeyEvent event) {
              if (event.runtimeType.toString() == 'RawKeyDownEvent') {
                switch (event.logicalKey.keyLabel) {
                  case 'Home':
                    if (event.isControlPressed) {
                      d.moveCursorToStartOfDocument();
                    } else {
                      d.moveCursorToStartOfLine();
                    }
                    break;
                  case 'End':
                    if (event.isControlPressed) {
                      d.moveCursorToEndOfDocument();
                    } else {
                      d.moveCursorToEndOfLine();
                    }
                    break;
                  case 'Enter':
                    d.deleteSelectedText();
                    d.insertNewLine();
                    break;
                  case 'Backspace':
                    if (d.cursor.hasSelection()) {
                      d.deleteSelectedText();
                    } else {
                      d.moveCursorLeft();
                      d.deleteText();
                    }
                    break;
                  case 'Delete':
                    if (d.cursor.hasSelection()) {
                      d.deleteSelectedText();
                    } else {
                      d.deleteText();
                    }
                    break;
                  case 'Arrow Left':
                    d.moveCursorLeft(keepAnchor: event.isShiftPressed);
                    break;
                  case 'Arrow Right':
                    d.moveCursorRight(keepAnchor: event.isShiftPressed);
                    break;
                  case 'Arrow Up':
                    d.moveCursorUp(keepAnchor: event.isShiftPressed);
                    break;
                  case 'Arrow Down':
                    d.moveCursorDown(keepAnchor: event.isShiftPressed);
                    break;
                  default:
                    {
                      int k = event.logicalKey.keyId;
                      if ((k >= LogicalKeyboardKey.keyA.keyId &&
                              k <= LogicalKeyboardKey.keyZ.keyId) ||
                          (k + 32 >= LogicalKeyboardKey.keyA.keyId &&
                              k + 32 <= LogicalKeyboardKey.keyZ.keyId)) {
                        String ch = String.fromCharCode(
                            97 + k - LogicalKeyboardKey.keyA.keyId);
                        if (event.isControlPressed) {
                          d.command('ctrl+$ch');
                          break;
                        }
                        d.insertText(ch);
                        break;
                      }
                    }
                    if (event.logicalKey.keyLabel.length == 1) {
                      d.insertText(event.logicalKey.keyLabel);
                    }
                    print(event.logicalKey.keyLabel);
                    break;
                }
                doc.touch();
              }
              return KeyEventResult.handled;
            }),
        onTapDown: (TapDownDetails details) {
          Offset o = screenToCursor(
              context.findRenderObject(), details.globalPosition);
          d.moveCursor(o.dy.toInt(), o.dx.toInt());
          doc.touch();
        },
        onPanUpdate: (DragUpdateDetails details) {
          Offset o = screenToCursor(
              context.findRenderObject(), details.globalPosition);
          d.moveCursor(o.dy.toInt(), o.dx.toInt(), keepAnchor: true);
          doc.touch();
        });
  }
}
