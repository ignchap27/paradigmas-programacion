declare RecordRelation

fun {RecordRelation R1 R2}
   A1 A2 AllEqual Contained
in
   %% Todos los features de As tienen mismo valor en R1 y R2
   fun {AllEqual As}
      F
   in
      if As == nil then true
      else
         F = As.1
         if R1.F == R2.F then {AllEqual As.2}
         else false
         end
      end
   end

   %% Ra contenido en Rb
   fun {Contained As Ra Rb}
      F
   in
      if As == nil then true
      else
         F = As.1
         if {HasFeature Rb F} then
            if Ra.F == Rb.F then {Contained As.2 Ra Rb}
            else false
            end
         else false
         end
      end
   end

   A1 = {Arity R1}
   A2 = {Arity R2}

   if {Label R1} == {Label R2} andthen A1 == A2 then
      if {AllEqual A1} then equal
      else equivalent
      end
   elseif {Contained A1 R1 R2} then subsimilar
   elseif {Contained A2 R2 R1} then subsimilar
   else different
   end
end

%%{Show {RecordRelation point(x:1 y:2)     point(x:1 y:2)}}
%%{Show {RecordRelation point(x:1 y:2)     point(x:1 y:9)}}
%%{Show {RecordRelation point(x:1 y:2)     point(x:1 y:2 z:3)}}
%%{Show {RecordRelation point(x:1 y:2)     line(x:1 y:2)}}
%%{Show {RecordRelation point(x:1 y:2)     point(x:1 z:2)}}
