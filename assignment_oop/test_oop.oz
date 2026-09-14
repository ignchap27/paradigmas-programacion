\insert 'assignment_oop/matrix.oz'
\insert 'assignment_oop/mastermind.oz'
\insert 'assignment_oop/language.oz'

declare
proc {TestResult TestName Expected Actual}
   if Expected == Actual then
      {Show testpassed(TestName)}
   else
      {Show testfailed(TestName expected:Expected actual:Actual)}
   end
end

declare
fun {PlayUntilOver Game}
   R = {Game playRound($)}
in
   if R.gameOver then R else {PlayUntilOver Game} end
end

declare
proc {TestMatrix}
   M = {New Matrix init([[1 2] [3 4]])}
in
   {TestResult matrixgetelement 3 {M getElement(2 1 $)}}
   {TestResult matrixsumrow 7 {M sumRow(2 $)}}
end

declare
proc {TestMastermind}
   Maker = {New CodeMaker init()}
   Breaker = {New CodeBreaker init()}
   Game = {New MastermindGame init(Maker Breaker)}
   F
in
   {Maker setSecretCode([red blue green yellow] _)}
   F = {Maker evaluateGuess([red green blue orange] $)}
   {TestResult mastermindfeedback [1 2] [F.blackClues F.whiteClues]}

   {Game startGame(_)}
   {Maker setSecretCode([purple purple orange orange] _)}
   {TestResult mastermindwins true {PlayUntilOver Game}.gameWon}
end

declare Test

proc {Test Name Exp}
   local V S in
      {Exp eval(V)}
      {Exp toString(S)}
      {System.showInfo Name}
      {System.showInfo "  print:"}
      {Exp print}
      {System.showInfo {Append "  eval: " {Int.toString V}}}
      {System.showInfo {Append "  toString: " S}}
   end
end

declare
proc {TestLanguage}
   N3 = {New Num init(3)}
   N4 = {New Num init(4)}
   N7 = {New Num init(7)}
   N20 = {New Num init(20)}
   N123 = {New Num init(123)}
   N999 = {New Num init(999)}
in
   {Test "Num: 3" N3}
   {Test "Num: 999" N999}
   {Test "Sum: 3 + 4" {New Sum init(N3 N4)}}
   {Test "Difference: 123 - 20" {New Difference init(N123 N20)}}
   {Test "Multiplication: 7 * 4" {New Multiplication init(N7 N4)}}
   {Test "Modulo: 123 mod 20" {New Modulo init(N123 N20)}}
   {Test "Complex: ((3 + 4) * 20 - 123) mod 7"
    {New Modulo init(
        {New Difference init(
            {New Multiplication init({New Sum init(N3 N4)} N20)}
            N123)}
        N7)}}
end

{TestMatrix}
{TestMastermind}
{TestLanguage}
