class Emp
{
    //global variable
    var id;
    var name;
    var salary;

    //local variable
    Emp(var id,var name,var salary)
    {
        this.id = id;
        this.name = name;
        this.salary = salary;
    }

    display()
    {
        print("$id and $name and $salary");
    }
}
void main()
{
    Emp e1 = Emp(101,"a",10234);
    Emp e2 = Emp(102,"b",10235);

    e1.display();
    e2.display();


}