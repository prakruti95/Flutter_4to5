validate(int age)
{
      if(age>=18)
      {
          print("Eligible to vote");
      }
      else
      {
        try
        {
          throw Exception("Not Eligible");
        }
        catch(e)
        {
          print(e);
        }
        finally
        {
          print("abcd");
        }


      }
}
void main()
{

  // var data = 10 / 0;
  // print(data);
  // print("Executed");

  validate(15);


}