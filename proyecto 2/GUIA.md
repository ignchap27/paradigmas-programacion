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

## Estado (48/48 tests pasan)
- **Task 1 — GraphGeneration: HECHA.** Tokenize, parser con precedencia (`ParseExpr/Term/Factor`), `var y = ... in` con entorno que comparte el mismo nodo, aplicaciones según aridad (`ParseApplication/ParseArgs`). Alias `GenerateGraph`.
- **Task 2 — NextReduction: HECHA.** `Unwind` baja por la espina izquierda; `Redex` sube `Arity` nodos. Primitivas con args no numéricos buscan redex dentro de los args (`FirstRedex`). Soporta CAF, sobre-aplicación e `ind`.
- **Task 3 — Reduce: HECHA.** `Value` sigue `ind` hasta el número; `Apply` aplica la primitiva (`/` → `div`) y la raíz pasa a `leaf(Res)`. Supercombinador: `Instantiate` copia el body (params → nodos argumento vía `Lookup`, memo `Viejo#Nuevo` conserva sharing de `var`) y la raíz pasa a `ind(Nuevo)`. Raíz se muta con `{Assign R.root ...}` (`R.root := X` en Oz es asignación de diccionario, falla). Tests en `TestTask3`.
- **Task 4 — Evaluate: HECHA.** Si `NextReduction` da `none` devuelve `{GraphToRecord Program.graph}` (número o expresión con variables libres); si no, `{Evaluate {Reduce Program}}`. Tests en `TestTask4`.

## Pendiente
Nada. Proyecto completo.

### Task 4 — `fun {Evaluate Program}`
Si `{NextReduction Program} == none` → `{GraphToRecord Program.graph}` (número, o expresión `'@'(...)` si hay variables libres). Si no → `{Evaluate {Reduce Program}}`.

### Tests a agregar (`TestTask4`)
| Programa | Resultado |
|---|---|
| `square square 3` | 81 |
| `fourtimes 2` | 8 |
| `twice 5` | 10 |
| `sqr 4` | 15 |
| `sum_n 1 sum_n 1 1 1 2 3 2` | 20 |
| `arithmetic arithmetic 5 6 arithmetic 2 11` | 2 (`div`) |
| `var_use var_use 16` | 241 |
| `five` (CAF) | 5 |
| `x + x` sin valor | `'@'('@'('+' x) x)` |

Reduce un paso: `twice 5` → raíz `+ 5 5`; `2+3` → `5`.

## Cómo correr los tests
```sh
export PATH="/Applications/Mozart2.app/Contents/Resources/bin:$PATH"
cd "proyecto 2"
printf "declare Show = System.show\n\\\\insert '<ruta absoluta>/proyecto 2/test_fp.oz'\n" | ozc -l System=x-oz://system/System.ozf -e /dev/stdin
```
Esperado: todo `testpassed(...)`.
