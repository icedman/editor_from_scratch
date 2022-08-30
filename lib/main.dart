import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'view.dart';
import 'input.dart';
import 'highlighter.dart';

class Editor extends StatefulWidget {
  const Editor({super.key, this.path = ''});
  final String path;
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
    ], child: const InputListener(child: View()));
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
      home: const Scaffold(body: Editor(path: './tests/tinywl.c'))));
}
