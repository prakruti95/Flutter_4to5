abstract class Shape
{

  // Define your Instance variable if needed
  int x=0;
  int y=0;

  void draw();       // Abstract Method

  void myNormalFunction()
  {
    // Some code
  }
}
class Rec extends Shape
{
  @override
  void draw()
  {
   print("Rectangle Drawing");
  }

}
void main()
{
  Rec s = Rec();
  s.draw();
}