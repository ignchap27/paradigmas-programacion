# Proyecto 2 (FP) — Guía

## Objetivo
Mini lenguaje funcional en Mozart con *template instantiation* (reducción de grafos). Enunciado: `p_fp_project.pdf`. Toda la solución va en `mozart-fp.oz`. Los programas se evalúan como `{Evaluate {GenerateGraph P}}`.

## Archivos de la carpeta
- `p_fp_project.pdf` — enunciado, 4 tasks (GraphGeneration, NextReduction, Reduce, Evaluate).
- `examples_fp.pdf` — grafos esperados (square, sqr, twice, fourtimes con nodo `y` compartido).
- `implementing functional languages.pdf` — tutorial Peyton Jones, cap. 2 (template instantiation).
- `9. recursion`, `11. continuations`, `12. lazy` — slides de clase.
- `infix2prefix.oz` — helper del profesor (infijo→prefijo). No se usa; el parser propio lo reemplaza.
- `mozart-fp.oz` — solución.
- `test_fp.oz` — tests (patrón `TestResult`).

## Representación
- Nodo = `Cell` con `leaf(V)`, `app(L R)` o `ind(N)` (indirección).
- Programa = `program(funs: funs(nombre: def(params:[...] body:Nodo)) graph: Nodo)`.
- Redex = `redex(name: N args: [Nodos] root: Nodo)` o `none`.

## Estado (57/57 tests pasan)
- **Task 1 — GraphGeneration: HECHA.** `Tokenize` separa por cualquier espacio (tabs, `\r`). Primero se arma `Arity` (nombre → nº de params, `CountParams`) desde las líneas `fun`; después un **único parser** (`ParseExpr/Term/Factor` + `ParseArgs`) sirve para cuerpos y para la línea de llamada. `ParseFactor`: `( expr )` (exige `)`), número, nombre del entorno (`var`/param, comparte el mismo nodo), función conocida → consume `Arity` argumentos (cada uno un factor), si no → variable libre. Así funcionan llamadas dentro de cuerpos (`twice x + 1`), operadores en la llamada (`twice (2 + 3)`, `twice 3 + 1`) y `sum_n 1 sum_n 1 1 1 2 3 2`. `var y x+x` (sin `=`) también. Alias `GenerateGraph`.
- **Task 2 — NextReduction: HECHA.** `Unwind` baja por la espina izquierda; `Redex` sube `Arity` nodos. Primitivas con args no numéricos buscan redex dentro de los args (`FirstRedex`). Soporta CAF, sobre-aplicación e `ind`.
- **Task 3 — Reduce: HECHA.** `Value` sigue `ind` hasta el número; `Apply` aplica la primitiva (`/` → `div`) y la raíz pasa a `leaf(Res)`. Supercombinador: `Instantiate` copia el body (params → nodos argumento vía `Lookup`, memo `Viejo#Nuevo` conserva sharing de `var`) y la raíz pasa a `ind(Nuevo)`. Raíz se muta con `{Assign R.root ...}`.
- **Task 4 — Evaluate: HECHA.** Si `NextReduction` da `none` devuelve `{GraphToRecord Program.graph}` (número o expresión `'@'(...)` con variables libres); si no, `{Evaluate {Reduce Program}}`.
- Tests: `TestTask1..4`, `TestTutorial` y `TestParser` (regresiones del parser unificado).

## Decisiones
- `NextReduction/Reduce/Evaluate` reciben `program(funs graph)`, no sólo el grafo: sin las definiciones no se puede reducir.
- División por cero: se deja la excepción de Oz (el enunciado no define nada).
- Si hay varias líneas de llamada, se evalúa la última.

## Pendiente
Nada.

## Cómo correr los tests
```sh
export PATH="/Applications/Mozart2.app/Contents/Resources/bin:$PATH"
cd "proyecto 2"
printf "declare Show = System.show\n\\\\insert '<ruta absoluta>/proyecto 2/test_fp.oz'\n" | ozc -l System=x-oz://system/System.ozf -e /dev/stdin
```
Esperado: todo `testpassed(...)`.
