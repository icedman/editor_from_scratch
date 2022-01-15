import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'document.dart';
import 'view.dart';

class KeyInputListener extends StatefulWidget {
  KeyInputListener({required Widget this.child});

  late Widget child;

  @override
  _KeyInputListener createState() => _KeyInputListener();
}

class _KeyInputListener extends State<KeyInputListener> {
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

    return Focus(
        child: widget.child,
        focusNode: focusNode,
        autofocus: true,
        onKey: (FocusNode node, RawKeyEvent event) {
          if (event.runtimeType.toString() == 'RawKeyDownEvent') {
            switch (event.logicalKey.keyLabel) {
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

          if (event.runtimeType.toString() == 'RawKeyUpEvent') {}
          return KeyEventResult.handled;
        });
  }
}
