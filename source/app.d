module app;

import dmd.parse;
import dmd.visitor;
import dmd.frontend;
import dmd.astbase;
import dmd.errors;
import dmd.dscope;
import dmd.dsymbol;
import dmd.globals;
import dmd.identifier;
import dmd.id;
import dmd.dmodule;
import dmd.visitor;
import dmd.func;
import dmd.astcodegen;

import std.file;
import std.stdio;
import std.algorithm;

extern(C++) class NogcCoverageVisitor : SemanticTimeTransitiveVisitor
{
    alias visit = SemanticTimeTransitiveVisitor.visit;
    Scope* sc;

    this(Scope* sc)
    {
        this.sc = sc;
    }

    override void visit(UnitTestDeclaration d)
    {
        writeln("unittest");
    }

    override void visit(FuncDeclaration fd)
    {
        writeln("I'm inside a function");
        //SemanticTimeTransitiveVisitor.visit(fd);
        writeln("I'm outside a function");
    }
}

void nogcCoverageCheck(Dsymbol dsym, Scope* sc)
{
    scope v = new NogcCoverageVisitor(sc);
    dsym.accept(v);
}

void main()
{
    import std.stdio;
    string fname = "test.d";
    string[1] predefinedVersions = ["unittest"];

    initDMD();
    global.params.isLinux = true;
    global.params.is64bit = (size_t.sizeof == 8);
    global.params.useUnitTests = true;

    findImportPaths().each!addImport;

    //auto id = Identifier.idPool(fname);
    //auto m = new Module(fname, id, false, false);
    //auto input = readText(fname);
    //m.read(Loc.initial);
    //m.parse();

    //scope p = new Parser!ASTCodegen(m, input, false);
    //p.nextToken();
    //m.members = p.parseModule();

    Module m = parseModule(fname).module_;
    assert(m !is null);
    writeln(prettyPrint(m));
    fullSemantic(m);

    m.nogcCoverageCheck(null);

    deinitializeDMD();

}
