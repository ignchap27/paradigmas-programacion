% Ignacio Chaparro - 202220577

sometimes(Query) :-
    \+ \+ call(Query).

always(Query) :-
    \+ \+ ( copy_term(Query, Copy),
            call(Copy),
            Copy =@= Query ).
