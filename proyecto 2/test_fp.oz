\insert 'mozart-fp.oz'

declare TestResult TestFloat Build RedexInfo ReduceN SharedBody
TestTask1 TestTask2 TestTask3 TestTask4 TestParser TestFunctional TestImprovements

proc {TestResult TestName Expected Actual}
   if Expected == Actual then
      {Show testpassed(TestName)}
   else
      {Show testfailed(TestName expected:Expected actual:Actual)}
   end
end

proc {TestFloat TestName Expected Actual}
   if {IsFloat Actual} andthen {Abs Expected - Actual} < 0.0001 then
      {Show testpassed(TestName)}
   else
      {Show testfailed(TestName expected:Expected actual:Actual)}
   end
end

fun {Build Funs E}
   Addr Heap in
   Addr#Heap = {Instantiate E nil heap}
   program(funs: Funs heap: Heap calls: [Addr] graph: Addr)
end

fun {RedexInfo P}
   R = {NextReduction P}
in
   if R == none then none
   else redex(R.name {Map R.args fun {$ A} {NodeToRecord A P.heap} end} {NodeToRecord R.root P.heap})
   end
end

fun {ReduceN P N}
   if N == 0 then P else {ReduceN {Reduce P} N-1} end
end

fun {SharedBody P}
   case P.heap.(P.graph) of ind(A) then
      case P.heap.A of app(L R) then P.heap.L.2 == R end
   end
end

proc {TestTask1}
   P1 = {GraphGeneration "fun square x = x * x\nsquare square 3"}
   P2 = {GraphGeneration "fun sqr x = (x+1) * (x-1)\nsqr 4"}
   P3 = {GraphGeneration "fun fourtimes x = var y = x*x in y+y\nfourtimes 2"}
   P4 = {GraphGeneration "fun sum_n x y z n = (x + y + z) * n\nsum_n 1 sum_n 1 1 1 2 3 2"}
   P5 = {GraphGeneration "fun arithmetic x y = ((x + y) / (x - y)) * 2\narithmetic arithmetic 5 6 arithmetic 2 11"}
   P6 = {GraphGeneration "fun var_use x = var y = x+x in var z = y * 2 in z - 3\nvar_use var_use 16"}
in
   {TestResult square_graph '@'(square '@'(square 3)) {GraphToRecord P1}}
   {TestResult square_body '@'('@'('*' x) x) P1.funs.square.body}
   {TestResult square_params [x] P1.funs.square.params}
   {TestResult sqr_body '@'('@'('*' '@'('@'('+' x) 1)) '@'('@'('-' x) 1)) P2.funs.sqr.body}
   {TestResult fourtimes_body let(y '@'('@'('*' x) x) '@'('@'('+' y) y)) P3.funs.fourtimes.body}
   {TestResult sum_n_graph '@'('@'('@'('@'(sum_n 1) '@'('@'('@'('@'(sum_n 1) 1) 1) 2)) 3) 2) {GraphToRecord P4}}
   {TestResult arithmetic_graph '@'('@'(arithmetic '@'('@'(arithmetic 5) 6)) '@'('@'(arithmetic 2) 11)) {GraphToRecord P5}}
   {TestResult arithmetic_body '@'('@'('*' '@'('@'('/' '@'('@'('+' x) y)) '@'('@'('-' x) y))) 2) P5.funs.arithmetic.body}
   {TestResult var_use_body let(y '@'('@'('+' x) x) let(z '@'('@'('*' y) 2) '@'('@'('-' z) 3))) P6.funs.var_use.body}
   {TestResult var_use_graph '@'(var_use '@'(var_use 16)) {GraphToRecord P6}}
   {TestResult heap_nodes heap(leaf(square) leaf(square) leaf(3) app(2 3) app(1 4)) P1.heap}
   {TestResult root_address 5 P1.graph}
end

proc {TestTask2}
   P1 = {GraphGeneration "fun square x = x * x\nsquare square 3"}
   P2 = {GraphGeneration "fun twice x = x + x\ntwice 5"}
   P3 = {GraphGeneration "fun sum_n x y z n = (x + y + z) * n\nsum_n 1 sum_n 1 1 1 2 3 2"}
   P4 = {GraphGeneration "fun f a b = a\nf 1 2 3"}
   P5 = {GraphGeneration "fun five = 5\nfive"}
   Funs = P1.funs
   Sq3 = '@'(square 3)
   Ind = program(funs: Funs
                 heap: heap(leaf(square) leaf(3) app(1 2) ind(3) leaf('+') app(5 4) leaf(1) app(6 7))
                 calls: [8] graph: 8)
in
   {TestResult next_square redex(square ['@'(square 3)] '@'(square '@'(square 3))) {RedexInfo P1}}
   {TestResult next_square_root true {NextReduction P1}.root == P1.graph}
   {TestResult next_twice redex(twice [5] '@'(twice 5)) {RedexInfo P2}}
   {TestResult next_sum_n_arity 4 {Length {NextReduction P3}.args}}
   {TestResult next_plus redex('+' [2 3] '@'('@'('+' 2) 3)) {RedexInfo {Build Funs {MakeOp '+' 2 3}}}}
   {TestResult next_plus_left redex(square [3] Sq3) {RedexInfo {Build Funs {MakeOp '+' Sq3 2}}}}
   {TestResult next_plus_right redex(square [3] Sq3) {RedexInfo {Build Funs {MakeOp '+' x Sq3}}}}
   {TestResult next_free_vars none {RedexInfo {Build Funs {MakeOp '+' x x}}}}
   {TestResult next_number none {RedexInfo {Build Funs 81}}}
   {TestResult next_partial none {RedexInfo {Build Funs square}}}
   {TestResult next_overapplied redex(f [1 2] '@'('@'(f 1) 2)) {RedexInfo P4}}
   {TestResult next_caf redex(five nil five) {RedexInfo P5}}
   {TestResult next_indirection redex(square [3] Sq3) {RedexInfo Ind}}
end

proc {TestTask3}
   P1 = {GraphGeneration "fun twice x = x + x\ntwice 5"}
   P2 = {Build P1.funs {MakeOp '+' 2 3}}
   P3 = {GraphGeneration "fun square x = x * x\nsquare square 3"}
   P4 = {GraphGeneration "fun fourtimes x = var y = x*x in y+y\nfourtimes 2"}
   P5 = {GraphGeneration "fun sqr x = (x+1) * (x-1)\nsqr 4"}
   P6 = {GraphGeneration "fun arithmetic x y = ((x + y) / (x - y)) * 2\narithmetic 2 11"}
   P7 = {Build P1.funs {MakeOp '+' x x}}
in
   {TestResult reduce_twice '@'('@'('+' 5) 5) {GraphToRecord {Reduce P1}}}
   {TestResult reduce_twice_root_ind true {Label {Reduce P1}.heap.(P1.graph)} == ind}
   {TestResult reduce_plus 5 {GraphToRecord {Reduce P2}}}
   {TestResult reduce_square 81 {GraphToRecord {ReduceN P3 4}}}
   {TestResult reduce_fourtimes_shared true {SharedBody {Reduce P4}}}
   {TestResult reduce_fourtimes 8 {GraphToRecord {ReduceN P4 3}}}
   {TestResult reduce_sqr 15 {GraphToRecord {ReduceN P5 4}}}
   {TestFloat reduce_arithmetic ~2.8888889 {GraphToRecord {ReduceN P6 5}}}
   {TestResult reduce_none '@'('@'('+' x) x) {GraphToRecord {Reduce P7}}}
   {TestResult reduce_none_same true {Reduce P7} == P7}
end

proc {TestTask4}
   {TestResult eval_square 81 {Evaluate {GenerateGraph "fun square x = x * x\nsquare square 3"}}}
   {TestResult eval_fourtimes 8 {Evaluate {GenerateGraph "fun fourtimes x = var y = x*x in y+y\nfourtimes 2"}}}
   {TestResult eval_twice 10 {Evaluate {GenerateGraph "fun twice x = x + x\ntwice 5"}}}
   {TestResult eval_sqr 15 {Evaluate {GenerateGraph "fun sqr x = (x+1) * (x-1)\nsqr 4"}}}
   {TestResult eval_sum_n 20 {Evaluate {GenerateGraph "fun sum_n x y z n = (x + y + z) * n\nsum_n 1 sum_n 1 1 1 2 3 2"}}}
   {TestFloat eval_arithmetic 2.6046512 {Evaluate {GenerateGraph "fun arithmetic x y = ((x + y) / (x - y)) * 2\narithmetic arithmetic 5 6 arithmetic 2 11"}}}
   {TestResult eval_var_use 241 {Evaluate {GenerateGraph "fun var_use x = var y = x+x in var z = y * 2 in z - 3\nvar_use var_use 16"}}}
   {TestResult eval_caf 5 {Evaluate {GenerateGraph "fun five = 5\nfive"}}}
   {TestResult eval_free_vars '@'('@'('+' x) x) {Evaluate {GenerateGraph "x + x"}}}
   {TestResult eval_free_call '@'('@'('+' y) y) {Evaluate {GenerateGraph "fun twice x = x + x\ntwice y"}}}
end

proc {TestParser}
   P1 = {GenerateGraph "fun twice x = x + x\nfun f x = twice x + 1\nf 3"}
in
   {TestResult parse_body_call '@'('@'('+' '@'(twice x)) 1) P1.funs.f.body}
   {TestResult eval_body_call 7 {Evaluate P1}}
   {TestResult eval_body_call_paren 12 {Evaluate {GenerateGraph "fun twice x = x + x\nfun g x = twice (x * 2)\ng 3"}}}
   {TestResult eval_call_paren_op 10 {Evaluate {GenerateGraph "fun twice x = x + x\ntwice (2 + 3)"}}}
   {TestResult eval_call_op 7 {Evaluate {GenerateGraph "fun twice x = x + x\ntwice 3 + 1"}}}
   {TestResult eval_only_arith 5 {Evaluate {GenerateGraph "2 + 3"}}}
   {TestResult eval_multi_def 36 {Evaluate {GenerateGraph "fun twice x = x + x\nfun square x = x * x\nsquare twice 3"}}}
   {TestResult eval_crlf 10 {Evaluate {GenerateGraph "fun twice x = x + x\r\ntwice 5"}}}
   {TestResult eval_tabs 10 {Evaluate {GenerateGraph "fun\ttwice x = x + x\ntwice\t5"}}}
   {TestResult eval_comment_line 81 {Evaluate {GenerateGraph "fun square x = x * x\nsquare square 3\n% % Res : 81"}}}
   {TestResult eval_comment_inline 8 {Evaluate {GenerateGraph "fun fourtimes x = var y = x*x in y+y % shared y\nfourtimes 2"}}}
   {TestResult eval_var_no_equal 241 {Evaluate {GenerateGraph "fun var_use x = var y x+x in var z = y * 2 in z - 3\nvar_use var_use 16"}}}
end

proc {TestImprovements}
   {TestResult div_real 2.5 {Evaluate {GenerateGraph "fun half x = x / 2\nhalf 5"}}}
   {TestResult div_exact_int 5 {Evaluate {GenerateGraph "fun half x = x / 2\nhalf 10"}}}
   {TestResult div_mixed 3.5 {Evaluate {GenerateGraph "7 / 2"}}}
   {TestResult float_literal 5.0 {Evaluate {GenerateGraph "fun twice x = x + x\ntwice 2.5"}}}
   {TestResult float_and_int 4.5 {Evaluate {GenerateGraph "2.5 + 2"}}}
   {TestResult multi_calls [10 14 25] {Evaluate {GenerateGraph "fun twice x = x + x\nfun square x = x * x\ntwice 5\ntwice 7\nsquare 5"}}}
   {TestResult multi_calls_free [6 '@'('@'('+' z) z)] {Evaluate {GenerateGraph "fun twice x = x + x\ntwice 3\ntwice z"}}}
   {TestResult only_defs nil {Evaluate {GenerateGraph "fun twice x = x + x"}}}
   {TestResult neg_arg 9 {Evaluate {GenerateGraph "fun square x = x * x\nsquare -3"}}}
   {TestResult neg_literal ~7 {Evaluate {GenerateGraph "-7"}}}
   {TestResult neg_second_arg 7 {Evaluate {GenerateGraph "fun sub x y = x - y\nsub 5 -2"}}}
   {TestResult neg_after_op 8 {Evaluate {GenerateGraph "5 - -3"}}}
   {TestResult neg_binary_minus 5 {Evaluate {GenerateGraph "fun twice x = x + x\ntwice 3 - 1"}}}
   {TestResult neg_param ~4 {Evaluate {GenerateGraph "fun neg x = -x\nneg 4"}}}
   {TestResult neg_paren ~5 {Evaluate {GenerateGraph "-(2 + 3)"}}}
   {TestResult neg_float ~1.25 {Evaluate {GenerateGraph "fun half x = x / 2\nhalf -2.5"}}}
   {TestResult neg_graph '@'('@'('-' 0) x) {GenerateGraph "fun neg x = -x\nneg 1"}.funs.neg.body}
end

proc {TestFunctional}
   P1 = {GenerateGraph "fun square x = x * x\nsquare square 3"}
   P2 = {GenerateGraph "fun twice x = x + x\ntwice 5"}
   Loop = {GenerateGraph "fun loop x = loop x\nloop 1"}
   P3 = {GenerateGraph "fun first x y = x\nfirst 1 (2 / 0)"}
   Before = {GraphToRecord P2}
   After = {GraphToRecord {Reduce P2}}
in
   {TestResult steps_square ['@'(square '@'(square 3))
                             '@'('@'('*' '@'(square 3)) '@'(square 3))
                             '@'('@'('*' '@'('@'('*' 3) 3)) '@'('@'('*' 3) 3))
                             '@'('@'('*' 9) 9)
                             81] {Steps P1}}
   {TestResult immutable_before '@'(twice 5) Before}
   {TestResult immutable_after '@'('@'('+' 5) 5) After}
   {TestResult immutable_still '@'(twice 5) {GraphToRecord P2}}
   {TestResult lazy_infinite_trace ['@'(loop 1) '@'(loop 1) '@'(loop 1)] {Map {List.take {Trace Loop} 3} GraphToRecord}}
   {TestResult lazy_outermost 1 {Evaluate P3}}
   {TestResult continuation_left_none redex(square [3] '@'(square 3)) {RedexInfo {Build P1.funs {MakeOp '*' {MakeOp '+' a b} '@'(square 3)}}}}
end

{TestTask1}
{TestTask2}
{TestTask3}
{TestTask4}
{TestParser}
{TestImprovements}
{TestFunctional}
