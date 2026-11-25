% Ignacio Chaparro - 202220577

:- dynamic guess/3.

color(red).
color(green).
color(blue).
color(yellow).
color(orange).
color(purple).

valid_code(Code) :-
    length(Code, 4),
    maplist(color, Code).

count(X, List, N) :-
    include(==(X), List, Found),
    length(Found, N).

black([], [], 0).
black([X|Xs], [X|Ys], B) :-
    black(Xs, Ys, B1),
    B is B1 + 1.
black([X|Xs], [Y|Ys], B) :-
    X \= Y,
    black(Xs, Ys, B).

feedback(Secret, Guess, Black, White) :-
    black(Secret, Guess, Black),
    findall(Min,
            ( color(C),
              count(C, Secret, N1),
              count(C, Guess, N2),
              Min is min(N1, N2) ),
            Mins),
    sum_list(Mins, Total),
    White is Total - Black.

consistent(Guess) :-
    forall(guess(Previous, B, W), feedback(Previous, Guess, B, W)).

suggest(Guess) :-
    valid_code(Guess),
    consistent(Guess).

random_code(Code) :-
    findall(C, color(C), Colors),
    findall(C, (between(1, 4, _), random_member(C, Colors)), Code).

play :-
    random_code(Secret),
    play(Secret).

play(Secret) :-
    retractall(guess(_, _, _)),
    write('Colors: red, green, blue, yellow, orange, purple'), nl,
    write('Write your guess as a list, e.g. [red,blue,green,yellow].'), nl,
    turn(1, Secret).

turn(Try, Secret) :-
    Try > 12,
    write('You lost. The secret code was: '), write(Secret), nl.
turn(Try, Secret) :-
    Try =< 12,
    write('Try '), write(Try), write(': '),
    read(Guess),
    (   is_list(Guess), valid_code(Guess)
    ->  answer(Try, Secret, Guess)
    ;   write('Invalid guess, use 4 valid colors.'), nl,
        turn(Try, Secret)
    ).

answer(Try, Secret, Guess) :-
    feedback(Secret, Guess, Black, White),
    write('Black: '), write(Black), write('  White: '), write(White), nl,
    (   consistent(Guess)
    ->  write('Your guess is consistent with previous answers.')
    ;   write('Your guess is not consistent with previous answers.')
    ),
    nl,
    assertz(guess(Guess, Black, White)),
    (   Black == 4
    ->  write('You won in '), write(Try), write(' tries!'), nl
    ;   Next is Try + 1,
        turn(Next, Secret)
    ).
