%% Matrix Definition
declare

   fun {IsValid Matrix I}
      I >= 1 andthen I =< {Length Matrix}
   end

   fun {Sum L}
      case L
      of nil then 0
      [] H|T then H + {Sum T}
      end
   end

   fun {Product L}
      case L
      of nil then 1
      [] H|T then H * {Product T}
      end
   end

   fun {GetSize Matrix }
      %% Returns the size N of the N×N matrix given as parameter
      %% Input: None
      %% Output: Result :: Int - The dimension N of the N×N matrix
      %% Your code here
      {Length Matrix}
   end

   fun {GetElement Matrix Row Col }
      %% Returns element at position  Matrix Row, Col) using 1-indexed coordinates
      %% Input: Row :: Int - Row index  Matrix 1 ≤ Row ≤ N)
      %%        Col :: Int - Column index  Matrix 1 ≤ Col ≤ N)
      %% Output: Result :: Int - Element at position  Matrix Row, Col)
      %% Note: If Row and Col are not valide within the matrix size return 142857
      %% Your code here
      if {IsValid Matrix Row} andthen {IsValid Matrix Col} then
         {Nth {Nth Matrix Row} Col}
      else
         142857
      end
   end

   fun {GetRow Matrix RowIndex }
      %% Returns the complete row as a list
      %% Input: RowIndex :: Int - Row number  Matrix 1 ≤ RowIndex ≤ N)
      %% Output: Result :: [Int] - List containing all elements of the specified row
      %% Note: If RowIndex is not valide within the matrix size return 142857
      %% Your code here
      if {IsValid Matrix RowIndex} then
         {Nth Matrix RowIndex}
      else
         142857
      end
   end

   fun {GetColumn Matrix ColIndex }
      %% Returns the complete column as a list
      %% Input: ColIndex :: Int - Column number  Matrix 1 ≤ ColIndex ≤ N)
      %% Output: Result :: [Int] - List containing all elements of the specified column
      %% Note: If ColIndex is not valide within the matrix size return 142857
      %% Your code here
      if {IsValid Matrix ColIndex} then
         {Map Matrix fun {$ Row} {Nth Row ColIndex} end}
      else
         142857
      end
   end

   fun {SumRow Matrix RowIndex }
      %% Returns sum of all elements in specified row
      %% Input: RowIndex :: Int - Row number  Matrix 1 ≤ RowIndex ≤ N)
      %% Output: Result :: Int - Arithmetic sum of all elements in the row
      %% Precondition: RowIndex is valid within the Matrix size
      %% Note: If RowIndex is not valide within the matrix size return 142857
      %% Your code here
      if {IsValid Matrix RowIndex} then
         {Sum {GetRow Matrix RowIndex}}
      else
         142857
      end
   end

   fun {ProductRow Matrix RowIndex }
      %% Returns product of all elements in specified row
      %% Input: RowIndex :: Int - Row number  ( 1 ≤ RowIndex ≤ N)
      %% Output: Result :: Int - Arithmetic product of all elements in the row
      %% Note: If RowIndex is not valide within the matrix size return 142857
      %% Your code here
      if {IsValid Matrix RowIndex} then
         {Product {GetRow Matrix RowIndex}}
      else
         142857
      end
   end

   fun {SumColumn Matrix ColIndex }
      %% Returns sum of all elements in specified column
      %% Input: ColIndex :: Int - Column number  Matrix 1 ≤ ColIndex ≤ N)
      %% Output: Result :: Int - Arithmetic sum of all elements in the column
      %% Note: If ColIndex is not valide within the matrix size return 142857
      %% Your code here
      if {IsValid Matrix ColIndex} then
         {Sum {GetColumn Matrix ColIndex}}
      else
         142857
      end
   end

   fun {ProductColumn Matrix ColIndex }
      %% Returns product of all elements in specified column
      %% Input: ColIndex :: Int - Column number  Matrix 1 ≤ ColIndex ≤ N)
      %% Output: Result :: Int - Arithmetic product of all elements in the column
      %% Note: If ColIndex is not valide within the matrix size return 142857
      %% Your code here
      if {IsValid Matrix ColIndex} then
         {Product {GetColumn Matrix ColIndex}}
      else
         142857
      end
   end

   fun {SumAll Matrix }
      %% Returns sum of all elements in the matrix
      %% Input: None
      %% Output: Result :: Int - Arithmetic sum of all matrix elements
      %% Note: Returns 0 for empty matrix
      %% Your code here
      {Sum {Map Matrix Sum}}
   end

   fun {ProductAll Matrix }
      %% Returns product of all elements in the matrix
      %% Input: None
      %% Output: Result :: Int - Arithmetic product of all matrix elements
      %% Note: Returns 1 for empty matrix, returns 0 if any element is 0
      %% Your code here
      {Product {Map Matrix Product}}
   end

   %% Utility funods
   fun {Display Matrix }
      %% Prints matrix in readable format to standard output
      %%    Any format is valid, just must display all the matrix content
      %% Input: None
      %% Output: None  Matrix void)
      %% Your code here
      {ForAll Matrix System.show}
      nil
   end
