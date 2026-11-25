% Ignacio Chaparro - 202220577

:- dynamic interval/3.

new_interval(Id, L, R) :-
    L < R,
    retractall(interval(Id, _, _)),
    assertz(interval(Id, L, R)).

left(Id, L) :-
    interval(Id, L, _).

right(Id, R) :-
    interval(Id, _, R).

in(Id, X) :-
    number(X),
    interval(Id, L, R),
    L < X,
    X < R.

in(Id, Other, Relation) :-
    interval(Id, L, R),
    interval(Other, L2, R2),
    relation(L, R, L2, R2, Relation).

relation(L, R, L2, R2, contained) :-
    L =< L2, R2 =< R.
relation(L, R, L2, R2, contains) :-
    L2 =< L, R =< R2.
relation(L, R, L2, R2, left_contained) :-
    L < L2, L2 < R, R < R2.
relation(L, R, L2, R2, right_contained) :-
    L2 < L, L < R2, R2 < R.
relation(L, R, L2, R2, disjoint) :-
    ( R2 =< L ; R =< L2 ).

update(Id, L, R) :-
    L < R,
    retract(interval(Id, _, _)),
    assertz(interval(Id, L, R)).
