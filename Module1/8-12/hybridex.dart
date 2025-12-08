class A1
{
  void a1()
  {
    print("A1 called");
  }
}
class B1 extends A1
{
  void b1()
  {
    print("B1 called");
  }
}
class C1 extends A1
{
  void c1()
  {
    print("C1 called");
  }
}
class D1 extends B1 implements C1
{
  void d1()
  {
    print("D1 called");
  }

  @override
  void c1()
  {
    print("C1 called");
  }


}
void main()
{
    D1 d = D1();
    d.a1();
    d.b1();
    d.c1();
    d.d1();
}