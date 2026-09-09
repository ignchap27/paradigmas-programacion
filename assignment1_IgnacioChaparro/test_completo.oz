%% ============================================================
%% test_completo.oz
%% Batería de pruebas para las 5 tareas de ISIS-4217.
%% Usa los nombres de función EXACTOS que pide el enunciado
%% (con mayúscula inicial, como exige la sintaxis de Oz para
%% variables/procedimientos).
%% ============================================================

\insert 'assignment1_IgnacioChaparro/list.oz'
\insert 'assignment1_IgnacioChaparro/poly.oz' 
\insert 'assignment1_IgnacioChaparro/tree.oz'
\insert 'assignment1_IgnacioChaparro/integral.oz'
\insert 'assignment1_IgnacioChaparro/recordR.oz'

declare
Passed = {NewCell 0}
Failed = {NewCell 0}

proc {TestResult TestName Expected Actual}
   if Expected == Actual then
      Passed := @Passed + 1
      {Show testpassed(TestName)}
   else
      Failed := @Failed + 1
      {Show testfailed(TestName expected:Expected actual:Actual)}
   end
end

fun {Abs X}
   if X < 0.0 then ~X else X end
end

fun {CloseEnough X Y}
   {Abs X-Y} < 0.0001
end

proc {TestResultFloat TestName Expected Actual}
   if {CloseEnough Expected Actual} then
      Passed := @Passed + 1
      {Show testpassed(TestName)}
   else
      Failed := @Failed + 1
      {Show testfailed(TestName expected:Expected actual:Actual)}
   end
end

%% ============================================================
%% TASK 1: OddSumEvenProduct
%% ============================================================
proc {TestTask1}
   local
      R1 R2 R3 R4 R5 R6 R7 R8
   in
      {Show '=== TASK 1: OddSumEvenProduct ==='}

      R1 = {OddSumEvenProduct [1 2 3 4 5]}
      {TestResult 'T1 Basic case' 8#9 R1}

      R2 = {OddSumEvenProduct [1]}
      {TestResult 'T1 Single element (odd pos only)' 1#1 R2}

      R3 = {OddSumEvenProduct [5 3]}
      {TestResult 'T1 Two elements' 3#5 R3}

      R4 = {OddSumEvenProduct nil}
      {TestResult 'T1 Empty list' 1#0 R4}

      R5 = {OddSumEvenProduct [~1 2 3 ~4 ~5]}
      {TestResult 'T1 Negative numbers' ~8#~3 R5}

      R6 = {OddSumEvenProduct [1 0 3 0 5]}
      {TestResult 'T1 Zero in even position (product=0)' 0#9 R6}

      R7 = {OddSumEvenProduct [7 2 9 4]}
      {TestResult 'T1 Four elements' 8#16 R7}

      R8 = {OddSumEvenProduct [~2 ~3 ~4]}
      {TestResult 'T1 All negative' ~3#~6 R8}
   end
end

%% ============================================================
%% TASK 2: AddPolynomials
%% ============================================================
proc {TestTask2}
   local
      R1 R2 R3 R4 R5 R6 R7 R8
   in
      {Show '=== TASK 2: AddPolynomials ==='}

      R1 = {AddPolynomials [1 ~2] [4 3 2 1]}
      {TestResult 'T2 PDF example 1' [4 3 3 ~1] R1}

      R2 = {AddPolynomials [3 0 0 4 1 ~5] [0 2 ~1 1 4 10]}
      {TestResult 'T2 PDF example 2' [3 2 ~1 5 5 5] R2}

      R3 = {AddPolynomials [1 2 3 4 5] [1 1]}
      {TestResult 'T2 First polynomial longer' [1 2 3 5 6] R3}

      %% NOTE: [2 3] padded is [0 0 0 2 3]; sum with [1 2 3 4 5]
      %% is [1 2 3 6 8]  (NOT [1 2 5 7 5] -- watch out if you copied
      %% that expected value from another test file, it's wrong)
      R4 = {AddPolynomials [2 3] [1 2 3 4 5]}
      {TestResult 'T2 Second polynomial longer' [1 2 3 6 8] R4}

      R5 = {AddPolynomials nil [1 2 3]}
      {TestResult 'T2 First polynomial empty' [1 2 3] R5}

      R6 = {AddPolynomials nil nil}
      {TestResult 'T2 Both polynomials empty' nil R6}

      R7 = {AddPolynomials [1 2] [~1 ~2]}
      {TestResult 'T2 Coefficients cancel to zero' [0 0] R7}

      R8 = {AddPolynomials [5] [3]}
      {TestResult 'T2 Single-term polynomials' [8] R8}
   end
end

%% ============================================================
%% TASK 3: InorderPreorder2BT / InorderPostorder2BT
%% ============================================================
proc {TestTask3}
   local
      Tree1 R1 R2
      Tree2 R3 R4
      R5 R6
      TreeLeft R7 R8
      TreeRight R9 R10
      TreeChar R11
      TreeMed R12 R13
   in
      {Show '=== TASK 3: Binary Tree Construction ==='}

      Tree1 = tree(1 tree(2 nil nil) tree(3 nil nil))
      R1 = {InorderPreorder2BT [2 1 3] [1 2 3]}
      {TestResult 'T3 Simple tree (in+pre)' Tree1 R1}

      R2 = {InorderPostorder2BT [2 1 3] [2 3 1]}
      {TestResult 'T3 Simple tree (in+post)' Tree1 R2}

      Tree2 = tree(5 nil nil)
      R3 = {InorderPreorder2BT [5] [5]}
      {TestResult 'T3 Single node (in+pre)' Tree2 R3}

      R4 = {InorderPostorder2BT [5] [5]}
      {TestResult 'T3 Single node (in+post)' Tree2 R4}

      R5 = {InorderPreorder2BT nil nil}
      {TestResult 'T3 Empty tree (in+pre)' nil R5}

      R6 = {InorderPostorder2BT nil nil}
      {TestResult 'T3 Empty tree (in+post)' nil R6}

      TreeLeft = tree(3 tree(2 tree(1 nil nil) nil) nil)
      R7 = {InorderPreorder2BT [1 2 3] [3 2 1]}
      {TestResult 'T3 Left-skewed (in+pre)' TreeLeft R7}

      R8 = {InorderPostorder2BT [1 2 3] [1 2 3]}
      {TestResult 'T3 Left-skewed (in+post)' TreeLeft R8}

      TreeRight = tree(1 nil tree(2 nil tree(3 nil nil)))
      R9 = {InorderPreorder2BT [1 2 3] [1 2 3]}
      {TestResult 'T3 Right-skewed (in+pre)' TreeRight R9}

      R10 = {InorderPostorder2BT [1 2 3] [3 2 1]}
      {TestResult 'T3 Right-skewed (in+post)' TreeRight R10}

      TreeChar = tree(a tree(b nil nil) tree(c nil nil))
      R11 = {InorderPreorder2BT [b a c] [a b c]}
      {TestResult 'T3 Character values' TreeChar R11}

      TreeMed = tree(1 tree(2 tree(4 nil nil) tree(5 nil nil))
                       tree(3 tree(6 nil nil) tree(7 nil nil)))
      R12 = {InorderPreorder2BT [4 2 5 1 6 3 7] [1 2 4 5 3 6 7]}
      {TestResult 'T3 Medium tree, 7 nodes (in+pre)' TreeMed R12}

      R13 = {InorderPostorder2BT [4 2 5 1 6 3 7] [4 5 2 6 7 3 1]}
      {TestResult 'T3 Medium tree, 7 nodes (in+post)' TreeMed R13}
   end
end
%% NOTE: your SplitInorder assumes no repeated values in the inorder
%% list (it matches the first occurrence). If your professor tests
%% with duplicate values (e.g. In=[1 2 1 3]) the reconstruction will
%% be wrong -- the assignment spec doesn't mention duplicates, so
%% this is very likely not an issue, just flagging it.

%% ============================================================
%% TASK 4: Integral (Simpson's rule)
%% ============================================================
proc {TestTask4}
   local
      Linear Quadratic Constant Cubic Shifted
      R1 R2 R3 R4 R5 R6
   in
      {Show '=== TASK 4: Simpson Rule Integration ==='}

      fun {Linear X} X end
      fun {Quadratic X} X*X end
      fun {Constant X} 1.0 end
      fun {Cubic X} X*X*X end
      fun {Shifted X} X*X + 2.0*X + 1.0 end

      R1 = {Integral Constant 0.0 1.0 2}
      {TestResultFloat 'T4 Constant function' 1.0 R1}

      R2 = {Integral Linear 0.0 2.0 4}
      {TestResultFloat 'T4 Linear function' 2.0 R2}

      R3 = {Integral Quadratic 0.0 1.0 6}
      {TestResultFloat 'T4 Quadratic, n=6' 0.333333 R3}

      R4 = {Integral Quadratic 0.0 1.0 100}
      {TestResultFloat 'T4 Quadratic, n=100 (precision)' 0.333333 R4}

      R5 = {Integral Cubic ~1.0 1.0 8}
      {TestResultFloat 'T4 Odd function, symmetric interval' 0.0 R5}

      R6 = {Integral Shifted ~2.0 2.0 10}
      {TestResultFloat 'T4 Shifted quadratic, negative interval' 9.333333 R6}
   end
end

%% ============================================================
%% TASK 5: RecordRelation
%% ============================================================
proc {TestTask5}
   local
      R1 R2 R3 R4 R5 R6 R7 R8 R9 R10 R11 R12 R13 R14 R15 R16
      Res1 Res2 Res3 Res4 Res5 Res6 Res7 Res8 Res9 Res10 Res11 Res12
   in
      {Show '=== TASK 5: Record Relations ==='}

      R1 = person(name:john age:25 city:bogota)
      R2 = person(name:john age:25 city:bogota)
      Res1 = {RecordRelation R1 R2}
      {TestResult 'T5 Equal records' equal Res1}

      Res2 = {RecordRelation R1 R1}
      {TestResult 'T5 Record equal to itself' equal Res2}

      R3 = person(name:mary age:30 city:medellin)
      Res3 = {RecordRelation R1 R3}
      {TestResult 'T5 Equivalent (same shape, diff values)' equivalent Res3}

      R4 = person(name:john age:25)
      Res4 = {RecordRelation R4 R1}
      {TestResult 'T5 Subsimilar (R4 subset of R1)' subsimilar Res4}

      Res5 = {RecordRelation R1 R4}
      {TestResult 'T5 Subsimilar reversed (R1 superset of R4)' subsimilar Res5}

      R5 = car(brand:toyota model:corolla)
      Res6 = {RecordRelation R1 R5}
      {TestResult 'T5 Different labels, no overlap' different Res6}

      R6 = empty()
      R7 = empty()
      Res7 = {RecordRelation R6 R7}
      {TestResult 'T5 Two empty records' equal Res7}

      R8 = data(value:42)
      Res8 = {RecordRelation R6 R8}
      {TestResult 'T5 Empty record vs non-empty' subsimilar Res8}

      R9 = person(id:123 salary:5000)
      Res9 = {RecordRelation R1 R9}
      {TestResult 'T5 Same label, zero field overlap' different Res9}

      R10 = person(name:john age:25)
      R11 = person(name:john height:180)
      Res10 = {RecordRelation R10 R11}
      {TestResult 'T5 Partial overlap, not subset' different Res10}

      R12 = person(name:john tags:[sql oz])
      R13 = person(name:john tags:[sql oz])
      Res11 = {RecordRelation R12 R13}
      {TestResult 'T5 Equal records with list-valued field' equal Res11}

      R14 = person(name:john tags:[sql oz])
      R15 = person(name:john tags:[python oz])
      Res12 = {RecordRelation R14 R15}
      {TestResult 'T5 Equivalent, list-valued field differs' equivalent Res12}

      %% ---- INFORMATIONAL ONLY (not asserted) ----
      %% The assignment text doesn't clarify whether 'subsimilar'
      %% requires matching labels. Your current implementation does
      %% NOT require it. This just shows you the actual result so you
      %% can judge/ask your professor whether it should be 'different'
      %% instead.
      R16 = foo(a:1 b:2)
      {Show ambiguous_case(
          note: 'same fields+values, DIFFERENT label -- ask your prof if this should be "different" instead'
          result: {RecordRelation R16 bar(a:1 b:2)})}
   end
end

%% ============================================================
%% Run everything and print a summary
%% ============================================================
{TestTask1}
{TestTask2}
{TestTask3}
{TestTask4}
{TestTask5}

{Show '================================'}
{Show summary(passed:@Passed failed:@Failed)}
{Show '================================'}
