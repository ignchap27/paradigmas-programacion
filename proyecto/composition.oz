%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ISIS-4217 Paradigmas de programacion
%% Proyecto: Orientacion a objetos - objetos componibles con "metafunciones"
%% Archivo: composition.oz
%% Tareas implementadas en este archivo: 1, 2 y 3
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
