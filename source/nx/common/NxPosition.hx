package nx.common;

import nx.common.position.NxHighlighter;

class NxPosition {
    public final line:Int;
    public final column:Int;
    public final character:Int;
    public final _fn:Null<String>;
    public final file:String;
    public final source:String;

    public function new(
        line:Int,
        column:Int,
        character:Int,
        file:String,
        source:String,
        _fn:Null<String> = null
    ) {
        this.line = line;
        this.column = column;
        this.character = character;
        this.file = file;
        this.source = source;
        this._fn = _fn;
    }

    /**
     * test.nx:3:15
     * o
     * test.nx:3:15 (in main)
     */
    public function location():String {
        var str = '${file}:${line}:${column}';

        if (_fn != null)
            str += ' (in ${_fn})';

        return str;
    }

    /**
     * 3 | print("hello"
     *   |            ^
     */
    public function codeFrame():String {
        var lines = source.split("\n");

        if (line < 1 || line > lines.length)
            return "";

        var text = lines[line - 1];

        var spaces = "";
        for (i in 1...column)
            spaces += (i - 1 < text.length && text.charAt(i - 1) == "\t") ? "\t" : " ";

        return NxHighlighter.highlight('${line} | ${text}\n'
             + '  | ${spaces}^');
    }
    /**
    * Returns a string representation of the position in the format "file:line:column". If the function name is provided, it will also include it in the output.
    **/
    public function toString():String {
        return location();
    }

}