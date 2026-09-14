# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working style (highest priority)

When you finished a task, deactivate caveman mode and give the user a detailed explanation of your work so he can understand. When writing code, write the most simplest code possible, so a human could understand it. Dont write any comment on the code.

## Toolchain

Mozart 2 is installed as an app bundle, not on `PATH`:

```sh
export PATH="/Applications/Mozart2.app/Contents/Resources/bin:$PATH"
oz                     # interactive Emacs-based OPI
ozengine file.ozf      # run a compiled functor
ozc -c file.oz         # compile to .ozf
ozc -x file.oz         # compile to standalone executable
```

To syntax-check or run a plain script (non-functor, `declare`-style files like every file here), the usual route is compiling it, since these files are top-level statements rather than functors. Piping the file into the OPI or wrapping it in a `functor $ import System define ... end` is the workaround when a quick check is needed.

## Repository layout

Each assignment is a top-level directory containing the assignment PDF plus one `.oz` file per task. There is no build system, no package manager, no test framework — files are plain Oz source that gets `\insert`ed together.

- `assignment1_IgnacioChaparro/` — declarative/functional Oz: `list.oz`, `poly.oz`, `tree.oz`, `integral.oz`, `recordR.oz`, plus `test_local.oz` and `test_completo.oz`.
- `assignment_oop/` — object-oriented Oz (current work): `matrix.oz`, `mastermind.oz`, `exp.oz`, `language.oz`.
- `prueba.oz` — scratch file for language experiments; not part of any assignment.

## How the code is organized

**Stub-driven assignments.** The professor ships skeleton files: `class` / `meth` headers with full doc comments (Input/Output/Precondition/Side effects) and a `skip` body marked `%% Your code here`. The doc comments are the spec — signatures, argument order, and sentinel values (e.g. matrix methods return `142857` on out-of-range indices) must not be changed. Implementation replaces `skip` only.

**Declarations.** Every file starts with a single `declare` naming all classes/functions it defines (`declare Matrix`, `declare MastermindGame CodeBreaker CodeMaker`), so files can be `\insert`ed into a driver without redeclaration conflicts. Output parameters follow the Oz convention of a trailing `?Result` bound by the method rather than a return value.

**Object model (`assignment_oop`).**
- `matrix.oz` — one self-contained `Matrix` class, `attr data size`, 1-indexed accessors over a list-of-lists.
- `mastermind.oz` — three collaborating classes: `MastermindGame` owns the round loop and holds a `CodeMaker` and a `CodeBreaker` injected at `init`; `CodeMaker` owns the secret code and computes black/white clue feedback; `CodeBreaker` owns guess and feedback history. Feedback crosses the boundary as a record `feedback(blackClues: ... whiteClues: ... totalCorrect: ... isCorrect: ... ClueList: ...)`.
- `exp.oz` — inheritance demo: abstract `Expression` with `print`/`eval(R)`, subclasses `Num` and `Sum` (`from Expression`) overriding both. This is the template for the interpreter-style task.

## Testing

Tests are hand-rolled, no framework. The pattern from `assignment1_IgnacioChaparro/test_completo.oz`:

```oz
\insert 'assignment1_IgnacioChaparro/list.oz'   % paths are relative to the repo root
...
proc {TestResult TestName Expected Actual}      % compares, {Show testpassed(...)} / testfailed(...)
proc {TestResultFloat ...}                      % float comparison within 0.0001
proc {TestTask1} ... end                        % one proc per task, called at the bottom
```

Run the whole suite by compiling and running the driver file; run a single task by calling only that `{TestTaskN}` at the bottom of the driver. `test_local.oz` is the lighter variant of the same idea.
