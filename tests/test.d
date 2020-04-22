module test;

import other;

@nogc unittest
{
    assert(smth(2, true) == 2);
    foo_bar(true, false);

    //Template instantiation in static asssert is not detected yet
    static assert(smth(3.3, false) == 0);
}

@nogc unittest
{
    sum(19, 20);
}

@nogc unittest
{
    foo_bar(true, true);
    bar!int(2,3);
    bar!uint(20, 40);
    bar(2.0, 3.0);
    assert (1 == 1);
}

@nogc @safe int foo(int a, int b)
{
    int c = a + b;
    int d = c * a + b;
    return d * 10;
}

@nogc foo_bar(bool a, bool b)
{
    foo(1, 2);
    bar!float(56, 66);
    return a && b;
}

T bar(T)(T x, T y)
{
    return x + y;
}

T smth(T, E)(T a, E b)
{
    if (b)
        return a;
    else
        return 0;
}
