module master;

import std.process;
import std.file;
import std.stdio;
import std.path;


void main(string[] args)
{
    string path;
    string[] importPaths;
    string[] params;
    string[] versionIdentifiers = ["StdUnittest", "CoreUnittest"];
    Pid[] procPids;

    if (args.length < 3)
    {
        writeln("Please provide path to file or directory and import path");
        return;
    }
    else
    {
        path = args[1];
        if (!exists(path))
        {
            writeln("Invalid path");
            return;
        }
        for (int i = 2; i < args.length; i++)
            importPaths ~= args[i];
    }

    if(isDir(path))
    {
        auto dFiles = dirEntries(path, SpanMode.depth);
        foreach (d; dFiles)
        {
            params = [];
            params ~= "./nogcov_worker";
            params ~= d.name;
            params ~= importPaths;
            auto worker = spawnProcess(params);
            procPids ~= worker;
        }
        foreach(worker; procPids)
        {
            if (wait(worker) != 0)
                    writeln("Analysis failed!");
        }
    }
    else if(isFile(path))
    {
        params ~= "./nogcov_worker";
        params ~= path;
        params ~= importPaths;
        auto worker = spawnProcess(params);
        if (wait(worker) != 0)
                writeln("Analysis failed!");
    }
}
