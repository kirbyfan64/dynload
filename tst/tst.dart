import 'package:dynload/dynload.dart';

import 'package:path/path.dart' as path;
import 'dart:io';


void main() async {
  var dir = path.dirname(Platform.script.toFilePath());
  var cb = new Uri.file(path.join(dir, 'cb.dart'));
  var mod = new Uri.file(path.join(dir, 'mod.dart'));

  await dynload(mod, new RemoteCallback(cb, 'cb'),
                message: 'Hello, world!');
}
