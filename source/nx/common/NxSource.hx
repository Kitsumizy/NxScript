package nx.common;
import nx.script.NxManager;
import nx.common.Types.SourceContentOrPath;
class NxSource {
    public final path:String;
    public final content:NxRawSource;

    public var length(get, never):Int;
    public inline function get_length():Int {
        return content.length;
    }


    public function new(source:SourceContentOrPath) {
      
        if (source is String) {
            trace('Loading source from path: ${source}');
            this.path = source;
            if (NxLoader.existsSource(source)) {
                trace('Source found: ${source}');
                this.content = NxLoader.loadSource(source);
            } else {
                NxManager.onException.emit(new NxError('File not found: ${source}', null));
            }
        } else {
            this.path = "<anonymous>";
            this.content = source;
        }
    }

    public function charAt(i:Int) {
        return content.charAt(i);
    }

    public static function loadAnnonymous(value:String) {
        return new NxSource(new NxRawSource(value, "<anonymous>")); 
    }
}