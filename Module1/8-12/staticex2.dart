class Emp
{
    var id;
    var name;
    static var clg ="VVP";

    Emp(var id,var name)
    {
        this.id=id;
        this.name=name;
    }
    void display()
    {
        print("$id and $name and $clg");
    }
    static change()
    {
        clg = "Marwadi";
    }
}
void main()
{
    Emp e1 = Emp(101, "abcd");
    Emp e2 = Emp(102, "pqrs");
    Emp e3 = Emp(103, "xyz");
    Emp.change();//static method calling
    e1.display();
    e2.display();
    e3.display();

}