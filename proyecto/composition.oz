%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ISIS-4217 Paradigmas de programacion
%% Proyecto: Orientacion a objetos - objetos componibles con "metafunciones"
%% Archivo: composition.oz
%% Tareas 1, 2, 3, 4, 5 y 6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% COMO REPRESENTAMOS UN OBJETO
%%
%% Aca no inventamos un lenguaje de objetos nuevo. Un objeto es simplemente un
%% record de funciones con nombre, como la modularidad empaquetada del libro,
%% pero con dos cosas que pide el enunciado:
%%
%%   1. Los atributos se declaran explicitamente dentro de la funcion que crea
%%      el objeto, como celdas (NewCell), y su valor inicial llega por
%%      parametro.
%%   2. Los atributos tambien son parte visible del objeto: cada objeto arma un
%%      record con etiqueta 'attributes' donde los campos son los nombres de los
%%      atributos y los valores son las celdas.
%%
%% Osea que un objeto se ve asi:
%%
%%   object(attributes: attributes(nombreAtributo1: <Celda> ...)
%%          metodo1: <Funcion o Procedimiento>
%%          metodo2: <Funcion o Procedimiento>
%%          ...)
%%
%% Y para llamar un metodo se saca el campo del record y se aplica:
%%      {O.name}          % sin parametros
%%      {O.deposit 10}    % con parametros
%%
%% El estado queda solo en las celdas, y los metodos son clausuras que capturan
%% esas celdas. Eso importa para la composicion: al copiar un metodo de un
%% objeto a otro sigue apuntando a la misma celda, entonces el estado nunca se
%% duplica.
%%
%% SOBRE LO DE "cualquier numero de objetos"
%%
%% En Oz la aridad de un procedimiento es fija, no hay varargs. Por eso las
%% metafunciones de composicion reciben una lista de objetos:
%% {ExplicitComposition [O1 O2 O3]}. Es lo mismo que el {Compose O1 O2 O3} del
%% enunciado y sirve para N objetos.
%%
%% COMO SE CORRE
%%
%% Alimentando tests.oz en el OPI de Mozart (Oz > Feed Buffer). Ese archivo
%% incluye a este con \insert y corre las demos y las pruebas de las seis
%% tareas. Este archivo solo define funciones.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0. FUNCIONES AUXILIARES (nivel meta)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% Hay dos campos que no son metodos: 'attributes', que es el record de celdas,
%% y 'constituents', que solo aparece en la composicion implicita (Tarea 3) para
%% guardar los objetos que forman al compuesto.

%% Devuelve los nombres de campo de Obj que si son metodos, osea todos menos
%% esos dos.
fun {MethodFeatures Obj}
   {List.filter {Arity Obj}
    fun {$ F} F \= attributes andthen F \= constituents end}
end

%% El objeto sin los campos reservados, solo el record de metodos. Sirve para
%% mezclar metodos y atributos con reglas distintas.
fun {ObjectMethods Obj}
   {Record.subtract {Record.subtract Obj attributes} constituents}
end

%% Union sin repetidos de los nombres de metodo de toda la lista, respetando el
%% orden: primero los del primer objeto, despues los nuevos del segundo, etc.
fun {AllMethodFeatures Objs}
   {RemoveDuplicates {List.flatten {Map Objs MethodFeatures}}}
end

%% Mezcla los records 'attributes' de todos los objetos.
%% El enunciado dice que si un atributo esta en varios objetos, queda la celda
%% del primero que lo tenga.
%% {Adjoin R1 R2} junta los campos de ambos y ante un choque se queda con el de
%% R2, asi que recorriendo de derecha a izquierda (foldR) el acumulador trae los
%% objetos de atras y el actual (que esta mas a la izquierda) entra de segundo,
%% entonces gana el primero de la lista.
fun {ComposeAttributes Objs}
   {List.foldR Objs
    fun {$ Obj Acc} {Adjoin Acc Obj.attributes} end
    attributes}   % record vacio con etiqueta attributes
end

%% Quita repetidos dejando la primera aparicion. De aca sale la idempotencia:
%% componer el mismo objeto dos veces no agrega nada nuevo.
fun {RemoveDuplicates Xs}
   case Xs
   of nil then nil
   [] X|Xr then X|{RemoveDuplicates {List.filter Xr fun {$ Y} Y \= X end}}
   end
end

%% Busca el metodo F en la lista y devuelve la implementacion del primer objeto
%% que lo tenga, que es la regla de choques del enunciado. Es el method lookup
%% de nuestro sistema.
fun {ResolveMethod Objs F}
   case Objs
   of nil then raise metaError(methodNotFound F) end
   [] Obj|Objr then
      if {HasFeature Obj F} then Obj.F else {ResolveMethod Objr F} end
   end
end

%% Arma un reenviador (un delegado) para el metodo F. Solo lo usa la composicion
%% implicita (Tarea 3).
%%
%% El reenviador es un procedimiento con la misma aridad del metodo original
%% que, cada vez que lo llaman, vuelve a resolver F sobre la lista de objetos y
%% le pasa los argumentos como vienen. Osea que hace late binding: el objeto
%% compuesto no se guarda una copia del metodo sino como llegar a el.
%%
%% Dos cosas de Oz que hay que tener en cuenta:
%%   - una fun es azucar de un proc con un argumento extra de salida, asi que un
%%     proc reenviador de la misma aridad sirve para los dos casos.
%%   - {Procedure.arity P} da esa aridad total. Como no se pueden construir
%%     procedimientos de aridad arbitraria en tiempo de ejecucion toca enumerar
%%     los casos; hasta 4 parametros reales sobra para lo que necesitamos.
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
%% Cada objeto se crea con una funcion (NewEmployer / NewPerson) que hace cuatro
%% cosas:
%%   a) declara sus atributos como celdas con el valor inicial que recibio,
%%   b) define una funcion local Attributes que arma el record attributes(...)
%%      con esas celdas,
%%   c) define los metodos como clausuras sobre las celdas,
%%   d) devuelve el record object(attributes:... metodo:... ...).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% Employer.
%% Atributos: name, address.
%% Metodos: name y address devuelven lo que dice su nombre, display lo imprime.
fun {NewEmployer InitName InitAddress}
   %% a) los atributos, celdas explicitas con su valor inicial
   CellName    = {NewCell InitName}
   CellAddress = {NewCell InitAddress}

   %% b) los atributos como parte visible del objeto
   fun {Attributes}
      attributes(name:    CellName
                 address: CellAddress)
   end

   %% c) los metodos, que leen y escriben esas mismas celdas
   fun {Name}    @CellName    end
   fun {Address} @CellAddress end

   proc {Display}
      {System.showInfo "Employer"}
      {System.showInfo "Name: "#@CellName}
      {System.showInfo "Address: "#@CellAddress}
   end
in
   %% d) el objeto: sus atributos mas sus metodos
   object(attributes: {Attributes}
          name:       Name
          address:    Address
          display:    Display)
end

%% Person.
%% Atributos: name y employer, donde employer guarda un objeto Employer.
%% Metodos: personName da el nombre, personEmployer da el nombre del empleador
%% (no el objeto) y display imprime.
fun {NewPerson InitName InitEmployer}
   CellName     = {NewCell InitName}
   CellEmployer = {NewCell InitEmployer}

   fun {Attributes}
      attributes(name:     CellName
                 employer: CellEmployer)
   end

   fun {PersonName} @CellName end

   %% Como employer es un objeto Employer, para sacar su nombre le mandamos su
   %% metodo name. Si resulta que no es un objeto (un string suelto por ejemplo)
   %% lo devolvemos tal cual.
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

%% Account no lo pide la Tarea 1, lo agregue para tener un objeto con metodos
%% que reciban parametros (los otros dos no tienen ninguno) y asi poder probar
%% que la composicion implicita reenvia bien los argumentos.
%% Atributos: balance.
%% Metodos: balance da el saldo, deposit le suma un monto.
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
%% {ExplicitComposition Objs} recibe una lista de objetos y construye un objeto
%% nuevo con los atributos y metodos de todos.
%%
%% Las reglas del enunciado:
%%   - idempotencia: componer el mismo objeto dos veces no replica nada. Sale de
%%     quitar duplicados de la lista, y ademas porque ante un choque el campo
%%     que queda es el mismo.
%%   - choques: si un atributo o metodo esta en varios objetos, queda el del
%%     primero.
%%
%% Ojo con un detalle: el objeto compuesto copia las clausuras, pero esas
%% clausuras siguen apuntando a las celdas originales. Por eso el estado se
%% comparte en vez de duplicarse:
%%     {O1.name} == {Comp.name}   ->  true
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

fun {ExplicitComposition Objs}
   Unique  = {RemoveDuplicates Objs}          % idempotencia
   %% Los metodos se mezclan igual que los atributos: de derecha a izquierda
   %% para que en un choque gane el objeto que va primero.
   Methods = {List.foldR Unique
              fun {$ Obj Acc} {Adjoin Acc {ObjectMethods Obj}} end
              object}
in
   %% y le pegamos el record de atributos ya mezclado
   {AdjoinAt Methods attributes {ComposeAttributes Unique}}
end

%% Nombre generico que usa el enunciado en el Snippet 1.
Compose = ExplicitComposition


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAREA 3. COMPOSICION IMPLICITA
%%
%% {ImplicitComposition Objs} tambien recibe una lista, pero en vez de copiar
%% los metodos se guarda los objetos adentro del compuesto (en el campo
%% reservado 'constituents') y les delega cuando toca.
%%
%% Para cada nombre de metodo que exista en algun constituyente, el compuesto
%% expone un reenviador (ver MakeForwarder). El reenviador no guarda el metodo,
%% guarda la lista de constituyentes y en cada llamada lo resuelve con
%% {ResolveMethod ...} y le pasa los argumentos.
%%
%% La diferencia con la Tarea 2:
%%   - explicita: la busqueda pasa una sola vez, al componer. El resultado es
%%     autonomo y deja de depender de sus constituyentes.
%%   - implicita: la busqueda pasa en cada llamada (late binding). El compuesto
%%     delega en los objetos que lo forman y se queda con la referencia a ellos
%%     en 'constituents'.
%%
%% Las reglas de siempre se mantienen: los duplicados se van de la lista de
%% constituyentes, la union de nombres respeta el orden de aparicion y
%% ResolveMethod siempre escoge el primer objeto que define el metodo.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

fun {ImplicitComposition Objs}
   Unique = {RemoveDuplicates Objs}
   %% un campo por metodo disponible, con el reenviador como valor
   Fields = {Map {AllMethodFeatures Unique}
             fun {$ F} F#{MakeForwarder Unique F} end}
in
   %% El compuesto tiene la misma forma que cualquier otro objeto (etiqueta
   %% object, campo attributes y los metodos), entonces se usa igual y hasta se
   %% puede volver a componer.
   {AdjoinList object(attributes:   {ComposeAttributes Unique}
                      constituents: Unique)
    Fields}
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAREA 4. COMPOSICION EXPLICITA POLIMORFICA
%%
%% {ExplicitCompositionPoly Objs} compone como la Tarea 2, pero cuando dos
%% objetos definen el mismo metodo ya no gana el primero botando a los demas:
%% se quedan todas las implementaciones, en una lista ordenada segun el orden de
%% los objetos en Objs.
%%
%% El compuesto queda asi:
%%
%%   object(attributes: attributes(...)
%%          name:       [NameEmployer]
%%          display:    [DisplayEmployer DisplayPerson])
%%
%% Todos los metodos quedan como lista, incluso los que no chocan (ahi la lista
%% tiene un solo elemento). Lo hice a proposito: asi la forma del objeto es
%% siempre la misma y no toca preguntar si hubo choque para saber como usar un
%% campo, que es justo lo que necesita el despachador de la Tarea 5, que indexa
%% esa lista. Lo que se pierde es poder llamar el metodo directo, porque
%% {CP.name} ya es una lista y no un procedimiento: toca invocar la
%% implementacion que uno quiera con {{List.nth CP.name 1}} o dejarselo a
%% Dispatch.
%%
%% Contra la Tarea 2:
%%   - explicita (Tarea 2): choque -> gana el primero y el resto se pierde.
%%   - polimorfica (Tarea 4): choque -> quedan todas, en orden.
%%
%% Lo demas queda igual: los atributos se mezclan con la regla de siempre (con
%% {ComposeAttributes}, o sea que ante un choque queda la celda del primero y el
%% estado se sigue compartiendo), y la composicion sigue siendo idempotente
%% porque {RemoveDuplicates} deja un solo ejemplar de cada objeto, entonces
%% {ExplicitCompositionPoly [E E]} da listas de largo 1.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% La version polimorfica de {ResolveMethod}: en vez de parar en el primer
%% objeto que define F, recorre toda la lista y devuelve todas las
%% implementaciones, en orden de aparicion.
fun {AllImplementations Objs F}
   case Objs
   of nil then nil
   [] Obj|Objr then
      if {HasFeature Obj F} then Obj.F|{AllImplementations Objr F}
      else {AllImplementations Objr F}
      end
   end
end

%% Arma un campo por cada nombre de metodo que exista en algun constituyente
%% ({AllMethodFeatures} ya da esa union sin repetidos y en orden) y el valor del
%% campo es la lista de implementaciones.
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
%% Despues de la Tarea 4 los metodos del compuesto ya no son procedimientos sino
%% listas, entonces {CP.deposit 10} no se puede aplicar porque seria aplicar una
%% lista. Toca una metafuncion que escoja una implementacion y la llame:
%%
%%      {Dispatch CP deposit 10 1}     en vez de   {CP.deposit 10}
%%
%% La Tarea 5 pide que el despacho funcione "exactamente como funcionaban las
%% funciones en ExplicitComposition", osea que ante un choque use la primera
%% implementacion. Eso es {Dispatch Obj Sel Params 1}. La Tarea 6 agrega el
%% indice, asi que con este mismo Dispatch quedan cubiertas las dos: el indice 1
%% es el comportamiento de la Tarea 5.
%%
%% Sobre Params: como en Oz la aridad es fija y no hay varargs, la forma depende
%% de cuantos parametros reciba el metodo:
%%   - sin parametros: {Dispatch A display nil 1}
%%   - un parametro: {Dispatch A deposit 10 1}, tal cual, sin lista
%%   - varios: {Dispatch A sum [2 3 R] 1}, en una lista
%%   - si es una funcion, el resultado va en el ultimo argumento del metodo o se
%%     recibe con $: {Dispatch A balance $ 1}
%% Esto ultimo es porque en Oz una fun es azucar de un proc con un argumento de
%% salida extra, entonces el resultado cuenta como un parametro mas.
%%
%% Si Params no tiene la forma que el metodo espera, sale
%% metaError(badParams Aridad Params).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% Aplica el procedimiento P a Params. Se decide segun la aridad de P porque no
%% se pueden construir aplicaciones de aridad arbitraria en tiempo de ejecucion,
%% el mismo problema de MakeForwarder.
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

%% Devuelve la lista de implementaciones de un campo. Si ya es una lista (objeto
%% de la Tarea 4) la deja igual, y si es un procedimiento suelto (Tareas 1, 2 o
%% 3) lo mete en una lista de un elemento. Asi Dispatch sirve con cualquier
%% objeto del sistema.
fun {Implementations Method}
   if {IsList Method} then Method else [Method] end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TAREA 6. INDICE EN Dispatch Y NextFunction
%%
%% {Dispatch Obj Selector Params Index} llama a la implementacion numero Index
%% (contando desde 1) del metodo Selector:
%%
%%      {Dispatch A deposit 10 1}   llama la primera
%%      {Dispatch A deposit 10 2}   llama la segunda
%%
%% Si el indice se pasa del numero de implementaciones no hace nada, como pide
%% el enunciado.
%%
%% {NextFunction} se llama desde adentro de un metodo y sigue con la siguiente
%% implementacion de la lista. Para que el metodo sepa cual es la siguiente sin
%% recibir el indice, Dispatch deja la continuacion (un procedimiento sin
%% argumentos que hace {Dispatch ... Index+1}) en la celda NextThunk justo antes
%% de llamar la implementacion actual, y NextFunction solo la ejecuta.
%%
%% Tres detalles que importan:
%%   - en {NextFunction} no se vuelven a pasar los parametros, la continuacion
%%     ya los tiene, asi que la siguiente implementacion recibe los mismos de la
%%     actual.
%%   - si hay despachos anidados, Dispatch se guarda el valor anterior de
%%     NextThunk y lo restaura al final, para que un metodo que despacha a otro
%%     objeto no pise la continuacion del despacho de afuera.
%%   - el try ... finally restaura NextThunk incluso si el metodo lanza una
%%     excepcion, para no dejar una continuacion vieja en la celda.
%%
%% Llamar {NextFunction} por fuera de un Dispatch, o en la ultima
%% implementacion, no hace nada.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

declare

%% La continuacion vigente, lo que va a ejecutar {NextFunction}. Al principio no
%% hace nada.
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
