package nx.script;

import nx.common.NxRawSource;
import nx.common.NxLoader;
import nx.common.NxPosition;
import nx.signal.NxSignal;

class NxManager {
    public static var onException:NxSignal<NxException> = new NxSignal<NxException>("Exception Events");
    public static var runtimeException:NxSignal<NxException> = new NxSignal<NxException>("Runtime Exception Events");
    public static var file_loader:(path:String) -> String = null;
    public static var file_exists:(path:String) -> Bool = null;

    public static function initialize():Void {
        NxLoader.loadSource = function(path:String):NxRawSource {
            if (file_loader != null) {
                var content = file_loader(path);
                return new NxRawSource(content, path);
            } else {
                throw "No file loader function provided.";
            }
        };
        NxLoader.existsSource = function(path:String):Bool {
            if (file_exists != null) {
                return file_exists(path);
            } else {
                throw "No file exists function provided.";
            }
        };
        onException.connect(printException);
        runtimeException.connect(printException);
    }

    static function printException(exception:NxException):Void {
        
      #if (NX_MODE == 0)
        throw exception;
     #elseif (NX_MODE == 1)
            #if sys Sys.println(exception.toString());
            #else trace(exception.toString()); #end
        #end
    }
}