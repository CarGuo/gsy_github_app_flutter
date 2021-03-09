/**
 * Created by guoshuyu
 * Date: 2018-10-12
 */

abstract class Base {
  a() {
    print("base a()");
  }

  b() {
    print("base b()");
  }

  c() {
    print("base c()");
  }
}

mixin A on Base {
  a() {
    print("A.a()");
    //super.a();
  }

  b() {
    print("A.b()");
    super.b();
  }
}

mixin A2 on Base {
  a() {
    print("A2.a()");
    super.a();
  }
}

class B extends Base {
  a() {
    print("B.a()");
    super.a();
  }

  b() {
    print("B.b()");
    super.b();
  }

  c() {
    print("B.c()");
    super.c();
  }
}

class G extends B with A, A2 {

}


testMixins() {
  G t = new G();
  t.a();
  t.b();
  t.c();
}


///I/flutter (13627): A2.a()
///I/flutter (13627): A.a()
///I/flutter (13627): B.a()
///I/flutter (13627): base a()
///I/flutter (13627): A.b()
///I/flutter (13627): B.b()
///I/flutter (13627): base b()
///I/flutter (13627): B.c()
///I/flutter (13627): base c()