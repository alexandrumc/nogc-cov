import std.stdio;
import std.file;
import std.json;

void main(string[] args)
{
    string docs = args[1];
    string nogc_info = args[2];

    auto docs_json = parseJSON(readText(docs));
    auto nogc_json = parseJSON(readText(nogc_info));


    foreach (nogc_js; nogc_json.array)
    {
        if ("members" in nogc_js)
        {
            foreach(memb_nogc; nogc_js["members"].array)
            {
                foreach(docs_js; docs_json.array)
                {
                    if (docs_js["name"] == nogc_js["name"])
                    {
                        foreach (ref memb_docs; docs_js["members"].array)
                        {
                            if (memb_docs["name"].str == memb_nogc["fname"].str &&
                                    memb_docs["comment"].str != "ditto\n")
                            {
                                memb_docs.object["canBeNogc"] = JSONValue("true");
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    auto res = File("nogc_result.json", "w");
    res.writeln(docs_json.toPrettyString(JSONOptions.doNotEscapeSlashes));
}
