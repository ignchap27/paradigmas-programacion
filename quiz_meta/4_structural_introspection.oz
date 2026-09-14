%% Quiz Metaprogramacion
%% Ignacio Chaparro - 202220577
%% Daniel Diab - 202212289

%% Identificar en que funciones tiene reflexion, introspeccion e intersession

declare

proc {DescribeRecord R}
   Lbl = {Label R} %% estas dos lineas son introspeccion porque se esta leyendo la estuctura de R sin cambiarla
   Feats = {Arity R}
in
   {Browse 'record label'#Lbl}
   {Browse 'fields'#Feats}
   for F in Feats do
      {Browse F#'='#R.F} %% tambien instorspeccion porque se esta entrando a consultar el valor de R.F
   end
end

local
   P = point(x:2 y:3)
   Q = person(name:"Ada" age:36 role:"Engineer")
in
   {DescribeRecord P}
   {Browse '---'}
   {DescribeRecord Q}
end


class Shape
   meth area($)
      0 
   end
end

class Circle from Shape
   attr radius
   meth init(R)
      radius := R
   end
   meth area($)
      3.14159 * @radius * @radius 
   end
end

proc {SafeCall Obj M ?Result}
   try
      {Obj M}
      Result = ok
   catch _ then
      Result = notUnderstood(M)
   end
end

local
   C = {New Circle init(5)}
   R1 R2 Status1 Status2
in
   {SafeCall C area(R1) Status1}
   {Browse Status1#R1}          
   %% estas dos lineas se considerarian interseccion porque estas cambiando un circulo de estado base a uno se estado 1.
   %% lo mismo sucede abajo pero convirtiendo el circulo a estado 2.
   {SafeCall C perimeter(R2) Status2}
   {Browse Status2}             
end