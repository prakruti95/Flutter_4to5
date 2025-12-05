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

void main()
{

    B b1 = B();

    b1.a();
    b1.b();
}