library dynload;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:mirrors';

import 'package:path/path.dart' as path;


/// A proxy library. Wraps an underlying ClassMirror and forwards all method
/// accesses to the mirror.
class ProxyClass {
  ClassMirror _cls;
  /// Creates a [ProxyClass] that wraps the given ClassMirror.
  ProxyClass(this._cls);

  bool operator==(dynamic other) =>
    other is ProxyClass && _cls == other._cls;

  /// Internal method. **Do not use!**
  ClassMirror get dynload_proxyMirror => _cls;

  /// Forwards the invocation to the underlying ClassMirror.
  dynamic noSuchMethod(Invocation inv) => _cls.delegate(inv);
}


/// A proxy constructor. Any attributes accessed are assumed to be constructors.
///
/// Example:
///
///     var ctor = proxyNew(lib, #MyClass);
///     print(ctor(1));         // Equivalent to `new lib.MyClass(1)`.
///     print(ctor.factory(1)); // Equivalent to `new lib.MyClass.factory(1)`.
class ProxyConstructor {
  ClassMirror _cls;
  /// Creates a [ProxyConstructor] that wraps the given ClassMirror.
  ProxyConstructor(this._cls);

  bool operator==(dynamic other) =>
    other is ProxyConstructor && _cls == other._cls;

  dynamic noSuchMethod(Invocation inv) {
    if (!inv.isMethod)
      throw new Exception('can only access methods on a ProxyConstructor');

    var ctor = inv.memberName == #call ? const Symbol('') : inv.memberName;
    return _cls.newInstance(ctor, inv.positionalArguments, inv.namedArguments)
               .reflectee;
  }
}


/// A proxy library. Wraps an underlying LibraryMirror and forwards all
/// method accesses to the mirror.
class ProxyLib {
  LibraryMirror _lib;
  /// Creates a [ProxyLib] that wraps the given LibraryMirror.
  ProxyLib(this._lib);

  bool operator==(dynamic other) =>
    other is ProxyLib && _lib == other._lib;

  /// Internal getter. **Do not use!**
  LibraryMirror get dynload_proxyMirror => _lib;

  /// Forwards the invocation to the underlying LibraryMirror.
  dynamic noSuchMethod(Invocation inv) => _lib.delegate(inv);
}


/// Gets the LibraryMirror inside the [ProxyLib].
LibraryMirror proxyLibMirror(ProxyLib lib) => lib.dynload_proxyMirror;
/// Gets the ClassMirror inside the [ProxyClass].
ClassMirror proxyClassMirror(ProxyClass cls) => cls.dynload_proxyMirror;


/// Gets the class with [name] from inside [lib], and returns a
/// [ProxyClass] that can be used to access the class's attributes.
ProxyClass proxyClass(ProxyLib lib, Symbol name) {
  var cls = proxyLibMirror(lib).declarations[name];
  if (cls == null || cls is! ClassMirror)
    throw new Exception("bad or nonexistent class ${name}");
  return new ProxyClass(cls);
}


/// Returns a [ProxyConstructor] that can be used to construct [cls].
ProxyConstructor proxyNewWith(ProxyClass cls) =>
  new ProxyConstructor(proxyClassMirror(cls));


/// Gets the class with [name] from inside [lib], and returns a
/// [ProxyConstructor] that can be used to construct the class.
ProxyConstructor proxyNew(ProxyLib lib, Symbol name) =>
  proxyNewWith(proxyClass(lib, name));


/// A callback that will be called by [dynload] when the module is loaded.
class RemoteCallback {
  /// The module containing the callback function.
  Uri module;
  /// The name of the callback function. It should take a [ProxyLib] and a
  // message (of type var) and return void.
  String func;

  RemoteCallback(this.module, this.func);
  bool operator==(dynamic other) =>
    other is RemoteCallback && module == other.module && func == other.func;
}


/// An exception thrown inside a [dynload] isolate.
class RemoteException {
  /// The error message.
  String err;
  /// The original stack trace.
  StackTrace trace;

  RemoteException(this.err, this.trace);
  bool operator==(dynamic other) =>
    other is RemoteException && err == other.err && trace == other.trace;
  String toString() =>
    "exception in dynload spawn: ${this.err}\n${this.trace}\n";
}


/// Loads the import located at [uri], then calls the [RemoteCallback] [cb]
/// with the loaded [ProxyLib]. Note that the callback will be called inside
/// an isolate.
///
/// If [message] is given, it will be sent as the second argument to the
/// callback function. (Note that a second argument will be given whether or
/// not the message was passed.) If [packageRoot] is given, it will be used as
/// the package root for both [uri] and [cb].
Future dynload(Uri uri, RemoteCallback cb,
               {dynamic message = null, Uri packageRoot = null}) async {
  var uristr = uri.toString();
  var self = await Isolate.resolvePackageUri(
              Uri.parse('package:dynload/dynload.dart'));
  assert(self != null);

  var stubsrc = """
  import '${uristr}';
  import '${cb.module.toString()}' as cb;
  import '${self.toString()}';
  import 'dart:mirrors';

  void main(var _, var message) async {
    var uri = Uri.parse(message[0]);
    await cb.${cb.func}(new ProxyLib(currentMirrorSystem().libraries[uri]),
                        message[1]);
  }
  """;

  var tmpdir = await Directory.systemTemp.createTemp();
  var stub = new File(path.join(tmpdir.path, 'stub.dart'));
  await stub.writeAsString(stubsrc);

  packageRoot ??= await Isolate.packageRoot;

  var recv = new ReceivePort();
  await Isolate.spawnUri(new Uri.file(stub.path), [], [uristr, message],
                         packageRoot: packageRoot,
                         errorsAreFatal: true,
                         onError: recv.sendPort,
                         onExit: recv.sendPort);

  var error = await recv.first;
  if (error != null) {
    var err = error[0];
    var trace = error[1];
    throw new RemoteException(err, trace);
  }
}
