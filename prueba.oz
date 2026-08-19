declare Z
Y = &n
Z = 34

local X Y Z in
X = 3
Y = 5
Z = X + Y
end

{Show Z}
{Show Y}

declare A
declare B

declare Square X

fun {Square X}
    X * X
end

X = 5

{Show {Square X}}


declare Y Z W Q
proc {Square X R1 R2 R3}
    R1 = X * X
    R2 = X + X
    R3 = X - X
end
{Square 5 Y Z W}
{Show Y Z W}

for I in 1..10 do
    if I then
    {Show I}
end

declare X
X = {NewCell 4}
X := 7
{Show @X}