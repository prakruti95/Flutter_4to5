class Student
{
    //data memebers
    var num;
    var name;

    void display()
    {
      print("$num and $name");
    }
}
void main()
{
    Student s1 = Student();
    s1.num=101;
    s1.name="abcd";

    Student s2 = Student();
    s2.num=102;
    s2.name="pqrs";

    //print("${s1.num} and ${s1.name}");
   // print("${s2.num} and ${s2.name}");
    s1.display();
    s2.display();//method call
}