declare Expression Num Sum Difference Multiplication Modulo
declare Units Teens Tens NumberToString

fun {Units N}
   case N
   of 1 then "one"
   [] 2 then "two"
   [] 3 then "three"
   [] 4 then "four"
   [] 5 then "five"
   [] 6 then "six"
   [] 7 then "seven"
   [] 8 then "eight"
   [] 9 then "nine"
   end
end

fun {Teens N}
   case N
   of 10 then "ten"
   [] 11 then "eleven"
   [] 12 then "twelve"
   [] 13 then "thirteen"
   [] 14 then "fourteen"
   [] 15 then "fifteen"
   [] 16 then "sixteen"
   [] 17 then "seventeen"
   [] 18 then "eighteen"
   [] 19 then "nineteen"
   end
end

fun {Tens N}
   case N
   of 2 then "twenty"
   [] 3 then "thirty"
   [] 4 then "forty"
   [] 5 then "fifty"
   [] 6 then "sixty"
   [] 7 then "seventy"
   [] 8 then "eighty"
   [] 9 then "ninety"
   end
end

fun {NumberToString N}
   if N == 0 then "zero"
   elseif N < 10 then {Units N}
   elseif N < 20 then {Teens N}
   elseif N < 100 then
      if N mod 10 == 0 then {Tens N div 10}
      else {Append {Tens N div 10} {Append " " {Units N mod 10}}}
      end
   else
      if N mod 100 == 0 then {Append {Units N div 100} " hundred"}
      else {Append {Units N div 100} {Append " hundred " {NumberToString N mod 100}}}
      end
   end
end

class Expression
   meth print
      {System.showInfo "Base method does nothing"}
   end
   meth eval(R)
      {System.showInfo "Base method does nothing"}
   end
   meth toString(S)
      {System.showInfo "Base method does nothing"}
   end
end

class Num from Expression
   attr n:0
   meth init(Val)
      n := Val
   end
   meth print
      {System.showInfo @n}
   end
   meth eval(R)
      R = @n
   end
   meth toString(S)
      S = {NumberToString @n}
   end
end

class Sum from Expression
   attr left right
   meth init(L R)
      left := L
      right := R
   end
   meth print
      {@left print} {System.showInfo "+"} {@right print}
   end
   meth eval(R)
      local LR RR in
         {@left eval(LR)}
         {@right eval(RR)}
         R = LR + RR
      end
   end
   meth toString(S)
      local LS RS in
         {@left toString(LS)}
         {@right toString(RS)}
         S = {Append LS {Append " plus " RS}}
      end
   end
end

class Difference from Expression
   attr left right
   meth init(L R)
      left := L
      right := R
   end
   meth print
      {@left print} {System.showInfo "-"} {@right print}
   end
   meth eval(R)
      local LR RR in
         {@left eval(LR)}
         {@right eval(RR)}
         R = LR - RR
      end
   end
   meth toString(S)
      local LS RS in
         {@left toString(LS)}
         {@right toString(RS)}
         S = {Append LS {Append " minus " RS}}
      end
   end
end

class Multiplication from Expression
   attr left right
   meth init(L R)
      left := L
      right := R
   end
   meth print
      {@left print} {System.showInfo "*"} {@right print}
   end
   meth eval(R)
      local LR RR in
         {@left eval(LR)}
         {@right eval(RR)}
         R = LR * RR
      end
   end
   meth toString(S)
      local LS RS in
         {@left toString(LS)}
         {@right toString(RS)}
         S = {Append LS {Append " times " RS}}
      end
   end
end

class Modulo from Expression
   attr left right
   meth init(L R)
      left := L
      right := R
   end
   meth print
      {@left print} {System.showInfo "mod"} {@right print}
   end
   meth eval(R)
      local LR RR in
         {@left eval(LR)}
         {@right eval(RR)}
         R = LR mod RR
      end
   end
   meth toString(S)
      local LS RS in
         {@left toString(LS)}
         {@right toString(RS)}
         S = {Append LS {Append " modulo " RS}}
      end
   end
end
