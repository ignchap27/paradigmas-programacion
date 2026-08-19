declare InorderPreorder2BT InorderPostorder2BT Span SplitAt InitLast

fun {Span L X}
   Rec
in
   if L == nil then nil # nil
   elseif L.1 == X then nil # L.2
   else
      Rec = {Span L.2 X}
      (L.1|Rec.1) # Rec.2
   end
end

fun {SplitAt N L}
   Rec
in
   if N == 0 then nil # L
   else
      Rec = {SplitAt N-1 L.2}
      (L.1|Rec.1) # Rec.2
   end
end

fun {InitLast L}
   Rec
in
   if L.2 == nil then nil # L.1
   else
      Rec = {InitLast L.2}
      (L.1|Rec.1) # Rec.2
   end
end

%% inorderPreorder2BT
%% Input: Two lists representing the inorder and preorder traversals of a binary tree
%% Output: A binary tree built from the traversals
fun {InorderPreorder2BT In Pre}
   Root InSplit InLeft InRight PreSplit
in
   if Pre == nil then nil
   else
      Root = Pre.1
      InSplit = {Span In Root}
      InLeft = InSplit.1
      InRight = InSplit.2
      PreSplit = {SplitAt {Length InLeft} Pre.2}
      tree(Root
           {InorderPreorder2BT InLeft PreSplit.1}
           {InorderPreorder2BT InRight PreSplit.2})
   end
end

%% inorderPostorder2BT
%% Input: Two lists representing the inorder and postorder traversals of a binary tree
%% Output: A binary tree built from the traversals
fun {InorderPostorder2BT In Post}
   IL Root PostInit InSplit InLeft InRight PostSplit
in
   if Post == nil then nil
   else
      IL = {InitLast Post}
      Root = IL.2
      PostInit = IL.1
      InSplit = {Span In Root}
      InLeft = InSplit.1
      InRight = InSplit.2
      PostSplit = {SplitAt {Length InLeft} PostInit}
      tree(Root
           {InorderPostorder2BT InLeft PostSplit.1}
           {InorderPostorder2BT InRight PostSplit.2})
   end
end

%%{Show {InorderPreorder2BT [1 2 3 4 5 6 7] [4 2 1 3 6 5 7]}}
%%{Show {InorderPostorder2BT [1 2 3 4 5 6 7] [1 3 2 5 7 6 4]}}
