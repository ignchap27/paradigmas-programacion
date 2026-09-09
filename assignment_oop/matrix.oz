%% Matrix Class Definition
%% Represents a square matrix with operations for rows, columns, and entire matrix
declare Matrix

class Matrix
   attr data size
   
   meth init(Data) 
      %% Initialize matrix from list of lists
      %% Input: Data :: [[Int]] - List of lists representing matrix rows
      %%                            Each inner list represents a row of the matrix
      %%                            All rows must have equal length to form a square matrix
      %% Precondition: Data must represent a valid square matrix (N×N where N > 0)
      %% Side effects: Initializes @data and @size attributes
      %% Your code here
      skip
   end 
   
   meth getSize(?Result)
      %% Returns the size N of the N×N matrix
      %% Input: None
      %% Output: Result :: Int - The dimension N of the N×N matrix
      %% Your code here
      skip
   end
   
   meth getElement(Row Col ?Result)
      %% Returns element at position (Row, Col) using 1-indexed coordinates
      %% Input: Row :: Int - Row index (1 ≤ Row ≤ N)
      %%        Col :: Int - Column index (1 ≤ Col ≤ N)
      %% Output: Result :: Int - Element at position (Row, Col)
      %% Note: If Row and Col are not valide within the matrix size return 142857
      %% Your code here
      skip
   end
   
   meth getRow(RowIndex ?Result)
      %% Returns the complete row as a list
      %% Input: RowIndex :: Int - Row number (1 ≤ RowIndex ≤ N)
      %% Output: Result :: [Int] - List containing all elements of the specified row
      %% Note: If RowIndex is not valide within the matrix size return 142857
      %% Your code here
      skip
   end
   
   meth getColumn(ColIndex ?Result)
      %% Returns the complete column as a list
      %% Input: ColIndex :: Int - Column number (1 ≤ ColIndex ≤ N)  
      %% Output: Result :: [Int] - List containing all elements of the specified column
      %% Note: If ColIndex is not valide within the matrix size return 142857
      %% Your code here
      skip
   end
   
   meth sumRow(RowIndex ?Result)
      %% Returns sum of all elements in specified row
      %% Input: RowIndex :: Int - Row number (1 ≤ RowIndex ≤ N)
      %% Output: Result :: Int - Arithmetic sum of all elements in the row
      %% Precondition: RowIndex is valid within the Matrix size
      %% Note: If RowIndex is not valide within the matrix size return 142857
      %% Your code here
      skip
   end
   
   meth productRow(RowIndex ?Result)
      %% Returns product of all elements in specified row
      %% Input: RowIndex :: Int - Row number (1 ≤ RowIndex ≤ N)
      %% Output: Result :: Int - Arithmetic product of all elements in the row
      %% Note: If RowIndex is not valide within the matrix size return 142857
      %% Your code here
      skip
   end
   
   meth sumColumn(ColIndex ?Result)
      %% Returns sum of all elements in specified column
      %% Input: ColIndex :: Int - Column number (1 ≤ ColIndex ≤ N)
      %% Output: Result :: Int - Arithmetic sum of all elements in the column
      %% Note: If ColIndex is not valide within the matrix size return 142857
      %% Your code here
      skip
   end
   
   meth productColumn(ColIndex ?Result)
      %% Returns product of all elements in specified column
      %% Input: ColIndex :: Int - Column number (1 ≤ ColIndex ≤ N)
      %% Output: Result :: Int - Arithmetic product of all elements in the column
      %% Note: If ColIndex is not valide within the matrix size return 142857
      %% Your code here
      skip
   end
   
   meth sumAll(?Result)
      %% Returns sum of all elements in the matrix
      %% Input: None
      %% Output: Result :: Int - Arithmetic sum of all matrix elements
      %% Note: Returns 0 for empty matrix
      %% Your code here
      skip
   end
   
   meth productAll(?Result) 
      %% Returns product of all elements in the matrix
      %% Input: None
      %% Output: Result :: Int - Arithmetic product of all matrix elements
      %% Note: Returns 1 for empty matrix, returns 0 if any element is 0
      %% Your code here
      skip
   end
   
   %% Utility methods
   meth display()
      %% Prints matrix in readable format to standard output
      %%    Any format is valid, just must display all the matrix content
      %% Input: None
      %% Output: None (void)
      %% Your code here
      skip
   end
end