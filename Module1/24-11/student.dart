class Student
{
    //data memebers
    var num;
    String name="";
}
void main()
{
  //object
  //Student s2;
  //var s3 = Student();
  //Student s4 = new Student();
  //object create
  Student s1 = Student();
  Student s2 = Student();
  Student s3 = Student();
  Student s4 = Student();
  Student s5 = Student();

  //object value assign
  s1.name="baldev";
  s1.num=1;

  s2.name="Abhay";
  s2.num=2;

  s3.name="Vivek";
  s3.num=3;

  s4.name="Bhargav";
  s4.num=4;

  s5.name="Harsh";
  s5.num=5;
  //value call
  print(s1.name);
  print(s1.num);

  print(s2.name);
  print(s2.num);

  print(s3.name);
  print(s3.num);

  print(s4.name);
  print(s4.num);

  print(s5.name);
  print(s5.num);

}