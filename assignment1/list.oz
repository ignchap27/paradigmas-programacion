%% OddSumEvenProduct
%% Input: A list of integers
%% Output: A tuple where
%% - the first element is the product of elements at even positions ,
%% - the second element is the sum of elements at odd positions.
declare
fun {OddSumEvenProduct L}
    Loop
in
    fun {Loop Xs Pos Prod Sum}
        if Xs == nil then Prod # Sum
        elseif Pos mod 2 == 0 then 
            {Loop Xs.2 Pos+1 Prod*Xs.1 Sum}
        else
            {Loop Xs.2 Pos+1 Prod Sum+Xs.1}
        end
    end
    {Loop L 1 1 0}
end

%%{Show {OddSumEvenProduct [10 43 50 60]}}