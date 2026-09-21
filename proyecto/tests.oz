\insert 'composition.oz'

declare
E    = {NewEmployer "Uniandes" "Cra 1 # 18A-12"}
P    = {NewPerson "Ana" E}
CE   = {ExplicitComposition [E P]}
CI   = {ImplicitComposition [E P]}
A    = {NewAccount 100}

proc {Titulo T} {System.showInfo ""} {System.showInfo "== "#T#" =="} end

fun {NewLoud}
   proc {Announce Msg}
      {System.showInfo "LOUD: "#Msg}
      {NextFunction}
   end
in
   object(attributes: attributes announce: Announce)
end

fun {NewQuiet}
   proc {Announce Msg}
      {System.showInfo "quiet: "#Msg}
   end
in
   object(attributes: attributes announce: Announce)
end

CP = {ExplicitCompositionPoly [E P]}
CN = {ExplicitCompositionPoly [{NewLoud} {NewQuiet}]}

{Titulo "Tarea 1: objetos basicos"}
{E.display}
{P.display}
{System.showInfo "PersonEmployer -> "#{P.personEmployer}}

{Titulo "Tarea 2: composicion explicita"}
{CE.display}
{System.showInfo "personName -> "#{CE.personName}}
{System.show {E.name} == {CE.name}}

{Titulo "Tarea 3: composicion implicita"}
{CI.display}
{System.showInfo "personName -> "#{CI.personName}}
{System.show {E.name} == {CI.name}}

{Titulo "Tarea 4 y 5: Dispatch sobre la composicion polimorfica"}
{Dispatch CP display nil 1}
{Dispatch CP display nil 2}
{Dispatch CP display nil 3}

{Titulo "Tarea 5: Dispatch con parametros"}
{Dispatch {ExplicitCompositionPoly [A]} deposit 10 1}
{System.showInfo "Saldo -> "#{A.balance}}

{Titulo "Tarea 6: NextFunction"}
{Dispatch CN announce "hola" 1}



declare
Passed = {NewCell 0}
Failed = {NewCell 0}

proc {Check Name Expected Actual}
   if Expected == Actual then
      Passed := @Passed + 1
      {System.showInfo "OK    "#Name}
   else
      Failed := @Failed + 1
      {System.showInfo "FALLA "#Name}
      {System.show falla(esperado: Expected obtenido: Actual)}
   end
end

fun {ErrorKind P}
   try
      {P}
      none
   catch metaError(Kind ...) then Kind
   [] _ then otherError
   end
end

fun {NewTracer Name Log CallsNext}
   CellName = {NewCell Name}
   fun {Attributes} attributes(name: CellName) end
   proc {Step}
      Log := {Append @Log [@CellName]}
      if CallsNext then {NextFunction} end
   end
in
   object(attributes: {Attributes} step: Step)
end

fun {NewCounter Init}
   CellCount = {NewCell Init}
   fun {Attributes} attributes(count: CellCount) end
   fun {Count} @CellCount end
   proc {Add N}
      CellCount := @CellCount + N
      {NextFunction}
   end
in
   object(attributes: {Attributes} count: Count add: Add)
end

fun {NewCalculator}
   fun {Attributes} attributes end
   fun {Sum X Y} X + Y end
   proc {Swap X Y ?R1 ?R2} R1 = Y R2 = X end
in
   object(attributes: {Attributes} sum: Sum swap: Swap)
end

{Titulo "CASOS DE PRUEBA"}

local
   E1 = {NewEmployer "Uniandes" "Cra 1 # 18A-12"}
   E2 = {NewEmployer "Javeriana" "Cra 7 # 40-62"}
   P1 = {NewPerson "Ana" E1}
   P2 = {NewPerson "Luis" "Empresa suelta"}
   A1 = {NewAccount 100}
in
   {System.showInfo "-- Tarea 1"}
   {Check "t1 Employer.name" "Uniandes" {E1.name}}
   {Check "t1 Employer.address" "Cra 1 # 18A-12" {E1.address}}
   {Check "t1 Person.personName" "Ana" {P1.personName}}
   {Check "t1 Person.personEmployer devuelve el nombre del empleador" "Uniandes" {P1.personEmployer}}
   {Check "t1 Person.personEmployer con un string como empleador" "Empresa suelta" {P2.personEmployer}}
   {Check "t1 campos de Employer" [address attributes display name] {Arity E1}}
   {Check "t1 campos de Person" [attributes display personEmployer personName] {Arity P1}}
   {Check "t1 etiqueta del registro de atributos" attributes {Label E1.attributes}}
   {Check "t1 atributos de Employer" [address name] {Arity E1.attributes}}
   {Check "t1 atributos de Person" [employer name] {Arity P1.attributes}}
   {Check "t1 los atributos son celdas" true {IsCell E1.attributes.name}}
   {Check "t1 la celda tiene el valor inicial" "Uniandes" @(E1.attributes.name)}
   {Check "t1 el atributo employer guarda el objeto" E1 @(P1.attributes.employer)}
   {Assign E1.attributes.name "Uniandes S.A."}
   {Check "t1 cambiar la celda cambia el metodo" "Uniandes S.A." {E1.name}}
   {Check "t1 Person ve el cambio de su empleador" "Uniandes S.A." {P1.personEmployer}}
   {Assign E1.attributes.name "Uniandes"}
   {Check "t1 dos instancias no comparten estado" "Javeriana" {E2.name}}
   {Check "t1 celdas distintas por instancia" false E1.attributes.name == E2.attributes.name}
   {A1.deposit 50}
   {Check "t1 metodo con parametro (deposit)" 150 {A1.balance}}
end

local
   E1 = {NewEmployer "Uniandes" "Cra 1 # 18A-12"}
   P1 = {NewPerson "Ana" E1}
   A1 = {NewAccount 100}
   C  = {ExplicitComposition [E1 P1]}
   CR = {ExplicitComposition [P1 E1]}
in
   {System.showInfo "-- Tarea 2"}
   {Check "t2 Snippet 1 del enunciado" true {E1.name} == {C.name}}
   {Check "t2 tiene los metodos de ambos" [address attributes display name personEmployer personName] {Arity C}}
   {Check "t2 tiene los atributos de ambos" [address employer name] {Arity C.attributes}}
   {Check "t2 metodo de Employer" "Cra 1 # 18A-12" {C.address}}
   {Check "t2 metodo de Person" "Ana" {C.personName}}
   {Check "t2 choque de metodo: gana el primero" E1.display C.display}
   {Check "t2 choque de atributo: gana el primero" E1.attributes.name C.attributes.name}
   {Check "t2 atributo sin choque" P1.attributes.employer C.attributes.employer}
   {Check "t2 orden invertido: gana Person en display" P1.display CR.display}
   {Check "t2 orden invertido: gana Person en atributo name" P1.attributes.name CR.attributes.name}
   {Check "t2 los metodos se copian (misma clausura)" E1.name C.name}
   {Assign C.attributes.name "Uniandes S.A."}
   {Check "t2 el estado se comparte con el original" "Uniandes S.A." {E1.name}}
   {Assign C.attributes.name "Uniandes"}
   {Check "t2 idempotencia [E E]" {Arity E1} {Arity {ExplicitComposition [E1 E1]}}}
   {Check "t2 idempotencia [E P E] = [E P]" {Arity C} {Arity {ExplicitComposition [E1 P1 E1]}}}
   {Check "t2 idempotencia mantiene el metodo" E1.name {ExplicitComposition [E1 E1]}.name}
   {Check "t2 un solo objeto" {Arity E1} {Arity {ExplicitComposition [E1]}}}
   {Check "t2 lista vacia da objeto vacio" object(attributes: attributes) {ExplicitComposition nil}}
   {Check "t2 tres objetos" "Ana" {{ExplicitComposition [E1 P1 A1]}.personName}}
   {Check "t2 composicion de composiciones" {Arity {Compose [E1 P1 A1]}} {Arity {Compose [C A1]}}}
   {{ExplicitComposition [A1 P1]}.deposit 25}
   {Check "t2 deposit a traves de la composicion" 125 {A1.balance}}
   {Check "t2 Compose es ExplicitComposition" ExplicitComposition Compose}
end

local
   E1 = {NewEmployer "Uniandes" "Cra 1 # 18A-12"}
   P1 = {NewPerson "Ana" E1}
   A1 = {NewAccount 100}
   C  = {ImplicitComposition [E1 P1]}
   Log = {NewCell nil}
   CT = {ImplicitComposition [{NewTracer first Log false} {NewTracer second Log false}]}
   CC = {ImplicitComposition [{NewCalculator} A1]}
in
   {System.showInfo "-- Tarea 3"}
   {Check "t3 Snippet 1 del enunciado" true {E1.name} == {C.name}}
   {Check "t3 metodo de Person" "Ana" {C.personName}}
   {Check "t3 personEmployer" "Uniandes" {C.personEmployer}}
   {Check "t3 tiene los metodos de ambos" [address attributes constituents display name personEmployer personName] {Arity C}}
   {Check "t3 guarda a los constituyentes" [E1 P1] C.constituents}
   {Check "t3 delega: no copia el metodo" false E1.name == C.name}
   {Check "t3 choque de atributo: gana el primero" E1.attributes.name C.attributes.name}
   {CT.step}
   {Check "t3 choque de metodo: se ejecuta solo el primero" [first] @Log}
   {Check "t3 idempotencia" 1 {Length {ImplicitComposition [E1 E1]}.constituents}}
   {CC.deposit 40}
   {Check "t3 reenvia parametros (deposit)" 140 {A1.balance}}
   {Check "t3 reenvia funciones con 2 parametros" 5 {CC.sum 2 3}}
   {Check "t3 reenvia procedimientos con 4 parametros" b#a local R1 R2 in {CC.swap a b R1 R2} R1#R2 end}
   {Check "t3 composicion de composiciones" "Ana" {{ImplicitComposition [C A1]}.personName}}
   {Check "t3 mezcla implicita dentro de explicita" "Ana" {{ExplicitComposition [C A1]}.personName}}
   {Check "t3 ResolveMethod falla si nadie tiene el metodo" methodNotFound {ErrorKind proc {$} _ = {ResolveMethod [E1] foo} end}}
end

local
   E1 = {NewEmployer "Uniandes" "Cra 1 # 18A-12"}
   P1 = {NewPerson "Ana" E1}
   Log = {NewCell nil}
   T1 = {NewTracer a Log false}
   T2 = {NewTracer b Log false}
   T3 = {NewTracer c Log false}
   C  = {ExplicitCompositionPoly [E1 P1]}
   CT = {ExplicitCompositionPoly [T1 T2 T3]}
in
   {System.showInfo "-- Tarea 4"}
   {Check "t4 metodo con choque tiene 2 implementaciones" 2 {Length C.display}}
   {Check "t4 las implementaciones van en orden de aparicion" [E1.display P1.display] C.display}
   {Check "t4 metodo sin choque queda como lista de uno" [E1.name] C.name}
   {Check "t4 tiene los metodos de ambos" [address attributes display name personEmployer personName] {Arity C}}
   {Check "t4 los atributos siguen la regla del primero" E1.attributes.name C.attributes.name}
   {Check "t4 tres implementaciones en orden" [T1.step T2.step T3.step] CT.step}
   {Check "t4 idempotencia" 1 {Length {ExplicitCompositionPoly [E1 E1]}.display}}
   {Check "t4 idempotencia [T1 T2 T1]" [T1.step T2.step] {ExplicitCompositionPoly [T1 T2 T1]}.step}
end

local
   E1 = {NewEmployer "Uniandes" "Cra 1 # 18A-12"}
   P1 = {NewPerson "Ana" E1}
   A1 = {NewAccount 100}
   A2 = {NewAccount 500}
   C  = {ExplicitCompositionPoly [E1 P1]}
   CA = {ExplicitCompositionPoly [A1 A2]}
   CC = {ExplicitCompositionPoly [{NewCalculator}]}
   Log = {NewCell nil}
   CT = {ExplicitCompositionPoly [{NewTracer a Log false} {NewTracer b Log false}]}
in
   {System.showInfo "-- Tarea 5"}
   {Check "t5 funcion sin parametros devuelve su valor" "Uniandes" {Dispatch C name $ 1}}
   {Check "t5 metodo de Person" "Ana" {Dispatch C personName $ 1}}
   {Check "t5 personEmployer" "Uniandes" {Dispatch C personEmployer $ 1}}
   {Dispatch CA deposit 10 1}
   {Check "t5 llamada del enunciado {Dispatch A deposit 10 1}" 110 {A1.balance}}
   {Check "t5 solo se ejecuta la implementacion pedida" 500 {A2.balance}}
   {Dispatch CA deposit 10 2}
   {Check "t5 indice 2 usa la segunda implementacion" 510 {A2.balance}}
   {Check "t5 balance con indice 1" 110 {Dispatch CA balance $ 1}}
   {Check "t5 balance con indice 2" 510 {Dispatch CA balance $ 2}}
   {Dispatch CA deposit 10 3}
   {Check "t5 indice fuera de rango no tiene efecto" 110#510 {A1.balance}#{A2.balance}}
   {Dispatch CT step nil 1}
   {Check "t5 procedimiento sin parametros" [a] @Log}
   {Check "t5 varios parametros en una lista" 5 local R in {Dispatch CC sum [2 3 R] 1} R end}
   {Check "t5 procedimiento con 4 parametros" b#a local R1 R2 in {Dispatch CC swap [a b R1 R2] 1} R1#R2 end}
   {Check "t5 funciona sobre un objeto normal" "Uniandes" {Dispatch E1 name $ 1}}
   {Check "t5 funciona sobre ExplicitComposition" "Ana" {Dispatch {ExplicitComposition [E1 P1]} personName $ 1}}
   {Check "t5 funciona sobre ImplicitComposition" "Ana" {Dispatch {ImplicitComposition [E1 P1]} personName $ 1}}
   {Check "t5 objeto normal con indice 2 no hace nada" none local R in {Dispatch E1 name R 2} if {IsDet R} then R else none end end}
   {Check "t5 parametros mal formados dan error" badParams {ErrorKind proc {$} {Dispatch CC sum [2] 1} end}}
   {Check "t5 selector inexistente da error" otherError {ErrorKind proc {$} {Dispatch C foo nil 1} end}}
end

local
   Log = {NewCell nil}
   Other = {NewCell nil}
   A = {NewTracer a Log true}
   B = {NewTracer b Log true}
   C = {NewTracer c Log true}
   Stop = {NewTracer stop Log false}
   Nested = local
               fun {Attributes} attributes end
               proc {Step}
                  Log := {Append @Log [nested]}
                  {Dispatch {ExplicitCompositionPoly [{NewTracer x Other true} {NewTracer y Other true}]} step nil 1}
                  {NextFunction}
               end
            in
               object(attributes: {Attributes} step: Step)
            end
   Broken = local
               fun {Attributes} attributes end
               proc {Step} raise boom end end
            in
               object(attributes: {Attributes} step: Step)
            end
   K1 = {NewCounter 0}
   K2 = {NewCounter 10}
   K3 = {NewCounter 100}
   Clear = proc {$} Log := nil end
in
   {System.showInfo "-- Tarea 6"}
   {Dispatch {ExplicitCompositionPoly [A B C]} step nil 1}
   {Check "t6 NextFunction recorre todas las implementaciones" [a b c] @Log}
   {Clear}
   {Dispatch {ExplicitCompositionPoly [A B C]} step nil 2}
   {Check "t6 empezar en el indice 2" [b c] @Log}
   {Clear}
   {Dispatch {ExplicitCompositionPoly [A B C]} step nil 3}
   {Check "t6 empezar en el ultimo indice" [c] @Log}
   {Clear}
   {Dispatch {ExplicitCompositionPoly [A Stop C]} step nil 1}
   {Check "t6 la cadena se corta si un metodo no llama NextFunction" [a stop] @Log}
   {Clear}
   {Dispatch {ExplicitCompositionPoly [Stop A]} step nil 1}
   {Check "t6 sin NextFunction solo corre el primero" [stop] @Log}
   {Clear}
   {Dispatch {ExplicitCompositionPoly [A]} step nil 1}
   {Check "t6 NextFunction en la ultima implementacion no hace nada" [a] @Log}
   {Clear}
   {Dispatch {ExplicitCompositionPoly [K1 K2 K3]} add 5 1}
   {Check "t6 NextFunction reenvia los parametros" 5#15#105 {K1.count}#{K2.count}#{K3.count}}
   {Dispatch {ExplicitCompositionPoly [K1 K2 K3]} add 1 2}
   {Check "t6 NextFunction con parametros desde el indice 2" 5#16#106 {K1.count}#{K2.count}#{K3.count}}
   {Dispatch {ExplicitCompositionPoly [A Nested B]} step nil 1}
   {Check "t6 un Dispatch anidado no rompe la cadena externa" [a nested b] @Log}
   {Check "t6 el Dispatch anidado corre su propia cadena" [x y] @Other}
   {Clear}
   {NextFunction}
   {Check "t6 NextFunction fuera de un Dispatch no hace nada" nil @Log}
   {Check "t6 una excepcion en un metodo se propaga" otherError {ErrorKind proc {$} {Dispatch {ExplicitCompositionPoly [Broken A]} step nil 1} end}}
   {NextFunction}
   {Check "t6 despues de una excepcion NextFunction queda limpio" nil @Log}
end

{System.showInfo ""}
{System.showInfo "Pruebas correctas: "#@Passed}
{System.showInfo "Pruebas fallidas:  "#@Failed}
