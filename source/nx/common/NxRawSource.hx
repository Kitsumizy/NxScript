package nx.common;

/**
 * Represents the raw source code of a program.
 */
@:forward(length, charAt)
abstract NxRawSource(String) from String to String {
    public inline function get_source():String {
        return this;

    }
    
    public function new(source:String, path:String) {
        this = source;
    }
    
}