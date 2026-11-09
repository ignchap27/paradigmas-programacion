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

## Estado (29/29 tests pasan)
- **Task 1 — GraphGeneration: HECHA.** Tokenize, parser con precedencia (`ParseExpr/Term/Factor`), `var y = ... in` con entorno que comparte el mismo nodo, aplicaciones según aridad (`ParseApplication/ParseArgs`). Alias `GenerateGraph`.
- **Task 2 — NextReduction: HECHA.** `Unwind` baja por la espina izquierda; `Redex` sube `Arity` nodos. Primitivas con args no numéricos buscan redex dentro de los args (`FirstRedex`). Soporta CAF, sobre-aplicación e `ind`.
- **Task 3 — Reduce: FALTA.**
- **Task 4 — Evaluate: FALTA.**

## Pendiente
Agregar a `declare`: `Value Apply Instantiate Reduce Evaluate`.

### Task 3 — `fun {Reduce Program}` (muta el grafo, retorna Program)
1. `R = {NextReduction Program}`; si `none`, retorna Program igual.
2. Primitiva: `Value` (sigue `ind` hasta `leaf(N)`) de los 2 args, aplica op (`/` → `div`), `R.root := leaf(Res)`.
3. Supercombinador: `Instantiate` copia el body:
   - `leaf(param)` → nodo argumento (compartido).
   - otro `leaf(V)` → `{Leaf V}` nuevo (nunca mutar el body original).
   - `app(L R)` → `{App ...}` nuevo, con memo `Viejo#Nuevo` (identidad de celda) para conservar sharing de `var`.
   - `R.root := ind(Nuevo)`.

### Task 4 — `fun {Evaluate Program}`
Si `{NextReduction Program} == none` → `{GraphToRecord Program.graph}` (número, o expresión `'@'(...)` si hay variables libres). Si no → `{Evaluate {Reduce Program}}`.

### Tests a agregar (`TestTask3`, `TestTask4`)
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
