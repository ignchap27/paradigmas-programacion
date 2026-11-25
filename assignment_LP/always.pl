sometimes(Query) :-
    \+ \+ call(Query).

always(Query) :-
    \+ \+ ( copy_term(Query, Copy),
            call(Copy),
            Copy =@= Query ).
