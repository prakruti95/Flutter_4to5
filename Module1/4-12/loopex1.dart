void main()
{
  var num = 1234;//478
  var sum = 0;

  while(num>0)
  {
      var rem = num%10;
      sum+=rem;
      num=num ~/ 10;
  }

  print(sum);
}