declare Leaf App MakeOp Tokenize Lookup
ParseFactor ParseArgs ParseTerm ParseTermRest ParseExpr ParseExprRest ParseBody ParseDefinition
CountParams GraphGeneration GenerateGraph GraphToRecord
IsPrimitive IsNumberNode RightChild Unwind Redex PrimitiveRedex FirstRedex FindRedex NextReduction Value Apply Instantiate Reduce Evaluate

fun {Leaf V}
   {NewCell leaf(V)}
end

fun {App L R}
   {NewCell app(L R)}
end

fun {MakeOp Op L R}
   {App {App {Leaf {String.toAtom Op}} L} R}
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

fun {Lookup Name Env}
   case Env of N#Node|Rest then
      if N == Name then Node else {Lookup Name Rest} end
   else
      {Leaf Name}
   end
end

fun {ParseFactor Tokens Env Arity}
   case Tokens of "("|Rest then
      Node Rest2 in
      Node#(")"|Rest2) = {ParseExpr Rest Env Arity}
      Node#Rest2
   [] T|Rest then
      if {String.isInt T} then
         {Leaf {String.toInt T}}#Rest
      else
         Name = {String.toAtom T} in
         if {Some Env fun {$ P} P.1 == Name end} then
            {Lookup Name Env}#Rest
         elseif {HasFeature Arity Name} then
            {ParseArgs {Leaf Name} Arity.Name Rest Env Arity}
         else
            {Leaf Name}#Rest
         end
      end
   end
end

fun {ParseArgs Node N Tokens Env Arity}
   if N == 0 then
      Node#Tokens
   else
      Arg Rest in
      Arg#Rest = {ParseFactor Tokens Env Arity}
      {ParseArgs {App Node Arg} N-1 Rest Env Arity}
   end
end

fun {ParseTerm Tokens Env Arity}
   Left Rest in
   Left#Rest = {ParseFactor Tokens Env Arity}
   {ParseTermRest Left Rest Env Arity}
end

fun {ParseTermRest Left Tokens Env Arity}
   case Tokens of Op|Rest then
      if Op == "*" orelse Op == "/" then
         Right Rest2 in
         Right#Rest2 = {ParseFactor Rest Env Arity}
         {ParseTermRest {MakeOp Op Left Right} Rest2 Env Arity}
      else
         Left#Tokens
      end
   else
      Left#Tokens
   end
end

fun {ParseExpr Tokens Env Arity}
   Left Rest in
   Left#Rest = {ParseTerm Tokens Env Arity}
   {ParseExprRest Left Rest Env Arity}
end

fun {ParseExprRest Left Tokens Env Arity}
   case Tokens of Op|Rest then
      if Op == "+" orelse Op == "-" then
         Right Rest2 in
         Right#Rest2 = {ParseTerm Rest Env Arity}
         {ParseExprRest {MakeOp Op Left Right} Rest2 Env Arity}
      else
         Left#Tokens
      end
   else
      Left#Tokens
   end
end

fun {ParseBody Tokens Env Arity}
   case Tokens of "var"|NameS|Rest then
      ExprTokens Node Rest2 NewEnv in
      ExprTokens = case Rest of "="|R then R else Rest end
      Node#Rest2 = {ParseExpr ExprTokens Env Arity}
      NewEnv = ({String.toAtom NameS}#Node)|Env
      case Rest2 of "in"|Rest3 then
         {ParseBody Rest3 NewEnv Arity}
      else
         {ParseBody Rest2 NewEnv Arity}
      end
   else
      {ParseExpr Tokens Env Arity}.1
   end
end

fun {ParseDefinition Tokens Arity}
   NameS Rest ParamsS BodyTokens in
   "fun"|NameS|Rest = Tokens
   {List.takeDropWhile Rest fun {$ T} T \= "=" end ParamsS _|BodyTokens}
   {String.toAtom NameS}#def(params: {Map ParamsS String.toAtom}
                             body: {ParseBody BodyTokens nil Arity})
end

fun {CountParams Tokens}
   {Length {List.takeWhile Tokens.2.2 fun {$ T} T \= "=" end}}
end

fun {GraphGeneration Program}
   Lines = {Filter {Map {String.tokens Program &\n} Tokenize} fun {$ L} L \= nil end}
   Defs = {Filter Lines fun {$ L} L.1 == "fun" end}
   Calls = {Filter Lines fun {$ L} L.1 \= "fun" end}
   Arity = {List.toRecord arity {Map Defs fun {$ L} {String.toAtom L.2.1}#{CountParams L} end}}
   Funs = {List.toRecord funs {Map Defs fun {$ L} {ParseDefinition L Arity} end}}
in
   program(funs: Funs graph: {ParseExpr {List.last Calls} nil Arity}.1)
end

GenerateGraph = GraphGeneration

fun {GraphToRecord Node}
   case @Node of leaf(V) then V
   [] app(L R) then '@'({GraphToRecord L} {GraphToRecord R})
   [] ind(N) then {GraphToRecord N}
   end
end

fun {IsPrimitive V}
   {Member V ['+' '-' '*' '/']}
end

fun {IsNumberNode Node}
   case @Node of leaf(V) then {IsNumber V}
   [] ind(N) then {IsNumberNode N}
   else false
   end
end

fun {RightChild Node}
   case @Node of app(_ R) then R end
end

fun {Unwind Node Stack}
   case @Node of app(L _) then
      {Unwind L Node|Stack}
   [] ind(N) then
      {Unwind N Stack}
   else
      Node|Stack
   end
end

fun {Redex Name Stack Arity}
   if {Length Stack} =< Arity then
      none
   else
      redex(name: Name
            args: {Map {List.take Stack.2 Arity} RightChild}
            root: {Nth Stack Arity+1})
   end
end

fun {PrimitiveRedex Name Stack Funs}
   R = {Redex Name Stack 2}
in
   if R == none then none
   elseif {All R.args IsNumberNode} then R
   else {FirstRedex R.args Funs}
   end
end

fun {FirstRedex Nodes Funs}
   case Nodes of Node|Rest then
      R = {FindRedex Node Funs} in
      if R == none then {FirstRedex Rest Funs} else R end
   else
      none
   end
end

fun {FindRedex Node Funs}
   Stack = {Unwind Node nil}
   Head = Stack.1
   Name = case @Head of leaf(V) then V end
in
   if {IsPrimitive Name} then
      {PrimitiveRedex Name Stack Funs}
   elseif {HasFeature Funs Name} then
      {Redex Name Stack {Length Funs.Name.params}}
   else
      none
   end
end

fun {NextReduction Program}
   {FindRedex Program.graph Program.funs}
end

fun {Value Node}
   case @Node of leaf(V) then V
   [] ind(N) then {Value N}
   end
end

fun {Apply Op A B}
   case Op of '+' then A + B
   [] '-' then A - B
   [] '*' then A * B
   [] '/' then A div B
   end
end

fun {Instantiate Node Env Memo}
   case @Node of leaf(V) then
      {Lookup V Env}
   [] app(L R) then
      case {Filter @Memo fun {$ P} P.1 == Node end} of (_#Copy)|_ then
         Copy
      else
         New = {App {Instantiate L Env Memo} {Instantiate R Env Memo}} in
         Memo := (Node#New)|@Memo
         New
      end
   end
end

fun {Reduce Program}
   R = {NextReduction Program}
in
   if R == none then
      skip
   elseif {IsPrimitive R.name} then
      {Assign R.root leaf({Apply R.name {Value R.args.1} {Value R.args.2.1}})}
   else
      Def = Program.funs.(R.name) in
      {Assign R.root ind({Instantiate Def.body
                                      {List.zip Def.params R.args fun {$ P A} P#A end}
                                      {NewCell nil}})}
   end
   Program
end

fun {Evaluate Program}
   if {NextReduction Program} == none then
      {GraphToRecord Program.graph}
   else
      {Evaluate {Reduce Program}}
   end
end
