module other;

import test;

@nogc int sum(int a, int b)
{
    return a + b;
}

version (unittest)
{
    @nogc int ten()
    {
        return 10;
    }
}

version (StdUnittest)
{
    @nogc int eleven()
    {
        return 11;
    }
}

@nogc unittest
{
    sum(1, 2);
}

// Check that version identifiers are enabled
unittest
{
    static assert(ten() == 10);
    static assert(eleven() == 11);
}
