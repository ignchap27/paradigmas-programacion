# Proyecto 2 (FP) — Guía

## Objetivo
Mini lenguaje funcional en Mozart con *template instantiation* (reducción de grafos). Enunciado: `p_fp_project.pdf`. Toda la solución va en `mozart-fp.oz`. Los programas se evalúan como `{Evaluate {GenerateGraph P}}`.

## Archivos de la carpeta
- `p_fp_project.pdf` — enunciado, 4 tasks (GraphGeneration, NextReduction, Reduce, Evaluate).
- `examples_fp.pdf` — grafos esperados (square, sqr, twice, fourtimes con nodo `y` compartido).
- `implementing functional languages.pdf` — tutorial Peyton Jones, cap. 2 (template instantiation). La solución sigue su modelo: heap de direcciones, `instantiate body heap env`, `hUpdate` con `NInd`, `eval state = state : rest_states`.
- `9. recursion`, `11. continuations`, `12. lazy` — slides de clase (técnicas usadas, ver abajo).
- `infix2prefix.oz` — helper del profesor (infijo→prefijo). No se usa; el parser propio lo reemplaza.
- `mozart-fp.oz` — solución.
- `test_fp.oz` — tests (patrón `TestResult` / `TestFloat`).

## Representación (100% declarativa, sin `Cell`)
- **Expresión (AST)** que produce el parser: número, átomo, `'@'(F A)` (aplicación) o `let(Nombre Def Cuerpo)` (para `var`).
- **Heap** inmutable: record `heap(1: Nodo 2: Nodo ...)`. Nodo = `leaf(V)`, `app(DirL DirR)` o `ind(Dir)`. `Alloc` devuelve `Dir#HeapNuevo`; actualizar = `{AdjoinAt Heap Dir Nodo}` (heap nuevo, el viejo no cambia).
- **Programa** = `program(funs: funs(nombre: def(params:[...] body: AST)) heap: Heap calls: [Dir ...] graph: Dir)`. `calls` son las raíces de todas las líneas de llamada; `graph` es la raíz que se está reduciendo.
- **Redex** = `redex(name: N args: [Dir ...] root: Dir)` o `none`.

## Estado (98/98 tests pasan)
- **Task 1 — GraphGeneration: HECHA.** `CleanLine` quita comentarios `%` y espacios de los bordes; `Tokenize` separa por espacios. `Header` valida y lee la cabecera `fun nombre params =`. Primero `Arities` (nombre → nº params), después un único parser recursivo (`ParseExpr/Term/Factor` + `ParseArgs`) que devuelve `AST#TokensRestantes`. `var y = e in b` → `let(y e b)` (también sin `=`). Menos unario: `-3` → `~3`, `-x` → `0 - x`. Literales float (`2.5`). Cada línea de llamada se convierte a grafo con `Instantiate` (un `FoldR` va pasando el heap).
- **Task 2 — NextReduction: HECHA.** `Unwind` baja por la espina con pila acumulador; `Redex` sube `ArgCount` nodos. `FindRedex` usa **continuación de fallo** (`Otherwise`): si una primitiva tiene args no numéricos busca en el 1º arg y, si no hay nada, la continuación busca en el 2º.
- **Task 3 — Reduce: HECHA.** Primitiva: raíz → `leaf(Res)`. `/` da entero si es exacta (`10/2 = 5`) y float si no (`5/2 = 2.5`); int con float → float. Supercombinador: `Instantiate` construye el cuerpo en el heap (params → direcciones de los args, `let` → misma dirección = sharing) y la raíz → `ind(Cuerpo)`. Devuelve un programa nuevo.
- **Task 4 — Evaluate: HECHA.** `Trace` es una lista **perezosa** (`fun lazy`) de estados; `Result` toma el último. `Evaluate` evalúa **todas** las líneas de llamada: una → el valor; varias → lista de valores; ninguna → `nil`. `Steps` muestra cada paso de reducción.

## Errores de sintaxis
- El parser lanza `raise syntax end` cuando: falta `)`, sobra `)` o cualquier token al final (`ParseAll` exige leer la línea completa), falta un argumento (`f 1` si `f` tiene 2 params), hay un operador sin operando (`5 +`, `5 * * 2`), aparece una palabra clave fuera de lugar (`in 5`), o un `fun` no tiene nombre, `=`, cuerpo, o tiene params que no son identificadores.
- `Checked` atrapa `syntax` y lo relanza como `syntaxError(Linea)`; `GraphGeneration` lo atrapa y devuelve `error(syntax: 'linea')`. `Evaluate` devuelve ese mismo error sin evaluar.
- Pasar funciones como argumento (`fun app f x = f x`) no está en el enunciado: se reporta como error de sintaxis.

## Técnicas de clase usadas
- Recursión de cola con acumuladores: `Unwind` (pila), `ParseArgs`, `ParseTermRest`, `ParseExprRest`, `Lookup`.
- Múltiples acumuladores (estado entrada/salida): tokens `T0 → T` en el parser, heap `H0 → H1 → H2` en `Instantiate`.
- Continuaciones: `FindRedex ... Otherwise`.
- Evaluación perezosa: `fun lazy {Trace}` (sirve hasta para programas infinitos, `{List.take {Trace P} 3}`), y la reducción más externa no evalúa args que no se usan (`first 1 (2/0)` = 1).
- Orden superior: `Map`, `Filter`, `FoldR`, `All`, `List.zip`, `List.takeWhile`.
- Inmutabilidad: `Reduce` no modifica el programa original (test `immutable_still`).

## Decisiones
- `NextReduction/Reduce/Evaluate` reciben `program(...)`, no sólo el grafo: sin las definiciones y el heap no se puede reducir.
- División por cero: `1 / 0` da `inf` (float de Oz).

## Pendiente
Nada.

## Cómo correr los tests
```sh
export PATH="/Applications/Mozart2.app/Contents/Resources/bin:$PATH"
cd "proyecto 2"
printf "declare Show = System.show\n\\\\insert '<ruta absoluta>/proyecto 2/test_fp.oz'\n" | ozc -l System=x-oz://system/System.ozf -e /dev/stdin
```
Esperado: todo `testpassed(...)`.
