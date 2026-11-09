# Proyecto 2 FP

Toda la solución está en `mozart-fp.oz` y los tests en `test_fp.oz`. Un programa se evalúa con `{Evaluate {GenerateGraph P}}`. Seguimos el modelo de template instantiation del capítulo 2 de Peyton Jones, con un heap de direcciones, instanciación del cuerpo y nodos de indirección.

## Representación

No usamos celdas, todo es declarativo. El parser produce un árbol donde una aplicación es `'@'(F A)` y un `var` es `let(Nombre Def Cuerpo)`. El heap es un record `heap(1:Nodo 2:Nodo ...)` con nodos `leaf(V)`, `app(L R)` o `ind(Dir)`. `Alloc` agrega un nodo y devuelve la dirección junto con el heap nuevo, y para actualizar usamos `AdjoinAt`, así que el heap anterior nunca cambia.

El programa es un record `program` con las definiciones en `funs`, el heap, la lista `calls` con la raíz de cada línea de llamada y `graph` con la raíz que se está reduciendo. `NextReduction`, `Reduce` y `Evaluate` reciben este record completo porque sin las definiciones y el heap no se puede reducir.

## GraphGeneration

`CleanLine` quita comentarios y espacios y `Tokenize` separa los tokens. Primero leemos las cabeceras con `Header` para saber cuántos parámetros tiene cada función, y con eso el parser recursivo (`ParseExpr`, `ParseTerm`, `ParseFactor`, `ParseArgs`) sabe cuántos argumentos tomar en cada llamada. Cada función del parser devuelve el árbol y los tokens que sobran. También aceptamos floats y el menos unario. Cada línea de llamada se pasa al heap con `Instantiate`.

## NextReduction

`Unwind` baja por la espina guardando los nodos en una pila y `Redex` toma tantos argumentos como pida la función. Si una primitiva tiene argumentos que todavía no son números, `FindRedex` busca dentro del primero y le pasa una continuación que busca en el segundo si en el primero no encontró nada.

## Reduce

Si el redex es una primitiva la raíz se reemplaza por `leaf` con el resultado. La división da entero cuando es exacta y float cuando no. Si es un supercombinador, `Instantiate` construye el cuerpo usando las direcciones de los argumentos y la raíz pasa a ser `ind` del cuerpo. En un `let` la variable apunta siempre a la misma dirección, así que el valor se comparte y se calcula una sola vez.

## Evaluate

`Trace` es una lista perezosa con todos los estados del programa y `Result` toma el último. `Evaluate` hace esto para cada línea de llamada y devuelve un valor si hay una sola línea o una lista si hay varias. `Steps` sirve para ver cada paso de la reducción. Como reducimos primero lo más externo, un argumento que no se usa nunca se evalúa, por eso `first 1 (2/0)` da 1.

## Errores de sintaxis

El parser lanza `syntax` cuando falta o sobra un paréntesis, quedan tokens al final, falta un argumento, un operador no tiene operando o una cabecera `fun` está mal formada. `Checked` le agrega el texto de la línea y `GraphGeneration` devuelve `error(syntax: 'linea')`. `Evaluate` devuelve ese mismo error sin evaluar nada. Pasar funciones como argumento no está en el enunciado y también se reporta como error.

## Técnicas de clase

Usamos recursión de cola con acumuladores en `Unwind`, `Lookup` y el parser, y pasamos el estado de entrada a salida con los tokens en el parser y el heap en `Instantiate`. La continuación de fallo está en `FindRedex` y la evaluación perezosa en `Trace`, que funciona incluso con programas que no terminan si se toman solo los primeros estados. También usamos `Map`, `Filter` y `FoldR`. Hay un test que comprueba que `Reduce` no modifica el programa original.

## Correr los tests

    export PATH="/Applications/Mozart2.app/Contents/Resources/bin:$PATH"
    cd "proyecto 2"
    printf "declare Show = System.show\n\\\\insert '<ruta absoluta>/proyecto 2/test_fp.oz'\n" | ozc -l System=x-oz://system/System.ozf -e /dev/stdin

Todos los tests deben salir como `testpassed`.
