class Account
{
    static var num = 0;

    Account()
    {
        num++;
        print(num);
    }
}
void main()
{
    Account a1 = Account();
    Account a2 = Account();
    Account a3 = Account();
}