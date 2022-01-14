import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'document.dart';
import 'view.dart';
import 'input.dart';
import 'highlighter.dart';

void futureRun(int millis, Function? func) {
  Timer(Duration(milliseconds: millis), () {
    func?.call();
  });
}

void main() async {
  DocumentProvider doc = DocumentProvider();
  await doc.openFile('/Users/iceman/Downloads/tinywl.c');
  Document d = doc.doc;
  return runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => doc),
        Provider(create: (context) => Highlighter())
      ],
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: KeyInputListener(child: View())))));
}
