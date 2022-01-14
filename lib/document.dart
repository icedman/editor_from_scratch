class Cursor {
  int line = 0;
  int column = 0;
  int anchorLine = 0;
  int anchorColumn = 0;

  Cursor normalized() {
    Cursor res = Cursor();
    if (line > anchorLine || (line == anchorLine && column > anchorColumn)) {
      res.line = anchorLine;
      res.column = anchorColumn;
      res.anchorLine = line;
      res.anchorColumn = column;
      return res;
    }
    res.line = line;
    res.column = column;
    res.anchorLine = anchorLine;
    res.anchorColumn = anchorColumn;
    return res;
  }

  bool hasSelection() {
    return line != anchorLine || column != anchorColumn;
  }
}

class Document {
  List<String> lines = <String>[''];
  Cursor cursor = Cursor();

  int hash = 0;

  void output() {
    print('\n');
    print(
        'cursor at: ${cursor.line + 1} ${cursor.column + 1} anchor: ${cursor.anchorLine + 1} ${cursor.anchorColumn + 1}');
    int i = 1;
    for (var l in lines) {
      print('${i++} $l');
    }
    print('selected lines: ${selectedLines()}');
    print(selectedText());
  }

  void _validateCursor(bool keepAnchor) {
    if (cursor.line >= lines.length) {
      cursor.line = lines.length - 1;
    }
    if (cursor.line < 0) cursor.line = 0;
    if (cursor.column > lines[cursor.line].length) {
      cursor.column = lines[cursor.line].length;
    }
    if (cursor.column < 0) cursor.column = 0;
    if (!keepAnchor) {
      cursor.anchorLine = cursor.line;
      cursor.anchorColumn = cursor.column;
    }

    hash++;
  }

  void moveCursor(int line, int column, {bool keepAnchor = false}) {
    _validateCursor(keepAnchor);
  }

  void moveCursorLeft({int count = 1, bool keepAnchor = false}) {
    cursor.column = cursor.column - count;
    _validateCursor(keepAnchor);
  }

  void moveCursorRight({int count = 1, bool keepAnchor = false}) {
    cursor.column = cursor.column + count;
    _validateCursor(keepAnchor);
  }

  void moveCursorUp({int count = 1, bool keepAnchor = false}) {
    cursor.line = cursor.line - count;
    _validateCursor(keepAnchor);
  }

  void moveCursorDown({int count = 1, bool keepAnchor = false}) {
    cursor.line = cursor.line + count;
    _validateCursor(keepAnchor);
  }

  void moveCursorToStartOfLine({bool keepAnchor = false}) {
    cursor.column = 0;
    _validateCursor(keepAnchor);
  }

  void moveCursorToEndOfLine({bool keepAnchor = false}) {
    cursor.column = lines[cursor.line].length;
    _validateCursor(keepAnchor);
  }

  void moveCursorToStartOfDocument({bool keepAnchor = false}) {
    cursor.line = 0;
    cursor.column = 0;
    _validateCursor(keepAnchor);
  }

  void moveCursorToEndOfDocument({bool keepAnchor = false}) {
    cursor.line = lines.length - 1;
    cursor.column = lines[cursor.line].length;
    _validateCursor(keepAnchor);
  }


  void insertNewLine() {
    deleteSelectedText();
    moveCursorToEndOfLine();
    insertText('\n');
  }

  void insertText(String text) {
    deleteSelectedText();
    String l = lines[cursor.line];
    String left = l.substring(0, cursor.column);
    String right = l.substring(cursor.column);

    // handle new line
    if (text == '\n') {
      lines[cursor.line] = left;
      lines.insert(cursor.line + 1, right);
      moveCursorDown();
      moveCursorToStartOfLine();
      return;
    }

    lines[cursor.line] = left + text + right;
    moveCursorRight(count: text.length);
  }

  void deleteText({int numberOfCharacters = 1}) {
    String l = lines[cursor.line];

    // handle join lines
    if (cursor.column >= l.length) {
      if (cursor.line < l.length - 1) {
        lines[cursor.line] += lines[cursor.line + 1];
        moveCursorDown();
        deleteLine();
        moveCursorToEndOfLine();
      }
      return;
    }

    Cursor cur = cursor.normalized();
    String left = l.substring(0, cur.column);
    String right = l.substring(cur.column + numberOfCharacters);
    cursor = cur;

    // handle erase entire line
    if (lines.length > 1 && (left + right).length == 0) {
      lines.removeAt(cur.line);
      moveCursorUp();
      moveCursorToStartOfLine();
      return;
    }

    lines[cursor.line] = left + right;
  }

  void deleteLine({int numberOfLines = 1}) {
    for (int i = 0; i < numberOfLines; i++) {
      moveCursorToStartOfLine();
      deleteText(numberOfCharacters: lines[cursor.line].length);
    }
  }

  List<String> selectedLines() {
    List<String> res = <String>[];
    Cursor cur = cursor.normalized();
    if (cur.line == cur.anchorLine) {
      String sel =
          lines[cur.line].substring(cur.column, cur.anchorColumn);
      res.add(sel);
      return res;
    }

    res.add(lines[cur.line].substring(cur.column));
    for (int i = cur.line + 1; i < cur.anchorLine; i++) {
      res.add(lines[i]);
    }
    res.add(lines[cur.anchorLine].substring(0, cur.anchorColumn));
    return res;
  }

  String selectedText() {
    return selectedLines().join('\n');
  }

  void deleteSelectedText() {
    if (!cursor.hasSelection()) {
      return;
    }

    Cursor cur = cursor.normalized();
    List<String> res = selectedLines();
    if (res.length == 1) {
      print(cur.anchorColumn - cur.column);
      deleteText(numberOfCharacters: cur.anchorColumn - cur.column);
      clearSelection();
      return;
    }

    lines[cur.line] = lines[cur.line].substring(0, cur.column);
    lines[cur.anchorLine] =
        lines[cur.anchorLine].substring(cur.anchorColumn);
    moveCursorDown();
    for (int i = 0; i < res.length - 2; i++) {
      deleteLine();
    }
    clearSelection();
  }

  void clearSelection() {
    cursor.anchorLine = cursor.line;
    cursor.anchorColumn = cursor.column;
  }
}
