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

  for (final par in pars) {
    TextSpan t = par.text as TextSpan;
    Rect bounds = const Offset(0, 0) & par.size;
    Offset offsetForCaret = par.localToGlobal(
        par.getOffsetForCaret(const TextPosition(offset: 0), bounds));
    Rect parBounds =
        offsetForCaret & Size(par.size.width * 10, par.size.height);
    if (parBounds.inflate(2).contains(pos)) {
      targetPar = par;
      break;
    }
  }

  if (targetPar == null) return Offset(-1, -1);

  Rect bounds = const Offset(0, 0) & targetPar.size;
  List<InlineSpan> children =
      (targetPar.text as TextSpan).children ?? <InlineSpan>[];
  Size fontCharSize = Size(0, 0);
  int textOffset = 0;
  bool found = false;
  for (var span in children) {
    if (found) break;
    if (!(span is TextSpan)) {
      continue;
    }

    if (fontCharSize.width == 0) {
      fontCharSize = getTextExtents(' ', span.style ?? TextStyle());
    }

    String txt = (span as TextSpan).text ?? '';
    for (int i = 0; i < txt.length; i++) {
      Offset offsetForCaret = targetPar.localToGlobal(targetPar
          .getOffsetForCaret(TextPosition(offset: textOffset), bounds));
      Rect charBounds = offsetForCaret & fontCharSize;
      if (charBounds.inflate(2).contains(Offset(pos.dx + 1, pos.dy + 1))) {
        found = true;
        break;
      }
      textOffset++;
    }
  }

  if (children.length > 0 && children.last is CustomWidgetSpan) {
    line = (children.last as CustomWidgetSpan).line;
  }

  return Offset(textOffset.toDouble(), line.toDouble());
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
  late Widget child;

  InputListener({required Widget this.child});
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
                  case 'Tab':
                    d.insertText('    ');
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
                    // print(event.logicalKey.keyLabel);
                    break;
                }
                doc.touch();
              }
              if (event.runtimeType.toString() == 'RawKeyUpEvent') {}
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
          if (o.dx == -1 || o.dy == -1) return;
          d.moveCursor(o.dy.toInt(), o.dx.toInt(), keepAnchor: true);
          doc.touch();
        });
  }
}
