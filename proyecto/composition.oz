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
%% Alimentar tests.oz en el OPI de Mozart (Oz > Feed Buffer). Ese
%% archivo incluye a este con \insert y corre las demos y los casos
%% de prueba de las seis tareas. Este archivo solo define las funciones.
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
%% procedimientos: son LISTAS de implementaciones. Por eso {CP.deposit 10} no se
%% puede aplicar (seria aplicar una lista). Hace falta una metafuncion que
%% escoja una implementacion de la lista y la invoque:
%%
%%      {Dispatch CP deposit 10 1}     en vez de   {CP.deposit 10}
%%
%% La Tarea 5 pide que el despacho funcione "exactamente como funcionaban las
%% funciones en ExplicitComposition", es decir, que ante un choque se use la
%% PRIMERA implementacion. Eso es lo que hace {Dispatch Obj Sel Params 1}. La
%% Tarea 6 agrega el argumento del indice, asi que este unico Dispatch cubre
%% las dos tareas: el indice 1 es el comportamiento de la Tarea 5.
%%
%% Como se pasan los parametros (Params). En Oz la aridad es fija y no hay
%% varargs, asi que la forma depende de cuantos parametros tiene el metodo:
%%   - sin parametros            : {Dispatch A display nil 1}
%%   - un parametro              : {Dispatch A deposit 10 1}   (tal cual, sin lista)
%%   - varios parametros         : {Dispatch A sum [2 3 R] 1}  (en una lista)
%%   - una funcion (devuelve algo): el resultado va en el ultimo argumento del
%%     metodo, o se recibe con $:  {Dispatch A balance $ 1}
%% Recordar que en Oz una 'fun' es azucar de un 'proc' con un argumento de
%% salida extra, por eso el resultado se trata como un parametro mas.
%%
%% Si Params no tiene la forma que espera el metodo, se lanza
%% metaError(badParams Aridad Params).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% {CallMethod P Params} aplica el procedimiento P a los parametros Params. Se
%% decide por la aridad de P porque no se pueden construir aplicaciones de
%% aridad arbitraria en tiempo de ejecucion (mismo motivo que MakeForwarder).
proc {CallMethod P Params}
   case {Procedure.arity P}#Params
   of 0#_ then {P}
   [] 1#_ then {P Params}
   [] 2#[A B] then {P A B}
   [] 3#[A B C] then {P A B C}
   [] 4#[A B C D] then {P A B C D}
   [] 5#[A B C D E] then {P A B C D E}
   [] N#_ then raise metaError(badParams N Params) end
   end
end

%% {Implementations Method} devuelve la lista de implementaciones de un campo.
%% Si el campo ya es una lista (objeto de la Tarea 4) la deja igual; si es un
%% procedimiento suelto (objeto de las Tareas 1, 2 o 3) lo envuelve en una lista
%% de un elemento. Asi Dispatch funciona con cualquier objeto del sistema.
fun {Implementations Method}
   if {IsList Method} then Method else [Method] end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAREA 6. INDICE EN Dispatch Y NextFunction
%%
%% {Dispatch Obj Selector Params Index} llama a la implementacion numero Index
%% (empezando en 1) del metodo Selector:
%%
%%      {Dispatch A deposit 10 1}   llama la primera implementacion
%%      {Dispatch A deposit 10 2}   llama la segunda
%%
%% Un indice mayor al numero de implementaciones no hace nada, como pide el
%% enunciado.
%%
%% {NextFunction} se llama DESDE DENTRO de un metodo y continua con la siguiente
%% implementacion de la lista. Para que el metodo sepa cual es "la siguiente"
%% sin recibir el indice como parametro, Dispatch deja la continuacion (un
%% procedimiento sin argumentos que hace {Dispatch ... Index+1}) en la celda
%% NextThunk justo antes de invocar la implementacion actual, y NextFunction
%% simplemente la ejecuta.
%%
%% Detalles importantes:
%%   - Los parametros no se vuelven a pasar en {NextFunction}: la continuacion
%%     ya los tiene guardados, asi que la siguiente implementacion recibe los
%%     mismos parametros que la actual.
%%   - Despachos anidados: Dispatch guarda el valor anterior de NextThunk y lo
%%     restaura al terminar, para que un metodo que despacha a otro objeto no
%%     pise la continuacion del despacho exterior.
%%   - El 'try ... finally' restaura NextThunk incluso si el metodo lanza una
%%     excepcion, de modo que no quede una continuacion vieja en la celda.
%%   - {NextFunction} fuera de un Dispatch, o en la ultima implementacion, no
%%     hace nada.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% Continuacion vigente: lo que ejecutara {NextFunction}. Al inicio no hace nada.
NextThunk = {NewCell proc {$} skip end}

proc {Dispatch Obj Selector Params Index}
   Impls = {Implementations Obj.Selector}
in
   if Index =< {Length Impls} then
      OldNext
   in
      {Exchange NextThunk OldNext proc {$} {Dispatch Obj Selector Params Index+1} end}
      try
         {CallMethod {Nth Impls Index} Params}
      finally
         NextThunk := OldNext
      end
   end
end

proc {NextFunction}
   {@NextThunk}
end
