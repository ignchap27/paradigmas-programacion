%% AddPolynomials
%% Input: Two lists of integers representing polynomials
%% Output: A list of integers representing the sum of the polynomials
%% Examples 
%% {AddPolynomials [1 ~2] [4 3 2 1]} = [4 3 3 ~1]
%% {AddPolynomials [3 0 0 4 1 ~5] [0 2 ~1 1 4 10]} = [3 2 ~1 5 5 5]

declare AddPolynomials MinMaxList List1 List2

fun {AddPolynomials P1 P2}
    Diff Completion MinMaxTuple CompleteTuple Sum
in
    MinMaxTuple = {MinMaxList P1 P2}
    Diff = {Length MinMaxTuple.1} - {Length MinMaxTuple.2}

    fun {Completion L1 L2 Diff}
        if Diff == 0 then L1 # L2
        else {Completion L1 0|L2 Diff-1}
        end
    end

    fun {Sum L1 L2 Res}
        NewRes
    in
        if L1 == nil then Res 
        else
            NewRes = {Append Res [L1.1 + L2.1]}
            %% {Show NewRes}
            {Sum L1.2 L2.2 NewRes}
        end
    end

    CompleteTuple = {Completion MinMaxTuple.1 MinMaxTuple.2 Diff}
    {Sum CompleteTuple.1 CompleteTuple.2 nil}
end

fun {MinMaxList L1 L2}
    if {Length L1} >= {Length L2} then L1 # L2
    else L2 # L1 
    end
end

List1 = [2 3]
List2 = [1 2 3 4 5]

{Show {AddPolynomials List1 List2}}
%testfailed(1:'Second longer' actual:[1 2 3 6 8] expected:[1 2 5 7 5])