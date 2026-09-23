
%% ejercicio 1 counter
declare
fun {NewCounter ValorInicial}
    Value = {NewCell ValorInicial}
    fun {Get} @Value end
    proc {Inc N} Value := @Value + N end
in
    counter(get:Get inc:Inc)
end

local 
    NCounter = {NewCounter 5} 
in
    {System.showInfo "Ejercico 1 Objetos funciones"}
    {System.showInfo {NCounter.get}}
    {NCounter.inc 5}
    {System.showInfo {NCounter.get}}
end 

class NewCounterOOP
    attr value:0

    meth init(Val)
        value := Val
    end

    meth get(?Result)
        Result = @value
    end

    meth inc(Number)
        value := @value + Number
    end
end

local
    ObjectCounter = {New NewCounterOOP init(3)} A B
in
    {System.showInfo "Ejercico 1 Objetos"}
    {ObjectCounter get(A)}
    {System.showInfo A}
    {ObjectCounter inc(10)}
    {ObjectCounter get(B)}
    {System.showInfo B}
end

%% ejecricio 2 creacion de objetos

declare

fun{NewBankAccount InitOwner InitBalance}
    CellOwner = {NewCell InitOwner}
    CellBalance = {NewCell InitBalance}

    fun{Attributes}
        attributes(owner:CellOwner balance:CellBalance)
    end

    fun{Owner} @CellOwner end
    fun{Balance} @CellBalance end
    proc{Deposit Value} CellBalance := @CellBalance + Value end
    proc{Display} {System.showInfo "Owner: "#@CellOwner#" Balance: "#@CellBalance} end
in
    object(
        attributes: {Attributes}
        owner: Owner
        balance: Balance
        deposit: Deposit
        display: Display
    )
end

local 
    BankAccount = {NewBankAccount "Ignacio" 30}
in
    {System.showInfo "Ejercico 2 funciones"}
    {System.showInfo {BankAccount.owner}}
    {System.showInfo {BankAccount.balance}}
    {BankAccount.deposit 40}
    {BankAccount.display}
end