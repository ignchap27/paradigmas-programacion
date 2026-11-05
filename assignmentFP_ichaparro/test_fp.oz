\insert 'assignmentFP/language.oz'
\insert 'assignmentFP/matrix_fp.oz'
\insert 'assignmentFP/mastermind_fp.oz'

declare
proc {TestResult TestName Expected Actual}
   if Expected == Actual then
      {Show testpassed(TestName)}
   else
      {Show testfailed(TestName expected:Expected actual:Actual)}
   end
end

proc {TestTask1}
   {TestResult evalNum 7 {Eval num(7)}}
   {TestResult evalSum 7 {Eval sum(num(3) num(4))}}
   {TestResult evalDifference 6 {Eval difference(num(10) num(4))}}
   {TestResult evalMultiplication 12 {Eval multiplication(num(3) num(4))}}
   {TestResult evalModulo 1 {Eval modulo(num(10) num(3))}}
   {TestResult evalNested 23 {Eval sum(num(3) multiplication(num(4) num(5)))}}
   {TestResult toStringSum "three plus four" {ToString sum(num(3) num(4))}}
   {TestResult toStringDifference "ten minus four" {ToString difference(num(10) num(4))}}
   {TestResult toStringMultiplication "three times four" {ToString multiplication(num(3) num(4))}}
   {TestResult toStringModulo "ten modulo three" {ToString modulo(num(10) num(3))}}
   {TestResult toStringNested "three plus four times five" {ToString sum(num(3) multiplication(num(4) num(5)))}}
   {TestResult toStringZero "zero" {ToString num(0)}}
   {TestResult toStringTeen "fifteen" {ToString num(15)}}
   {TestResult toStringTens "forty" {ToString num(40)}}
   {TestResult toStringBig "nine hundred ninety nine" {ToString num(999)}}
   {TestResult toStringHundred "one hundred five" {ToString num(105)}}
   {Print sum(num(3) multiplication(num(4) num(5)))}
end

proc {TestTask2}
   M = [[1 2 3] [4 5 6] [7 8 9]]
in
   {TestResult getSize 3 {GetSize M}}
   {TestResult getElement 6 {GetElement M 2 3}}
   {TestResult getElementInvalid 142857 {GetElement M 4 1}}
   {TestResult getRow [4 5 6] {GetRow M 2}}
   {TestResult getRowInvalid 142857 {GetRow M 0}}
   {TestResult getColumn [2 5 8] {GetColumn M 2}}
   {TestResult getColumnInvalid 142857 {GetColumn M 5}}
   {TestResult sumRow 6 {SumRow M 1}}
   {TestResult sumRowInvalid 142857 {SumRow M 9}}
   {TestResult productRow 120 {ProductRow M 2}}
   {TestResult sumColumn 18 {SumColumn M 3}}
   {TestResult productColumn 28 {ProductColumn M 1}}
   {TestResult productColumnInvalid 142857 {ProductColumn M 0}}
   {TestResult sumAll 45 {SumAll M}}
   {TestResult sumAllEmpty 0 {SumAll nil}}
   {TestResult productAll 362880 {ProductAll M}}
   {TestResult productAllEmpty 1 {ProductAll nil}}
   {TestResult productAllZero 0 {ProductAll [[1 0] [3 4]]}}
   {TestResult display nil {Display M}}
end

\insert 'assignmentFP/language.oz'
\insert 'assignmentFP/matrix_fp.oz'
\insert 'assignmentFP/mastermind_fp.oz'

declare
proc {TestResult TestName Expected Actual}
   if Expected == Actual then
      {Show testpassed(TestName)}
   else
      {Show testfailed(TestName expected:Expected actual:Actual)}
   end
end

proc {TestTask1}
   {TestResult evalNum 7 {Eval num(7)}}
   {TestResult evalSum 7 {Eval sum(num(3) num(4))}}
   {TestResult evalDifference 6 {Eval difference(num(10) num(4))}}
   {TestResult evalMultiplication 12 {Eval multiplication(num(3) num(4))}}
   {TestResult evalModulo 1 {Eval modulo(num(10) num(3))}}
   {TestResult evalNested 23 {Eval sum(num(3) multiplication(num(4) num(5)))}}
   {TestResult toStringSum "three plus four" {ToString sum(num(3) num(4))}}
   {TestResult toStringDifference "ten minus four" {ToString difference(num(10) num(4))}}
   {TestResult toStringMultiplication "three times four" {ToString multiplication(num(3) num(4))}}
   {TestResult toStringModulo "ten modulo three" {ToString modulo(num(10) num(3))}}
   {TestResult toStringNested "three plus four times five" {ToString sum(num(3) multiplication(num(4) num(5)))}}
   {TestResult toStringZero "zero" {ToString num(0)}}
   {TestResult toStringTeen "fifteen" {ToString num(15)}}
   {TestResult toStringTens "forty" {ToString num(40)}}
   {TestResult toStringBig "nine hundred ninety nine" {ToString num(999)}}
   {TestResult toStringHundred "one hundred five" {ToString num(105)}}
   {Print sum(num(3) multiplication(num(4) num(5)))}
end

proc {TestTask2}
   M = [[1 2 3] [4 5 6] [7 8 9]]
in
   {TestResult getSize 3 {GetSize M}}
   {TestResult getElement 6 {GetElement M 2 3}}
   {TestResult getElementInvalid 142857 {GetElement M 4 1}}
   {TestResult getRow [4 5 6] {GetRow M 2}}
   {TestResult getRowInvalid 142857 {GetRow M 0}}
   {TestResult getColumn [2 5 8] {GetColumn M 2}}
   {TestResult getColumnInvalid 142857 {GetColumn M 5}}
   {TestResult sumRow 6 {SumRow M 1}}
   {TestResult sumRowInvalid 142857 {SumRow M 9}}
   {TestResult productRow 120 {ProductRow M 2}}
   {TestResult sumColumn 18 {SumColumn M 3}}
   {TestResult productColumn 28 {ProductColumn M 1}}
   {TestResult productColumnInvalid 142857 {ProductColumn M 0}}
   {TestResult sumAll 45 {SumAll M}}
   {TestResult sumAllEmpty 0 {SumAll nil}}
   {TestResult productAll 362880 {ProductAll M}}
   {TestResult productAllEmpty 1 {ProductAll nil}}
   {TestResult productAllZero 0 {ProductAll [[1 0] [3 4]]}}
   {TestResult display nil {Display M}}
end

proc {TestTask3}
   CM = {StartGame [red blue green yellow]}
   R1 = {PlayRound CM [red blue orange purple]}
   Lost = {FoldL [1 2 3 4 5 6 7 8 9 10 11 12]
           fun {$ C _} {PlayRound C [orange orange orange orange]}.codemaker end CM}
in
   {TestResult secretCode [red blue green yellow] {GetSecretCode CM}}
   {TestResult allBlack 4 {EvaluateGuess CM [red blue green yellow]}.blackClues}
   {TestResult allWhite 4 {EvaluateGuess CM [blue green yellow red]}.whiteClues}
   {TestResult mixedBlack 2 {EvaluateGuess CM [red blue yellow orange]}.blackClues}
   {TestResult mixedWhite 1 {EvaluateGuess CM [red blue yellow orange]}.whiteClues}
   {TestResult repeatedColor feedback(blackClues:1 whiteClues:0 'ClueList':[black])
    {EvaluateGuess CM [red red red red]}}
   {TestResult clueList [black black white] {EvaluateGuess CM [red blue yellow orange]}.'ClueList'}
   {TestResult currentRoundStart 1 {GetCurrentRound CM}}
   {TestResult remainingStart 11 {GetRemainingRounds CM}}
   {TestResult roundsPlayed 1 R1.rounds}
   {TestResult currentRoundAfter 2 {GetCurrentRound R1.codemaker}}
   {TestResult remainingAfter 10 {GetRemainingRounds R1.codemaker}}
   {TestResult statusPlaying playing {GetGameStatus R1.feedback R1.rounds}}
   {TestResult statusWon won {GetGameStatus {EvaluateGuess CM [red blue green yellow]} 3}}
   {TestResult statusLost lost {GetGameStatus {EvaluateGuess Lost [orange orange orange orange]} Lost.rounds}}
end

{TestTask1}
{TestTask2}
{TestTask3}

