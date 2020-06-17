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
import dmd.root.outbuffer;

import std.file;
import std.string;
import std.range;
import std.stdio;
import std.algorithm;
import std.path;
import std.json;

string resultsDir = "results/";

extern(C++) class NogcCoverageVisitor : SemanticTimeTransitiveVisitor
{
    alias visit = SemanticTimeTransitiveVisitor.visit;
    Scope* sc;
    bool insideUnittest;
    string[][string] funcDict;
    JSONValue jv;

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
            FuncDeclaration fd = ce.f;
            if (fd !is null)
            {
                TypeFunction tf = fd.type.toTypeFunction();
                if (!fd.isCtorDeclaration() && fd.parent.isTemplateInstance())
                {
                    TemplateDeclaration td = getFuncTemplateDecl(fd);
                    if (td !is null)
                    {
                        string funcName = fd.toString().idup();
                        string tdName = td.toString().idup();
                        if ("members" !in jv)
                        {
                            JSONValue jj = JSONValue(["fname" : funcName]);
                            jj.object["signatures"] = [JSONValue(["form" : tdName])];

                            jv.object["members"] = [jj];
                        }
                        else
                        {
                            bool insideMembers = false;
                            foreach (ref jval; jv["members"].array)
                            {
                                if (jval["fname"].str == funcName)
                                {
                                    insideMembers = true;
                                    bool insideSignatures = false;
                                    foreach(jjval; jval["signatures"].array)
                                    {
                                        if (jjval["form"].str == tdName)
                                            insideSignatures = true;
                                    }
                                    if (!insideSignatures)
                                    {
                                        jval["signatures"].array ~= JSONValue(["form" : tdName]);
                                    }
                                    break;
                                }
                            }
                            if (!insideMembers)
                            {
                                JSONValue jj = JSONValue(["fname" : funcName]);
                                jj.object["signatures"] = [JSONValue(["form" : tdName])];

                                jv["members"].array ~= jj;
                            }
                        }
                    }
                }
            }
        }
    }
}

void nogcCoverageCheck(Dsymbol dsym, Scope* sc)
{
    OutBuffer buf;
    Module m = cast(Module)dsym;
    m.fullyQualifiedName(buf);

    string fullName = buf.extractSlice();

    auto f = File(resultsDir ~ fullName ~ ".json", "a");

    JSONValue jv = JSONValue(["name" : fullName]);

    scope v = new NogcCoverageVisitor(sc);
    v.jv = jv;
    dsym.accept(v);

    jv.object["file"] = JSONValue(fullName.replace(".", "/") ~ ".d");
    jv.object["kind"] = JSONValue("module");

    writeln(v.jv.toPrettyString(JSONOptions.doNotEscapeSlashes));

    f.writeln(v.jv.toPrettyString(JSONOptions.doNotEscapeSlashes));
    f.close();
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
