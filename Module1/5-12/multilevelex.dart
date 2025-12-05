class A
{
    a()
    {
        print("A1 called");
    }
}
class B extends A
{
  b()
  {
    print("B1 called");
  }
}

class C extends B
{
  c()
  {
    print("C1 called");
  }
}

class D extends C
{
  d()
  {
    print("D1 called");
  }
}

void main()
{

   D d1 = D();
   d1.a();
   d1.b();
   d1.c();
   d1.d();
}