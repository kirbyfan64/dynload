class MyClass {
  int which;

  MyClass() { which = 1; }
  MyClass.second() { which = 2; }
  MyClass.third() { which = 3; }

  static int howMany = 3;
  static int howManyFunc() => howMany;
}


MyClass make(int which) {
  switch (which) {
  case 1: return new MyClass();
  case 2: return new MyClass.second();
  case 3: return new MyClass.third();
  }
}

int howMany = MyClass.howMany;
