/**
 * Created by guoshuyu
 * Date: 2018-10-12
 */

abstract class Base {
  a();
}

class S extends Base with A {
  a() {
    super.a();
    print("S.a");
  }
}

class A extends Base {
  a() {
    print("A.a");
  }

  b() {
    print("A.b");
  }
}

class B extends Base {
  a() {
    print("B.a");
  }

  b() {
    print("B.b");
  }

  c() {
    print("B.c ");
  }
}

class T = B with A, S;


testMixins() {
  T t = new T();
  t.a();
  t.b();
  t.c();
}