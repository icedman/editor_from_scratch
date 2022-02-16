import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'document.dart';
import 'view.dart';
import 'input.dart';
import 'highlighter.dart';

class Editor extends StatefulWidget {
  Editor({Key? key, String this.path = ''}) : super(key: key);
  String path = '';
  @override
  _Editor createState() => _Editor();
}

class _Editor extends State<Editor> {
  late DocumentProvider doc;
  @override
  void initState() {
    doc = DocumentProvider();
    doc.openFile(widget.path);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
      ChangeNotifierProvider(create: (context) => doc),
      Provider(create: (context) => Highlighter())
    ], child: InputListener(child: View()));
  }
}

void main() async {
  ThemeData themeData = ThemeData(
    fontFamily: 'FiraCode',
    primaryColor: foreground,
    backgroundColor: background,
    scaffoldBackgroundColor: background,
  );
  return runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: Scaffold(
          body: Row(children: [
        Expanded(child: Editor(path: './tests/tinywl.c')),
        Expanded(child: Editor(path: './tests/tinywl.c'))
      ]))));
}
