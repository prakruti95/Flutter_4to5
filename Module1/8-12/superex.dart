class M1
{
    var color = "black";
}
class M2 extends M1
{
  var color = "white";

  display()
  {
    print(color);
    print(super.color);
  }
}
void main()
{
  M2 m = M2();
  m.display();
}