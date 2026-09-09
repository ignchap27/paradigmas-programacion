declare Expression Num Sum
class Expression
    meth print
        {System.showInfo "Base method does nothing"}
    end
    meth eval(R)
        {System.showInfo "Base method does nothing"}
    end
end

class Num from Expression
    attr n:0
    meth init(Val)
        n := Val
    end
    meth print
        {System.showInfo @n}
    end
    meth eval(R)
        R = @n
    end	
end

class Sum from Expression
    attr left right
    meth init(L R)
        left := L
        right := R
    end
    meth print
        {@left print} {System.showInfo "+"} {@right print}
        %for module print "mod" as the operator
    end
    meth eval(R)
        local LR RR in
            {@left eval(LR)}
            {@right eval(RR)}
            R =  LR + RR
        end 
    end
end