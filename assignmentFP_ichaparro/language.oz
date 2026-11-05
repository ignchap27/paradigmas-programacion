declare Units Teens Tens NumberToString
declare Print PrintNum PrintSum PrintDifference PrintMultiplication PrintModulo
declare Eval EvalNum EvalSum EvalDifference EvalMultiplication EvalModulo
declare ToString

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

proc {Print E}
   case E
   of num(I) then {PrintNum I}
   [] sum(L R) then {PrintSum L R}
   [] difference(L R) then {PrintDifference L R}
   [] multiplication(L R) then {PrintMultiplication L R}
   [] modulo(L R) then {PrintModulo L R}
   end
end

proc {PrintNum I}
   {Show I}
end

proc {PrintSum Left Right}
   {Print Left} {System.showInfo "+"} {Print Right}
end

proc {PrintDifference Left Right}
   {Print Left} {System.showInfo "-"} {Print Right}
end

proc {PrintMultiplication Left Right}
   {Print Left} {System.showInfo "*"} {Print Right}
end

proc {PrintModulo Left Right}
   {Print Left} {System.showInfo "mod"} {Print Right}
end

fun {Eval E}
   case E
   of num(I) then {EvalNum I}
   [] sum(L R) then {EvalSum {Eval L} {Eval R}}
   [] difference(L R) then {EvalDifference {Eval L} {Eval R}}
   [] multiplication(L R) then {EvalMultiplication {Eval L} {Eval R}}
   [] modulo(L R) then {EvalModulo {Eval L} {Eval R}}
   end
end

fun {EvalNum I}
   I
end

fun {EvalSum Left Right}
   Left + Right
end

fun {EvalDifference Left Right}
   Left - Right
end

fun {EvalMultiplication Left Right}
   Left * Right
end

fun {EvalModulo Left Right}
   Left mod Right
end

fun {ToString E}
   case E
   of num(I) then {NumberToString I}
   [] sum(L R) then {Append {ToString L} {Append " plus " {ToString R}}}
   [] difference(L R) then {Append {ToString L} {Append " minus " {ToString R}}}
   [] multiplication(L R) then {Append {ToString L} {Append " times " {ToString R}}}
   [] modulo(L R) then {Append {ToString L} {Append " modulo " {ToString R}}}
   end
end
