package main;

import nx.NxScript;
import nx.script.NxManager;


class Main {
    static function main() {
        NxManager.file_loader = function(path:String):String {
            #if sys
                return sys.io.File.getContent(path);
            #elseif js
                return js.node.Fs.readFileSync(path, "utf8");
            #else
                throw "File loading not supported in this environment.";
            #end
        };

        NxManager.file_exists = function(path:String):Bool {
            #if sys
                return sys.FileSystem.exists(path);
            #elseif js
                return js.node.Fs.existsSync(path);
            #else
                throw "File exists check not supported in this environment.";
            #end
        };

        NxManager.initialize();

        try {
            if (NxManager.file_exists("assets/test.nx")) {
                var script = new NxScript("assets/test.nx");
            } else {
                trace("Error: El archivo assets/test.nx no existe.");
            }
        } catch(e:Dynamic) {
            trace("Ocurrió un error al ejecutar el script: " + e);
        }
    }
}
