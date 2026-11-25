:- consult([matrix, mastermind, interval, always]).

parent(abe, homer).
parent(homer, bart).
parent(homer, lisa).

grandparent(X, Z) :-
    parent(X, Y),
    parent(Y, Z).

likes(mary, _).
likes(john, pizza).

test(Name, Goal) :-
    ( catch(Goal, _, fail) ->
        write(passed(Name))
    ;   write(failed(Name))
    ),
    nl.

test_matrix :-
    M = [[1, 2, 3], [4, 5, 6], [7, 8, 9]],
    test(sum_matrix, sum_matrix(M, 45)),
    test(sum_row, sum_row(M, 2, 15)),
    test(sum_column, sum_column(M, 3, 18)),
    test(mult_matrix, mult_matrix(M, 362880)),
    test(mult_row, mult_row(M, 1, 6)),
    test(mult_column, mult_column(M, 2, 80)),
    test(sum_matrix_1x1, sum_matrix([[5]], 5)),
    test(mult_with_zero, mult_matrix([[1, 0], [3, 4]], 0)),
    test(row_out_of_range, \+ sum_row(M, 4, _)),
    test(find_row, findall(R, sum_row(M, R, 15), [2])).

test_mastermind :-
    S = [red, blue, green, yellow],
    test(feedback_win, feedback(S, S, 4, 0)),
    test(feedback_none, feedback(S, [orange, orange, purple, purple], 0, 0)),
    test(feedback_all_white, feedback(S, [blue, red, yellow, green], 0, 4)),
    test(feedback_mixed, feedback(S, [red, green, blue, orange], 1, 2)),
    test(feedback_repeated, feedback(S, [red, red, red, red], 1, 0)),
    test(valid_code, valid_code([red, red, blue, purple])),
    test(invalid_color, \+ valid_code([red, red, blue, black])),
    test(invalid_length, \+ valid_code([red, blue])),
    retractall(guess(_, _, _)),
    feedback(S, [red, red, red, red], B, W),
    assertz(guess([red, red, red, red], B, W)),
    test(consistent_yes, consistent([red, green, green, green])),
    test(consistent_no, \+ consistent([blue, blue, blue, blue])),
    test(consistent_secret, consistent(S)),
    test(suggest, (suggest(G), consistent(G))),
    test(generate_codes, (findall(C, valid_code(C), All), length(All, 1296))),
    retractall(guess(_, _, _)),
    test(random_code, (random_code(C), valid_code(C))).

test_interval :-
    new_interval(a, 1.0, 10.0),
    test(left, left(a, 1.0)),
    test(right, right(a, 10.0)),
    test(in_point, in(a, 5.5)),
    test(in_left_border, \+ in(a, 1.0)),
    test(in_right_border, \+ in(a, 10.0)),
    test(in_outside, \+ in(a, 11.0)),
    new_interval(b, 2.0, 5.0),
    new_interval(c, 0.0, 20.0),
    new_interval(d, 8.0, 15.0),
    new_interval(e, -5.0, 3.0),
    new_interval(f, 12.0, 14.0),
    test(contained, in(a, b, contained)),
    test(contains, in(a, c, contains)),
    test(left_contained, in(a, d, left_contained)),
    test(right_contained, in(a, e, right_contained)),
    test(disjoint, in(a, f, disjoint)),
    test(only_one_relation, findall(Rel, in(a, b, Rel), [contained])),
    test(contained_not_disjoint, \+ in(a, b, disjoint)),
    test(find_contained, findall(I, in(a, I, contained), [a, b])),
    test(update, (update(a, 3.0, 4.0), left(a, 3.0), right(a, 4.0))),
    test(update_changes_in, \+ in(a, 5.5)),
    test(update_bad, \+ update(a, 9.0, 2.0)),
    test(new_interval_bad, \+ new_interval(z, 5.0, 1.0)).

test_always :-
    test(sometimes_grandparent, sometimes(grandparent(abe, _))),
    test(sometimes_append_false, \+ sometimes(append([a], [b], [c]))),
    test(sometimes_append_true, sometimes(append([a], [b], [a, b]))),
    test(sometimes_no_binding, (sometimes(grandparent(abe, X)), var(X))),
    test(always_likes_mary, always(likes(mary, _))),
    test(always_likes_john, \+ always(likes(john, _))),
    test(always_grandparent, \+ always(grandparent(abe, _))),
    test(always_ground_true, always(append([a], [b], [a, b]))),
    test(always_ground_false, \+ always(append([a], [b], [c]))),
    test(always_append, \+ always(append([], _, _))),
    test(always_append_same, always(append([], L, L))).

main :-
    test_matrix,
    test_mastermind,
    test_interval,
    test_always,
    halt.

:- initialization(main).
