import 'package:dynload/dynload.dart';
import 'dart:mirrors';


void eq(var lhs, var rhs) {
  if (lhs != rhs)
    throw new Exception("check failed: ${lhs} == ${rhs}");
}


void isa(var lhs, Type ty) {
  if (lhs == null ||
      !reflectClass(lhs.runtimeType).isAssignableTo(reflectClass(ty)))
    throw new Exception("check failed: ${lhs} is ${ty}");
}


void cb(ProxyLib lib, var message) async {
  eq(message, 'Hello, world!');

  eq(lib.howMany, 3);

  var cls = proxyClass(lib, #MyClass);
  eq(proxyNewWith(cls), proxyNew(lib, #MyClass));
  eq(cls.howMany, 3);
  eq(cls.howManyFunc(), 3);

  eq(proxyNew(lib, #MyClass)().which, 1);
  eq(proxyNew(lib, #MyClass).second().which, 2);
  eq(proxyNew(lib, #MyClass).third().which, 3);

  eq(lib.make(1).which, 1);
  eq(lib.make(2).which, 2);
  eq(lib.make(3).which, 3);

  isa(proxyLibMirror(lib), LibraryMirror);
  isa(proxyClassMirror(cls), ClassMirror);
}
