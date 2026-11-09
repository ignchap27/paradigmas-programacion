declare MakeOp Trim CleanLine Tokenize IsIdentifier Lookup
ParseFactor ParseArgs ParseTerm ParseTermRest ParseExpr ParseExprRest ParseAll ParseBody
Header ParseDefinition Checked Alloc Instantiate BuildProgram GraphGeneration GenerateGraph
NodeToRecord GraphToRecord
IsPrimitive Value IsNumberNode Unwind ArgCount Redex FindRedex NextReduction
ToFloat IsExact Calculate Apply Reduce Trace Steps Result Evaluate

fun {MakeOp Op L R}
   '@'('@'(Op L) R)
end

fun {Trim S}
   {Reverse {List.dropWhile {Reverse {List.dropWhile S Char.isSpace}} Char.isSpace}}
end

fun {CleanLine Line}
   {Trim {List.takeWhile Line fun {$ C} C \= &% end}}
end

fun {Tokenize Line}
   Spaced = {FoldR Line
             fun {$ C Acc}
                if {Char.isSpace C} then & |Acc
                elseif {Member C "+-*/()="} then & |C|& |Acc
                else C|Acc
                end
             end
             nil}
in
   {Filter {String.tokens Spaced & } fun {$ T} T \= nil end}
end

fun {IsIdentifier T}
   {Char.isAlpha T.1} andthen {Not {Member T ["fun" "var" "in"]}}
end

fun {Lookup Name Env}
   case Env of N#Addr|Rest then
      if N == Name then Addr else {Lookup Name Rest} end
   else
      none
   end
end

fun {ParseFactor Tokens Bound Arities}
   case Tokens of "("|Rest then
      E Rest2 in
      E#Rest2 = {ParseExpr Rest Bound Arities}
      case Rest2 of ")"|Rest3 then E#Rest3 else raise syntax end end
   [] "-"|Rest then
      E Rest2 in
      E#Rest2 = {ParseFactor Rest Bound Arities}
      if {IsNumber E} then (~E)#Rest2 else {MakeOp '-' 0 E}#Rest2 end
   [] T|Rest then
      if {String.isInt T} then
         {String.toInt T}#Rest
      elseif {String.isFloat T} then
         {String.toFloat T}#Rest
      elseif {Not {IsIdentifier T}} then
         raise syntax end
      else
         Name = {String.toAtom T} in
         if {Member Name Bound} then
            Name#Rest
         elseif {HasFeature Arities Name} then
            {ParseArgs Name Arities.Name Rest Bound Arities}
         else
            Name#Rest
         end
      end
   else
      raise syntax end
   end
end

fun {ParseArgs E N Tokens Bound Arities}
   if N == 0 then
      E#Tokens
   else
      Arg Rest in
      Arg#Rest = {ParseFactor Tokens Bound Arities}
      {ParseArgs '@'(E Arg) N-1 Rest Bound Arities}
   end
end

fun {ParseTerm Tokens Bound Arities}
   Left Rest in
   Left#Rest = {ParseFactor Tokens Bound Arities}
   {ParseTermRest Left Rest Bound Arities}
end

fun {ParseTermRest Left Tokens Bound Arities}
   case Tokens of Op|Rest then
      if Op == "*" orelse Op == "/" then
         Right Rest2 in
         Right#Rest2 = {ParseFactor Rest Bound Arities}
         {ParseTermRest {MakeOp {String.toAtom Op} Left Right} Rest2 Bound Arities}
      else
         Left#Tokens
      end
   else
      Left#Tokens
   end
end

fun {ParseExpr Tokens Bound Arities}
   Left Rest in
   Left#Rest = {ParseTerm Tokens Bound Arities}
   {ParseExprRest Left Rest Bound Arities}
end

fun {ParseExprRest Left Tokens Bound Arities}
   case Tokens of Op|Rest then
      if Op == "+" orelse Op == "-" then
         Right Rest2 in
         Right#Rest2 = {ParseTerm Rest Bound Arities}
         {ParseExprRest {MakeOp {String.toAtom Op} Left Right} Rest2 Bound Arities}
      else
         Left#Tokens
      end
   else
      Left#Tokens
   end
end

fun {ParseAll Tokens Bound Arities}
   E Rest in
   E#Rest = {ParseExpr Tokens Bound Arities}
   if Rest == nil then E else raise syntax end end
end

fun {ParseBody Tokens Bound Arities}
   case Tokens of "var"|NameS|Rest andthen {IsIdentifier NameS} then
      Name = {String.toAtom NameS}
      ExprTokens = case Rest of "="|R then R else Rest end
      E Rest2 BodyTokens in
      E#Rest2 = {ParseExpr ExprTokens Bound Arities}
      BodyTokens = case Rest2 of "in"|R then R else Rest2 end
      let(Name E {ParseBody BodyTokens Name|Bound Arities})
   else
      {ParseAll Tokens Bound Arities}
   end
end

fun {Header Tokens}
   case Tokens of "fun"|NameS|Rest andthen {Member "=" Rest} then
      ParamsS BodyTokens in
      {List.takeDropWhile Rest fun {$ T} T \= "=" end ParamsS _|BodyTokens}
      if {All NameS|ParamsS IsIdentifier} then
         header(name: {String.toAtom NameS} params: {Map ParamsS String.toAtom} body: BodyTokens)
      else
         raise syntax end
      end
   else
      raise syntax end
   end
end

fun {ParseDefinition Tokens Arities}
   H = {Header Tokens}
in
   H.name#def(params: H.params body: {ParseBody H.body H.params Arities})
end

fun {Checked Line F}
   try {F Line.2} catch syntax then raise syntaxError(Line.1) end end
end

fun {Alloc Node Heap}
   Addr = {Width Heap} + 1
in
   Addr#{AdjoinAt Heap Addr Node}
end

fun {Instantiate E Env Heap}
   case E of '@'(F A) then
      FAddr AAddr H1 H2 in
      FAddr#H1 = {Instantiate F Env Heap}
      AAddr#H2 = {Instantiate A Env H1}
      {Alloc app(FAddr AAddr) H2}
   [] let(Name Def Body) then
      DefAddr H1 in
      DefAddr#H1 = {Instantiate Def Env Heap}
      {Instantiate Body (Name#DefAddr)|Env H1}
   else
      Addr = {Lookup E Env} in
      if Addr == none then {Alloc leaf(E) Heap} else Addr#Heap end
   end
end

fun {BuildProgram Program}
   Texts = {Filter {Map {String.tokens Program &\n} CleanLine} fun {$ L} L \= nil end}
   Lines = {Map Texts fun {$ L} L#{Tokenize L} end}
   Defs = {Filter Lines fun {$ L} L.2.1 == "fun" end}
   Calls = {Filter Lines fun {$ L} L.2.1 \= "fun" end}
   Headers = {Map Defs fun {$ L} {Checked L Header} end}
   Arities = {List.toRecord arities {Map Headers fun {$ H} H.name#{Length H.params} end}}
   Funs = {List.toRecord funs {Map Defs fun {$ L} {Checked L fun {$ Ts} {ParseDefinition Ts Arities} end} end}}
   Exprs = {Map Calls fun {$ L} {Checked L fun {$ Ts} {ParseAll Ts nil Arities} end} end}
   Built = {FoldR Exprs
            fun {$ E Acc}
               Addr Heap in
               Addr#Heap = {Instantiate E nil Acc.1}
               Heap#(Addr|Acc.2)
            end
            heap#nil}
in
   program(funs: Funs heap: Built.1 calls: Built.2 graph: {CondSelect Built.2 1 none})
end

fun {GraphGeneration Program}
   try
      {BuildProgram Program}
   catch syntaxError(Text) then
      error(syntax: {String.toAtom Text})
   end
end

GenerateGraph = GraphGeneration

fun {NodeToRecord Addr Heap}
   case Heap.Addr of leaf(V) then V
   [] app(L R) then '@'({NodeToRecord L Heap} {NodeToRecord R Heap})
   [] ind(A) then {NodeToRecord A Heap}
   end
end

fun {GraphToRecord Program}
   {NodeToRecord Program.graph Program.heap}
end

fun {IsPrimitive V}
   {Member V ['+' '-' '*' '/']}
end

fun {Value Addr Heap}
   case Heap.Addr of leaf(V) then V
   [] ind(A) then {Value A Heap}
   end
end

fun {IsNumberNode Addr Heap}
   case Heap.Addr of leaf(V) then {IsNumber V}
   [] ind(A) then {IsNumberNode A Heap}
   else false
   end
end

fun {Unwind Addr Heap Stack}
   case Heap.Addr of app(L _) then {Unwind L Heap Addr|Stack}
   [] ind(A) then {Unwind A Heap Stack}
   else Addr|Stack
   end
end

fun {ArgCount Name Funs}
   if {IsPrimitive Name} then 2
   elseif {IsAtom Name} andthen {HasFeature Funs Name} then {Length Funs.Name.params}
   else none
   end
end

fun {Redex Name Stack N Heap}
   if N == none orelse {Length Stack} =< N then
      none
   else
      redex(name: Name
            args: {Map {List.take Stack.2 N} fun {$ A} Heap.A.2 end}
            root: {Nth Stack N+1})
   end
end

fun {FindRedex Addr Program Otherwise}
   Heap = Program.heap
   Stack = {Unwind Addr Heap nil}
   Name = {Value Stack.1 Heap}
   R = {Redex Name Stack {ArgCount Name Program.funs} Heap}
in
   if R == none then
      {Otherwise}
   elseif {IsPrimitive Name} andthen {Not {All R.args fun {$ A} {IsNumberNode A Heap} end}} then
      {FindRedex R.args.1 Program fun {$} {FindRedex R.args.2.1 Program Otherwise} end}
   else
      R
   end
end

fun {NextReduction Program}
   {FindRedex Program.graph Program fun {$} none end}
end

fun {ToFloat X}
   if {IsInt X} then {Int.toFloat X} else X end
end

fun {IsExact Op A B}
   {IsInt A} andthen {IsInt B} andthen (Op \= '/' orelse (B \= 0 andthen A mod B == 0))
end

fun {Calculate Op A B}
   case Op of '+' then A + B
   [] '-' then A - B
   [] '*' then A * B
   [] '/' then if {IsInt A} then A div B else A / B end
   end
end

fun {Apply Op A B}
   if {IsExact Op A B} then
      {Calculate Op A B}
   else
      {Calculate Op {ToFloat A} {ToFloat B}}
   end
end

fun {Reduce Program}
   R = {NextReduction Program}
   Heap = Program.heap
in
   if R == none then
      Program
   elseif {IsPrimitive R.name} then
      Res = {Apply R.name {Value R.args.1 Heap} {Value R.args.2.1 Heap}} in
      {AdjoinAt Program heap {AdjoinAt Heap R.root leaf(Res)}}
   else
      Def = Program.funs.(R.name)
      Env = {List.zip Def.params R.args fun {$ P A} P#A end}
      Body NewHeap in
      Body#NewHeap = {Instantiate Def.body Env Heap}
      {AdjoinAt Program heap {AdjoinAt NewHeap R.root ind(Body)}}
   end
end

fun lazy {Trace Program}
   if {NextReduction Program} == none then
      [Program]
   else
      Program|{Trace {Reduce Program}}
   end
end

fun {Steps Program}
   {Map {Trace Program} GraphToRecord}
end

fun {Result Program}
   {GraphToRecord {List.last {Trace Program}}}
end

fun {Evaluate Program}
   if {Label Program} == error then
      Program
   else
      Results = {Map Program.calls fun {$ Addr} {Result {AdjoinAt Program graph Addr}} end} in
      case Results of [R] then R else Results end
   end
end
