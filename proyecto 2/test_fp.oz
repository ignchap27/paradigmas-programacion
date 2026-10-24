\insert 'mozart-fp.oz'

declare TestResult TestTask1 TestTask2 TestTutorial RedexInfo

proc {TestResult TestName Expected Actual}
   if Expected == Actual then
      {Show testpassed(TestName)}
   else
      {Show testfailed(TestName expected:Expected actual:Actual)}
   end
end

fun {RedexInfo R}
   if R == none then none
   else redex(R.name {Map R.args GraphToRecord} {GraphToRecord R.root})
   end
end

proc {TestTask1}
   P1 = {GraphGeneration "fun square x = x * x\nsquare square 3"}
   P2 = {GraphGeneration "fun sqr x = (x+1) * (x-1)\nsqr 4"}
   P3 = {GraphGeneration "fun fourtimes x = var y = x*x in y+y\nfourtimes 2"}
   P4 = {GraphGeneration "fun sum_n x y z n = (x + y + z) * n\nsum_n 1 sum_n 1 1 1 2 3 2"}
   P5 = {GraphGeneration "fun arithmetic x y = ((x + y) / (x - y)) * 2\narithmetic arithmetic 5 6 arithmetic 2 11"}
   P6 = {GraphGeneration "fun var_use x = var y = x+x in var z = y * 2 in z - 3\nvar_use var_use 16"}
   Body3 = @(P3.funs.fourtimes.body)
in
   {TestResult square_graph '@'(square '@'(square 3)) {GraphToRecord P1.graph}}
   {TestResult square_body '@'('@'('*' x) x) {GraphToRecord P1.funs.square.body}}
   {TestResult square_params [x] P1.funs.square.params}
   {TestResult sqr_body '@'('@'('*' '@'('@'('+' x) 1)) '@'('@'('-' x) 1)) {GraphToRecord P2.funs.sqr.body}}
   {TestResult fourtimes_body '@'('@'('+' '@'('@'('*' x) x)) '@'('@'('*' x) x)) {GraphToRecord P3.funs.fourtimes.body}}
   {TestResult fourtimes_shared true case Body3 of app(L R) then {RightChild L} == R end}
   {TestResult sum_n_graph '@'('@'('@'('@'(sum_n 1) '@'('@'('@'('@'(sum_n 1) 1) 1) 2)) 3) 2) {GraphToRecord P4.graph}}
   {TestResult arithmetic_graph '@'('@'(arithmetic '@'('@'(arithmetic 5) 6)) '@'('@'(arithmetic 2) 11)) {GraphToRecord P5.graph}}
   {TestResult arithmetic_body '@'('@'('*' '@'('@'('/' '@'('@'('+' x) y)) '@'('@'('-' x) y))) 2) {GraphToRecord P5.funs.arithmetic.body}}
   {TestResult var_use_body '@'('@'('-' '@'('@'('*' '@'('@'('+' x) x)) 2)) 3) {GraphToRecord P6.funs.var_use.body}}
   {TestResult var_use_graph '@'(var_use '@'(var_use 16)) {GraphToRecord P6.graph}}
end

proc {TestTask2}
   P1 = {GraphGeneration "fun square x = x * x\nsquare square 3"}
   P2 = {GraphGeneration "fun twice x = x + x\ntwice 5"}
   P3 = {GraphGeneration "fun sum_n x y z n = (x + y + z) * n\nsum_n 1 sum_n 1 1 1 2 3 2"}
   Funs = P1.funs
   Sq3 = {App {Leaf square} {Leaf 3}}
in
   {TestResult next_square redex(square ['@'(square 3)] '@'(square '@'(square 3))) {RedexInfo {NextReduction P1}}}
   {TestResult next_square_root true {NextReduction P1}.root == P1.graph}
   {TestResult next_twice redex(twice [5] '@'(twice 5)) {RedexInfo {NextReduction P2}}}
   {TestResult next_sum_n_arity 4 {Length {NextReduction P3}.args}}
   {TestResult next_plus redex('+' [2 3] '@'('@'('+' 2) 3)) {RedexInfo {NextReduction program(funs: Funs graph: {MakeOp "+" {Leaf 2} {Leaf 3}})}}}
   {TestResult next_plus_inner redex(square [3] '@'(square 3)) {RedexInfo {NextReduction program(funs: Funs graph: {MakeOp "+" Sq3 {Leaf 2}})}}}
   {TestResult next_plus_right redex(square [3] '@'(square 3)) {RedexInfo {NextReduction program(funs: Funs graph: {MakeOp "+" {Leaf x} Sq3})}}}
   {TestResult next_unknown none {RedexInfo {NextReduction program(funs: Funs graph: {MakeOp "+" {Leaf x} {Leaf x}})}}}
   {TestResult next_number none {RedexInfo {NextReduction program(funs: Funs graph: {Leaf 81})}}}
   {TestResult next_partial none {RedexInfo {NextReduction program(funs: Funs graph: {Leaf square})}}}
end

proc {TestTutorial}
   Funs = {GraphGeneration "fun square x = x * x\nsquare 3"}.funs
   S = {App {Leaf square} {Leaf 3}}
   Root = {MakeOp "*" S S}
   P = program(funs: Funs graph: Root)
   F = funs(f: def(params: [a b] body: nil))
   E3 = {Leaf 3}
   Over = {App {App {App {Leaf f} {Leaf 1}} {Leaf 2}} E3}
   P5 = {GraphGeneration "fun five = 5\nfive"}
in
   {TestResult tutorial_step1 true {NextReduction P}.root == S}
   S := @{MakeOp "*" {Leaf 3} {Leaf 3}}
   {TestResult tutorial_step2 redex('*' [3 3] '@'('@'('*' 3) 3)) {RedexInfo {NextReduction P}}}
   {TestResult tutorial_step2_root true {NextReduction P}.root == S}
   S := leaf(9)
   {TestResult tutorial_step3 redex('*' [9 9] '@'('@'('*' 9) 9)) {RedexInfo {NextReduction P}}}
   Root := leaf(81)
   {TestResult tutorial_step4 none {NextReduction P}}
   {TestResult tutorial_overapplied redex(f [1 2] '@'('@'(f 1) 2)) {RedexInfo {NextReduction program(funs: F graph: Over)}}}
   {TestResult tutorial_caf redex(five nil five) {RedexInfo {NextReduction P5}}}
   {TestResult tutorial_indirection redex(square [3] '@'(square 3)) {RedexInfo {NextReduction program(funs: Funs graph: {MakeOp "+" {NewCell ind({App {Leaf square} {Leaf 3}})} {Leaf 1}})}}}
end

{TestTask1}
{TestTask2}
{TestTutorial}
