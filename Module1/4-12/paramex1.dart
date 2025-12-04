details(String surname,[var email , var name])
{
  if(name!=null)
  {
    print(name);
  }
  if(surname!=null)
  {
    print(surname);
  }
  if(email!=null)
  {
    print(email);
  }

}
void main()
{
    details("a", "a", "a@gmail.com");
    details("b", "b", "b@gmail.com");
    details("c", "c");

}