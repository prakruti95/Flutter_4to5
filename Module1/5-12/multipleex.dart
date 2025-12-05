class A
{
  void a()
  {
    print("A1 called");
  }
}
class B
{
  void b()
  {
    print("B1 called");
  }
}
class C implements A,B
{
  @override
  void a() {
   print("A called");
  }

  @override
  void b() {
    print("B called");
  }

  c()
  {
    print("C called");
  }

}
void main()
{
    C c1 = C();
    c1.a();
    c1.b();
    c1.c();
}