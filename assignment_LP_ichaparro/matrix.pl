% Ignacio Chaparro - 202220577

product_list([], 1).
product_list([X|Xs], P) :-
    product_list(Xs, P1),
    P is X * P1.

column(M, C, Col) :-
    maplist(nth1(C), M, Col).

sum_matrix(M, S) :-
    append(M, All),
    sum_list(All, S).

sum_row(M, R, S) :-
    nth1(R, M, Row),
    sum_list(Row, S).

sum_column(M, C, S) :-
    column(M, C, Col),
    sum_list(Col, S).

mult_matrix(M, P) :-
    append(M, All),
    product_list(All, P).

mult_row(M, R, P) :-
    nth1(R, M, Row),
    product_list(Row, P).

mult_column(M, C, P) :-
    column(M, C, Col),
    product_list(Col, P).
