module worker;

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
import dmd.expression;
import dmd.dtemplate;
import dmd.errors;
import dmd.arraytypes;
import dmd.mtype;

import std.file;
import std.range;
import std.stdio;
import std.algorithm;
import std.path;

extern(C++) class NogcCoverageVisitor : SemanticTimeTransitiveVisitor
{
    alias visit = SemanticTimeTransitiveVisitor.visit;
    Scope* sc;
    bool insideUnittest;
    string fileName;

    this(Scope* sc)
    {
        this.sc = sc;
        this.insideUnittest = false;
    }

    override void visit(UnitTestDeclaration ud)
    {
        if (ud.type !is null)
        {
            if (ud.isNogc)
            {
                insideUnittest = true;
                ud.fbody.accept(this);
                insideUnittest = false;
            }
        }
    }

    override void visit(CallExp ce)
    {
        Dsymbol sym;
        if (insideUnittest)
        {
            writeln("\n", fileName, "(", ce.loc.linnum, "): FuncCall in @nogc unittest: ", ce.f);
            FuncDeclaration fd = ce.f;
            TypeFunction tf = fd.type.toTypeFunction();
            if (fd.parent.isTemplateInstance())
            {
                writeln("\t|\n\t|-------->TemplateInstance called: ", fd.parent);
                writeln("\t|\n\t|-------->TemplateInstance header: ", tf);
                TemplateDeclaration td = getFuncTemplateDecl(fd);
                writeln("\t\t|\n\t\t|-------->TemplateDeclaration used: ", td);
            }
            else
            {
                writeln("\t|\n\t|-------->Function called: ", fd, " ", tf);
                writeln("\t|\n\t|-------->Function called: ", fd, " ");
            }
        }
    }

    override void visit(TemplateInstance ti)
    {
        if (insideUnittest)
            writeln(ti.loc.linnum, ": TemplateInstance: ", ti);
    }

    override void visit(DotTemplateInstanceExp dtie)
    {
        if (insideUnittest)
            writeln("DotTemplate :", dtie);
    }
}

void nogcCoverageCheck(Dsymbol dsym, Scope* sc)
{
    scope v = new NogcCoverageVisitor(sc);
    v.fileName = dsym.ident.toString().idup;
    dsym.accept(v);
}


void initTool(string[] versionIdentifiers, string[] importPaths)
{
    //Global.params must be set *before* initDMD();
    global.params.isLinux = true;
    global.params.is64bit = (size_t.sizeof == 8);
    global.params.useUnitTests = true;
    global.params.useDIP25 = true;
    global.params.vsafe = true;

    initDMD(null, versionIdentifiers);

    /*
    Import paths should be added using addImport()
    because findImportPaths() might lead to conflicts
    between /usr/bin/phobos and /dlang/phobos
    */
    importPaths.each!addImport;
}

void deinitializeTool()
{
    deinitializeDMD();
}

Modules prepareModules(string path)
{
    Modules modules;
    if(isDir(path))
    {
        auto dFiles = dirEntries(path, SpanMode.depth);
        foreach (d; dFiles)
        {
            writeln(d.name);
            Module m = parseModule(d.name).module_;
            fullSemantic(m);
            modules.push(m);
        }
    }
    else if(isFile(path))
    {
        Module m = parseModule(path).module_;
        fullSemantic(m);
        modules.push(m);
    }
    return modules;
}

void checkNogcCoverage(Modules *modules)
{
    foreach(m; *modules)
    {
        m.nogcCoverageCheck(null);
    }
}


void main(string[] args)
{
    string path;
    Modules modules;
    string[] importPaths;
    string[] versionIdentifiers = ["StdUnittest", "CoreUnittest"];

    path = args[1];

    for (int i = 2; i < args.length; i++)
        importPaths ~= args[i];

    initTool(versionIdentifiers, importPaths);

    modules = prepareModules(path);

    checkNogcCoverage(&modules);

    deinitializeTool();
}
