%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ISIS-4217 Paradigmas de programacion
%% Proyecto: Orientacion a objetos - objetos componibles con "metafunciones"
%% Archivo: composition.oz
%% Tareas implementadas en este archivo: 1, 2, 3, 4, 5 y 6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% IDEA GENERAL
%% ------------
%% No construimos un lenguaje de objetos nuevo: representamos un objeto como un
%% REGISTRO (record) de funciones con nombre, siguiendo la "modularidad
%% empaquetada" (bundled modularity) del libro, con dos diferencias que pide el
%% enunciado:
%%
%%   1. Los atributos son valores modificables DECLARADOS EXPLICITAMENTE dentro
%%      de la funcion que crea el objeto. Se declaran como celdas (NewCell) y su
%%      valor inicial se da al momento de crear el objeto.
%%   2. Los atributos son parte explicita de la estructura del objeto: cada
%%      objeto define internamente una funcion "Attributes" que devuelve un
%%      registro con etiqueta 'attributes' cuyos campos son los nombres de los
%%      atributos y cuyos valores son las CELDAS correspondientes.
%%
%% Entonces la forma de un objeto es:
%%
%%   object(attributes: attributes(nombreAtributo1: <Celda> ...)
%%          metodo1: <Funcion o Procedimiento>
%%          metodo2: <Funcion o Procedimiento>
%%          ...)
%%
%% Los metodos se invocan seleccionando el campo del registro y aplicandolo:
%%      {O.name}          % llamada sin parametros
%%      {O.deposit 10}    % llamada con parametros
%%
%% El estado vive UNICAMENTE en las celdas: los metodos son clausuras que
%% capturan esas celdas. Esto es clave para la composicion, porque al copiar un
%% metodo de un objeto a otro el metodo sigue apuntando a la MISMA celda: nunca
%% se duplica el estado.
%%
%% NOTA SOBRE "cualquier numero de objetos"
%% ----------------------------------------
%% En Oz la aridad de un procedimiento es fija, no existe el equivalente a los
%% varargs. Por eso las metafunciones de composicion reciben una LISTA de
%% objetos:  {ExplicitComposition [O1 O2 O3]}. Es la traduccion directa de
%% {Compose O1 O2 O3} del enunciado y permite componer N objetos.
%%
%% COMO EJECUTAR
%% -------------
%% Alimentar el archivo completo en el OPI de Mozart (Oz > Feed Buffer). El
%% bloque final de PRUEBAS imprime en la consola los resultados de las tres
%% tareas; todas las comparaciones deben mostrar 'true'.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0. FUNCIONES AUXILIARES (nivel meta)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% Campos "reservados" que NO son metodos del objeto.
%%   attributes   -> registro de atributos (celdas)
%%   constituents -> solo lo usa la composicion implicita (Tarea 3) para
%%                   guardar los objetos que componen al objeto compuesto.

%% {MethodFeatures Obj} devuelve la lista de nombres de campo de Obj que
%% corresponden a metodos, es decir, todos los campos menos los reservados.
fun {MethodFeatures Obj}
   {List.filter {Arity Obj}
    fun {$ F} F \= attributes andthen F \= constituents end}
end

%% {ObjectMethods Obj} devuelve el objeto SIN los campos reservados, o sea,
%% solamente el registro de sus metodos. Se usa para poder mezclar metodos y
%% atributos con reglas distintas.
fun {ObjectMethods Obj}
   {Record.subtract {Record.subtract Obj attributes} constituents}
end

%% {AllMethodFeatures Objs} devuelve la union ORDENADA (sin repetidos) de los
%% nombres de metodo de todos los objetos de la lista, respetando el orden de
%% aparicion: primero los del primer objeto, luego los nuevos del segundo, etc.
fun {AllMethodFeatures Objs}
   {RemoveDuplicates {List.flatten {Map Objs MethodFeatures}}}
end

%% {ComposeAttributes Objs} mezcla los registros 'attributes' de todos los
%% objetos de la lista.
%% Regla del enunciado: si un atributo aparece en varios objetos, gana la celda
%% del PRIMER objeto en el que aparece.
%% Implementacion: {Adjoin R1 R2} produce un registro con los campos de ambos y,
%% en caso de choque, se queda con el valor de R2. Recorriendo la lista de
%% derecha a izquierda (foldR) el acumulador trae los objetos posteriores y el
%% objeto actual (que esta mas a la izquierda) se ajunta de segundo, por lo que
%% termina ganando el primero de la lista.
fun {ComposeAttributes Objs}
   {List.foldR Objs
    fun {$ Obj Acc} {Adjoin Acc Obj.attributes} end
    attributes}   % registro vacio con etiqueta attributes
end

%% {RemoveDuplicates Xs} elimina repetidos conservando la primera aparicion.
%% Es lo que le da IDEMPOTENCIA a la composicion: componer el mismo objeto dos
%% veces no agrega informacion nueva.
fun {RemoveDuplicates Xs}
   case Xs
   of nil then nil
   [] X|Xr then X|{RemoveDuplicates {List.filter Xr fun {$ Y} Y \= X end}}
   end
end

%% {ResolveMethod Objs F} busca el metodo F en la lista de objetos y devuelve la
%% implementacion del PRIMER objeto que lo tenga (regla de resolucion de
%% choques del enunciado). Es la "busqueda de metodo" (method lookup) de nuestro
%% sistema de objetos.
fun {ResolveMethod Objs F}
   case Objs
   of nil then raise metaError(methodNotFound F) end
   [] Obj|Objr then
      if {HasFeature Obj F} then Obj.F else {ResolveMethod Objr F} end
   end
end

%% {MakeForwarder Objs F} construye un "reenviador" (delegado) para el metodo F.
%% Solo lo usa la composicion implicita (Tarea 3).
%%
%% El reenviador es un procedimiento con la MISMA aridad que el metodo original
%% que, cada vez que se invoca, vuelve a resolver F sobre la lista de objetos y
%% le pasa los argumentos tal cual. Es decir, hace enlace tardio (late binding):
%% el objeto compuesto no guarda una copia del metodo, sino la forma de llegar
%% a el.
%%
%% Detalles de Oz:
%%   - En Oz una funcion es azucar sintactica de un procedimiento con un
%%     argumento extra de salida, asi que un procedimiento reenviador de la
%%     misma aridad sirve tanto para 'proc' como para 'fun'.
%%   - {Procedure.arity P} da esa aridad total, y como no se pueden construir
%%     procedimientos de aridad arbitraria en tiempo de ejecucion, enumeramos
%%     los casos (soportamos hasta 4 parametros reales, suficiente de sobra).
fun {MakeForwarder Objs F}
   case {Procedure.arity {ResolveMethod Objs F}}
   of 0 then proc {$} {{ResolveMethod Objs F}} end
   [] 1 then proc {$ A} {{ResolveMethod Objs F} A} end
   [] 2 then proc {$ A B} {{ResolveMethod Objs F} A B} end
   [] 3 then proc {$ A B C} {{ResolveMethod Objs F} A B C} end
   [] 4 then proc {$ A B C D} {{ResolveMethod Objs F} A B C D} end
   [] 5 then proc {$ A B C D E} {{ResolveMethod Objs F} A B C D E} end
   elseof N then raise metaError(unsupportedArity F N) end
   end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAREA 1. DEFINICION DE OBJETOS
%%
%% Cada objeto se crea con una funcion (NewEmployer / NewPerson) que:
%%   a) declara sus atributos como celdas, con el valor inicial recibido,
%%   b) define una funcion local Attributes que devuelve el registro
%%      attributes(...) con esas celdas,
%%   c) define sus metodos como clausuras sobre las celdas,
%%   d) devuelve el registro object(attributes:... metodo:... ...).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% Objeto Employer:
%%   atributos: name, address
%%   metodos  : name (devuelve el nombre), address (devuelve la direccion),
%%              display (muestra el objeto por consola)
fun {NewEmployer InitName InitAddress}
   %% a) Atributos: celdas explicitas con su valor inicial.
   CellName    = {NewCell InitName}
   CellAddress = {NewCell InitAddress}

   %% b) Los atributos son parte explicita de la estructura del objeto.
   fun {Attributes}
      attributes(name:    CellName
                 address: CellAddress)
   end

   %% c) Metodos: clausuras que leen/escriben las celdas anteriores.
   fun {Name}    @CellName    end
   fun {Address} @CellAddress end

   proc {Display}
      {System.showInfo "Employer"}
      {System.showInfo "Name: "#@CellName}
      {System.showInfo "Address: "#@CellAddress}
   end
in
   %% d) El objeto es el registro de sus atributos y sus metodos.
   object(attributes: {Attributes}
          name:       Name
          address:    Address
          display:    Display)
end

%% Objeto Person:
%%   atributos: name, employer  (employer guarda un objeto Employer)
%%   metodos  : personName     -> nombre de la persona
%%              personEmployer -> nombre del empleador (no el objeto)
%%              display        -> muestra el objeto por consola
fun {NewPerson InitName InitEmployer}
   CellName     = {NewCell InitName}
   CellEmployer = {NewCell InitEmployer}

   fun {Attributes}
      attributes(name:     CellName
                 employer: CellEmployer)
   end

   fun {PersonName} @CellName end

   %% El atributo employer es un objeto Employer, asi que para obtener su
   %% nombre le enviamos su metodo name. Si por alguna razon el atributo no es
   %% un objeto (por ejemplo un string suelto), lo devolvemos tal cual.
   fun {PersonEmployer}
      E = @CellEmployer
   in
      if {IsRecord E} andthen {HasFeature E name} then {E.name} else E end
   end

   proc {Display}
      {System.showInfo "Person"}
      {System.showInfo "Name: "#@CellName}
   end
in
   object(attributes:     {Attributes}
          personName:     PersonName
          personEmployer: PersonEmployer
          display:        Display)
end

%% Objeto adicional Account. No lo pide el enunciado para la Tarea 1, pero sirve
%% para probar metodos CON PARAMETROS (los objetos anteriores solo tienen
%% metodos sin argumentos) y para verificar que la composicion implicita reenvia
%% correctamente los argumentos.
%%   atributos: balance
%%   metodos  : balance -> saldo actual
%%              deposit -> suma un monto al saldo
fun {NewAccount InitBalance}
   CellBalance = {NewCell InitBalance}

   fun {Attributes}
      attributes(balance: CellBalance)
   end

   fun {Balance} @CellBalance end

   proc {Deposit Amount}
      CellBalance := @CellBalance + Amount
   end
in
   object(attributes: {Attributes}
          balance:    Balance
          deposit:    Deposit)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAREA 2. COMPOSICION EXPLICITA
%%
%% {ExplicitComposition Objs} recibe una lista de objetos y CONSTRUYE UN OBJETO
%% NUEVO que contiene los atributos y metodos de todos sus constituyentes.
%%
%% Reglas (del enunciado):
%%   - Idempotencia: componer el mismo objeto dos veces devuelve el objeto sin
%%     informacion replicada. Se garantiza de dos formas: quitando duplicados de
%%     la lista y porque, ante un choque, el resultado es el mismo campo.
%%   - Polimorfismo/choques: si un atributo o metodo aparece en varios objetos,
%%     queda la version del PRIMER objeto en el que aparece.
%%
%% Importante: el objeto compuesto COPIA las clausuras de los constituyentes,
%% pero esas clausuras siguen apuntando a las celdas originales. Por eso el
%% estado se comparte y no se duplica:
%%     {O1.name} == {Comp.name}   ->  true
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

fun {ExplicitComposition Objs}
   Unique  = {RemoveDuplicates Objs}          % idempotencia
   %% Mezcla de metodos: igual que con los atributos, se recorre de derecha a
   %% izquierda para que en un choque gane el objeto que aparece primero.
   Methods = {List.foldR Unique
              fun {$ Obj Acc} {Adjoin Acc {ObjectMethods Obj}} end
              object}
in
   %% Se agrega el registro de atributos ya mezclado.
   {AdjoinAt Methods attributes {ComposeAttributes Unique}}
end

%% Alias con el nombre generico que usa el enunciado en el Snippet 1.
Compose = ExplicitComposition


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAREA 3. COMPOSICION IMPLICITA
%%
%% {ImplicitComposition Objs} tambien recibe una lista de objetos, pero en vez
%% de copiar sus metodos, GUARDA A LOS OBJETOS DENTRO del objeto compuesto (en
%% el campo reservado 'constituents') y usa sus atributos y metodos cuando hace
%% falta, delegando.
%%
%% Como se logra: para cada nombre de metodo que exista en algun constituyente,
%% el objeto compuesto expone un REENVIADOR (ver MakeForwarder). El reenviador
%% no guarda el metodo: guarda la lista de constituyentes y, en cada llamada,
%% resuelve el metodo con {ResolveMethod ...} y le pasa los argumentos.
%%
%% Diferencia real con la Tarea 2:
%%   - Explicita: la busqueda del metodo ocurre UNA VEZ, al componer. El objeto
%%     resultante es autonomo y ya no depende de sus constituyentes.
%%   - Implicita: la busqueda ocurre EN CADA LLAMADA (enlace tardio). El objeto
%%     compuesto es una fachada que delega en los objetos que lo componen, y
%%     conserva la referencia a ellos en 'constituents'.
%%
%% Las reglas de idempotencia y de "gana el primero" se mantienen: los
%% duplicados se eliminan de la lista de constituyentes, la union de nombres de
%% metodo respeta el orden de aparicion y ResolveMethod siempre escoge el primer
%% objeto que define el metodo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

fun {ImplicitComposition Objs}
   Unique = {RemoveDuplicates Objs}
   %% Un campo por cada metodo disponible, cuyo valor es el reenviador.
   Fields = {Map {AllMethodFeatures Unique}
             fun {$ F} F#{MakeForwarder Unique F} end}
in
   %% El objeto compuesto tiene la misma forma que cualquier otro objeto
   %% (etiqueta object + campo attributes + metodos), de modo que se puede usar
   %% igual, e incluso volver a componer.
   {AdjoinList object(attributes:   {ComposeAttributes Unique}
                      constituents: Unique)
    Fields}
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAREA 4. COMPOSICION EXPLICITA POLIMORFICA
%%
%% {ExplicitCompositionPoly Objs} compone como la Tarea 2, pero cuando hay un
%% CHOQUE de metodos (el mismo nombre definido en varios objetos) ya no gana el
%% primero y se descartan los demas: se CONSERVAN TODAS las implementaciones,
%% en una lista ordenada segun el orden en que aparecen los objetos en Objs.
%%
%% La forma del objeto compuesto es:
%%
%%   object(attributes: attributes(...)
%%          name:       [NameEmployer]
%%          display:    [DisplayEmployer DisplayPerson])
%%
%% Todos los metodos quedan como lista, incluso los que NO chocan (lista de un
%% solo elemento). Se hizo asi a proposito: la forma del objeto es uniforme, no
%% hay que preguntar si hubo choque para saber como usar un campo, y es
%% justamente lo que espera el despachador de la Tarea 5, que indexa la lista de
%% implementaciones. El precio es que un metodo ya no se invoca directamente
%% ({CP.name} es una lista, no un procedimiento): se invoca la implementacion
%% que se quiera, {{List.nth CP.name 1}}, o se deja que Dispatch lo haga.
%%
%% Diferencias con la Tarea 2:
%%   - Explicita (Tarea 2) : choque -> gana el primero, el resto se pierde.
%%   - Polimorfica (Tarea 4): choque -> quedan todas, ordenadas.
%%
%% Lo demas no cambia: los atributos se mezclan con la regla de siempre
%% ({ComposeAttributes}: ante un choque queda la celda del primer objeto, o sea
%% que el estado se sigue compartiendo y no se duplica), y la composicion sigue
%% siendo idempotente porque {RemoveDuplicates} deja un solo ejemplar de cada
%% objeto: {ExplicitCompositionPoly [E E]} da listas de largo 1.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% {AllImplementations Objs F} es la variante polimorfica de {ResolveMethod}:
%% en vez de cortar en el primer objeto que define F, recorre la lista completa
%% y devuelve TODAS las implementaciones de F, en orden de aparicion.
fun {AllImplementations Objs F}
   case Objs
   of nil then nil
   [] Obj|Objr then
      if {HasFeature Obj F} then Obj.F|{AllImplementations Objr F}
      else {AllImplementations Objr F}
      end
   end
end

%% {ExplicitCompositionPoly Objs} arma un campo por cada nombre de metodo que
%% exista en algun constituyente ({AllMethodFeatures} ya devuelve esa union sin
%% repetidos y en orden), y el valor del campo es la lista de implementaciones.
fun {ExplicitCompositionPoly Objs}
   Unique = {RemoveDuplicates Objs}          % idempotencia
   Fields = {Map {AllMethodFeatures Unique}
             fun {$ F} F#{AllImplementations Unique F} end}
in
   {AdjoinList object(attributes: {ComposeAttributes Unique}) Fields}
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAREA 5. FUNCION DE DESPACHO (Dispatch)
%%
%% Despues de la Tarea 4 los metodos del objeto compuesto ya NO son
%% procedimientos: son LISTAS de implementaciones. Por eso {CP.display} no se
%% puede aplicar, seria aplicar una lista. Hace falta una metafuncion que
%% seleccione una implementacion de la lista y la invoque:
%%
%%      {Dispatch CP display nil}      en vez de   {CP.display}
%%      {Dispatch CP deposit [10]}     en vez de   {CP.deposit 10}
%%
%% Firma: receptor, selector (nombre del metodo), parametros.
%% Los parametros van en una LISTA por la misma razon que las composiciones
%% reciben una lista de objetos: en Oz la aridad es fija, no hay varargs.
%%
%% Semantica pedida por el enunciado: "debe funcionar exactamente como
%% funcionaban las funciones en ExplicitComposition", es decir, ante un choque
%% gana el PRIMERO. Como {AllImplementations} construyo la lista en orden de
%% aparicion, eso es simplemente tomar el elemento 1.
%%
%% El unico punto delicado es aplicar la implementacion, porque en Oz una 'fun'
%% es azucar de un 'proc' con un argumento de salida extra. Un metodo como
%% Balance (fun sin parametros) y un metodo como Deposit (proc con un
%% parametro) tienen los dos aridad 1, y solo se distinguen comparando esa
%% aridad con la cantidad de argumentos que recibimos. De eso se encarga
%% CallWithResult, que ademas devuelve 'unit' cuando la implementacion era un
%% procedimiento (no produce resultado).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% {CallWithResult P Args} aplica P a los argumentos de la lista Args.
%%   - Si {Procedure.arity P} == {Length Args}, P es un procedimiento: se
%%     ejecuta y se devuelve unit.
%%   - Si {Procedure.arity P} == {Length Args}+1, P es una funcion: el argumento
%%     sobrante es el de salida y se devuelve lo que P produce.
%% Igual que en MakeForwarder, los casos de aridad se enumeran porque no se
%% pueden construir aplicaciones de aridad arbitraria en tiempo de ejecucion.
fun {CallWithResult P Args}
   Arity = {Procedure.arity P}
   NArgs = {Length Args}
in
   if Arity == NArgs then
      case Args
      of nil          then {P}         unit
      [] [A]          then {P A}       unit
      [] [A B]        then {P A B}     unit
      [] [A B C]      then {P A B C}   unit
      [] [A B C D]    then {P A B C D} unit
      else raise metaError(dispatchTooManyArgs NArgs) end
      end
   elseif Arity == NArgs+1 then
      case Args
      of nil          then {P $}
      [] [A]          then {P A $}
      [] [A B]        then {P A B $}
      [] [A B C]      then {P A B C $}
      [] [A B C D]    then {P A B C D $}
      else raise metaError(dispatchTooManyArgs NArgs) end
      end
   else
      raise metaError(dispatchArityMismatch Arity NArgs) end
   end
end

%% {Dispatch Obj Selector Args} ejecuta la primera implementacion del metodo.
%% Se define con el nombre DispatchT5 y se expone como Dispatch: la Tarea 6
%% vuelve a ligar el nombre Dispatch, y asi la version de esta tarea sigue
%% disponible (y probable) hasta el final del archivo.
fun {DispatchT5 Obj Selector Args}
   {CallWithResult {List.nth Obj.Selector 1} Args}
end

declare Dispatch = DispatchT5

%% Demostracion de la Tarea 5. Se construyen objetos propios porque los del
%% bloque final de PRUEBAS se declaran mas abajo, y para entonces Dispatch ya
%% habra sido redefinido por la Tarea 6.
local E5 A5 D5 in
   E5 = {NewEmployer "Uniandes" "Cra 1 # 18A-12"}
   A5 = {NewAccount 100}
   D5 = {ExplicitCompositionPoly [E5 {NewPerson "Ana" E5} A5]}

   {System.showInfo ""}
   {System.showInfo "== Tarea 5: Dispatch =="}
   %% Metodo con parametro (proc): no devuelve nada, modifica la celda.
   {System.show {Dispatch D5 deposit [50]}}         % unit
   %% Metodo sin parametros que devuelve valor (fun).
   {System.showInfo "balance -> "#{Dispatch D5 balance nil}}   % 150
   {System.show {Dispatch D5 balance nil} == {A5.balance}}     % true
   %% Metodo con choque: display esta en Employer y en Person, gana Employer.
   {Dispatch D5 display nil _}
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAREA 6. DESPACHO CON INDICE Y NextFunction
%%
%% Ahora si le sacamos provecho a guardar todas las implementaciones. Dispatch
%% se REDEFINE con un cuarto argumento, el indice de la implementacion a llamar
%% (el 'declare' vuelve a ligar el nombre, asi que de aqui en adelante Dispatch
%% es esta version de 4 argumentos):
%%
%%      {Dispatch A deposit [10] 1}   llama la primera implementacion
%%      {Dispatch A deposit [10] 2}   llama la segunda
%%
%% Con indice 1 el comportamiento es identico al de la Tarea 5. Un indice mayor
%% al numero de implementaciones no hace nada, como pide el enunciado.
%%
%% {NextFunction} se llama DESDE DENTRO de un metodo y continua con la siguiente
%% implementacion. Para que el metodo sepa cual es "la siguiente" sin recibir el
%% indice como parametro, Dispatch deja la continuacion en la celda NextThunk
%% antes de invocar la implementacion actual, y restaura el valor anterior al
%% terminar. Ese guardar/restaurar es lo que permite que los despachos anidados
%% (un metodo que despacha otro metodo) no se pisen entre si.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% Continuacion vigente: el thunk que ejecutara {NextFunction}.
NextThunk = {NewCell fun {$} unit end}

fun {Dispatch Obj Selector Args Index}
   Impls = Obj.Selector
in
   if Index > {Length Impls} then unit
   else
      Curr = {List.nth Impls Index}
      OldNext
      R
   in
      {Exchange NextThunk OldNext fun {$} {Dispatch Obj Selector Args Index+1} end}
      R = {CallWithResult Curr Args}
      {Exchange NextThunk _ OldNext}
      R
   end
end

fun {NextFunction} {@NextThunk} end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PRUEBAS / EJEMPLOS
%% Ejecutar este bloque muestra el comportamiento de las tareas 1, 2 y 3.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare
E    = {NewEmployer "Uniandes" "Cra 1 # 18A-12"}
P    = {NewPerson "Ana" E}
CE   = {ExplicitComposition [E P]}   % Tarea 2
CI   = {ImplicitComposition [E P]}   % Tarea 3
CIde = {ExplicitComposition [E E]}   % idempotencia
A    = {NewAccount 100}
AE   = {ExplicitComposition [A P]}   % con metodos que reciben parametros
AI   = {ImplicitComposition [A P]}

proc {Titulo T} {System.showInfo ""} {System.showInfo "== "#T#" =="} end

{Titulo "Tarea 1: objetos basicos"}
{E.display}
{P.display}
{System.showInfo "PersonEmployer -> "#{P.personEmployer}}

{Titulo "Tarea 2: composicion explicita"}
%% El compuesto responde a los metodos de los dos constituyentes.
{System.showInfo "name           -> "#{CE.name}}
{System.showInfo "address        -> "#{CE.address}}
{System.showInfo "personName     -> "#{CE.personName}}
{System.showInfo "personEmployer -> "#{CE.personEmployer}}
%% display esta en ambos objetos: gana el del primero (Employer).
{CE.display}
%% El estado se comparte, no se copia (esto es el Snippet 1 del enunciado).
{System.showInfo "Comparte estado con E:"}
{System.show {E.name} == {CE.name}}                      % true
{System.show E.attributes.name == CE.attributes.name}     % true (misma celda)
%% El atributo name aparece en los dos objetos: queda la celda de Employer.
{Assign CE.attributes.name "Uniandes S.A."}
{System.showInfo "Tras modificar la celda desde el compuesto, E.name -> "#{E.name}}
{Assign CE.attributes.name "Uniandes"}   % se deja como estaba

{Titulo "Tarea 2: idempotencia"}
{System.show {Arity CIde} == {Arity E}}   % true: no se replico informacion
{System.show {CIde.name} == {E.name}}     % true

{Titulo "Tarea 3: composicion implicita"}
{System.showInfo "name           -> "#{CI.name}}
{System.showInfo "personName     -> "#{CI.personName}}
{System.showInfo "personEmployer -> "#{CI.personEmployer}}
{CI.display}                              % tambien gana el display de Employer
{System.show {E.name} == {CI.name}}       % true
%% A diferencia de la explicita, el objeto conserva a sus constituyentes y
%% resuelve cada llamada en el momento de invocarla.
{System.showInfo "Numero de constituyentes:"}
{System.show {Length CI.constituents}}    % 2

{Titulo "Metodos con parametros a traves de la composicion"}
{AE.deposit 50}                           % explicita: 100 + 50
{AI.deposit 25}                           % implicita: 150 + 25
{System.showInfo "Saldo final -> "#{A.balance}}   % 175
{System.show {A.balance} == {AI.balance}} % true: una sola celda de estado

{Titulo "Composicion de composiciones"}
%% Un objeto compuesto es un objeto normal, se puede volver a componer.
%% Aqui usamos el alias Compose, que es el nombre del Snippet 1 del enunciado.
{System.showInfo "personName    -> "#{{Compose [CI A]}.personName}}

declare
fun {NewLoud Msg}
   proc {Announce}
      {System.showInfo "LOUD: "#Msg}
      {NextFunction _}
   end
in
   object(attributes: attributes announce: Announce)
end

fun {NewQuiet Msg}
   proc {Announce}
      {System.showInfo "quiet: "#Msg}
   end
in
   object(attributes: attributes announce: Announce)
end

CP = {ExplicitCompositionPoly [E P]}
L  = {NewLoud "hola"}
Q  = {NewQuiet "hola"}
CN = {ExplicitCompositionPoly [L Q]}

{Titulo "Tarea 4: composicion explicita polimorfica"}
%% display choca: Employer y Person lo definen, y quedan las dos versiones.
{System.showInfo "Implementaciones de display en CP:"}
{System.show {Length CP.display}}                  % 2
%% name no choca, pero igual queda como lista (forma uniforme).
{System.show {Length CP.name}}                     % 1
%% Se puede invocar cualquiera de las implementaciones conservadas.
{{List.nth CP.display 1}}                          % el display de Employer
{{List.nth CP.display 2}}                          % el display de Person
%% El estado se sigue compartiendo con los constituyentes.
{System.show {{List.nth CP.name 1}} == {E.name}}   % true
%% Idempotencia: componer el mismo objeto dos veces no replica implementaciones.
{System.show {Length {ExplicitCompositionPoly [E E]}.display}}   % 1

{Titulo "Tarea 5: Dispatch sin indice"}
%% La firma de la Tarea 5 es (receptor, selector, parametros) y siempre ejecuta
%% la primera implementacion, igual que ExplicitComposition.
{DispatchT5 CP display nil _}                       % el display de Employer
{System.showInfo "name -> "#{DispatchT5 CP name nil}}
{System.show {DispatchT5 CP name nil} == {E.name}}  % true
%% Metodo con parametros: deposit es un proc, el despacho devuelve unit.
{System.show {DispatchT5 {ExplicitCompositionPoly [A P]} deposit [10]}}
{System.showInfo "balance tras el deposito -> "#{A.balance}}

{Titulo "Tarea 6: Dispatch con indice"}
{Dispatch CP display nil 1 _}         % ejecuta el display de Employer
{Dispatch CP display nil 2 _}         % ejecuta el display de Person
{Dispatch CP display nil 3 _}         % indice fuera de rango: no hace nada

{Titulo "Tarea 6: NextFunction"}
{Dispatch CN announce nil 1 _}        % Loud imprime su mensaje y llama a NextFunction,
                                      % que dispara Quiet (indice 2)
