/**
 * Created by guoshuyu
 * Date: 2018-10-12
 */

abstract class Base {
  a() {

  }
  b() {

  }
}

class S extends Base {
  a() {
    print("S.a");
    super.a();
  }
}

class A extends Base {
  a() {
    print("A.a");
    super.a();
  }

  b() {
    print("A.b");
    super.b();
  }
}

class A1 extends Base {
  a() {
    print("A1.a");
    super.a();
  }

  b() {
    print("A1.b");
    super.b();
  }
}

class A2 extends Base {
  a() {
    print("A2.a");
    super.a();
  }

  b() {
    print("A2.b");
    super.b();
  }
}

class B extends Base {
  a() {
    print("B.a");
    super.a();
  }

  b() {
    print("B.b");
    super.b();
  }

  c() {
    print("B.c ");
  }
}

class T = B with A1, A2, A, S;


testMixins() {
  T t = new T();
  t.a();
  t.b();
  t.c();
}

/**
 *  I/flutter ( 1864): S.a
    I/flutter ( 1864): A.a
    I/flutter ( 1864): A2.a
    I/flutter ( 1864): A1.a
    I/flutter ( 1864): B.a
    I/flutter ( 1864): A.b
    I/flutter ( 1864): A2.b
    I/flutter ( 1864): A1.b
    I/flutter ( 1864): B.b
    I/flutter ( 1864): B.c
 * */