dynload
=======

*dynload* makes it easy (or, at least easier) to dynamically load imports at
runtime. It takes a URI to import and a module URI to use as a callback.

Usage:

```dart
import 'package:dynload/dynload.dart';


void main() async {
  // This code will dynamically import 'package:mypkg/mypkg.dart'. Once imported,
  // it will import the module 'package:mypkg/mycallback.dart' and call the
  // function mycallback inside.

  await dynload(Uri.parse('package:mypkg/mypkg.dart'),
                new RemoteCallback(Uri.parse('package:mypkg/mycallback.dart'),
                                   'mycallback'),
                // This is optional; when given, it's a message that will be
                // passed to the callback function.
                message: 'Hello, world!');
}
```


This is what a callback should look like:

```dart
// This is mypkg/mycallback.dart.

import 'package:dynload/dynload.dart';
import 'dart:mirrors';


void callback(ProxyLib lib, var message) {
  // The imported library is in 'lib'. It's a ProxyLib, which means that it will
  // automatically forward any attributes accesses to the underlying library.

  // First of all, let's get the message:
  print(message); // Should print 'Hello, world!'.

  // To get the underlying LibraryMirror, you can use proxyMirror:
  LibraryMirror mirror = proxyMirror(lib);

  // Attributes and functions are automatically forwarded:
  print(mylib.myattr);
  print(mylib.myfunc(1, 2, 3));

  // Classes can be accessed using proxyClass:
  var cls = proxyClass(lib, #MyClass);
  print(cls.aStaticAttribute);
  print(cls.aStaticMethod());

  // They can be constructed using proxyNewWith:
  print(proxyNewWith(cls)(1));       // Like `new lib.MyClass(1)`.
  print(proxyNewWith(cls).ctor(1));  // Like `new lib.MyClass.ctor(1)`.

  // proxyNew(lib, cls) is shorthand for proxyNewWith(proxyClass(lib, cls)):
  print(proxyNew(lib, #MyClass)(1));       // Like `new lib.MyClass(1)`
  print(proxyNew(lib, #MyClass).ctor(1));  // Like `new lib.MyClass.ctor(1)`
}
```
