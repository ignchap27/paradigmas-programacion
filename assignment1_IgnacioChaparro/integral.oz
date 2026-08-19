declare Integral

fun {Integral F A B N}
   H
   Coef
   Sum
in
   H = (B - A) / {IntToFloat N}

   %% Coeficiente Simpson
   fun {Coef K}
      if K == 0 then 1.0
      elseif K == N then 1.0
      elseif K mod 2 == 1 then 4.0
      else 2.0
      end
   end

   %% Suma ponderada de yk, K de 0 a N
   fun {Sum K}
      Yk
   in
      if K > N then 0.0
      else
         Yk = {F A + {IntToFloat K} * H}
         {Coef K} * Yk + {Sum K + 1}
      end
   end

   H / 3.0 * {Sum 0}
end

%%{Show {Integral fun {$ X} X * X end 0.0 1.0 100}}
%%{Show {Integral fun {$ X} X * X * X end 0.0 2.0 100}}
