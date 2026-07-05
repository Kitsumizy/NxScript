package nx.common.position;

class NxHighlighter {

    static final KEYWORDS = [
        "if","else","while","for",
        "function","return",
        "var","let","const",
        "true","false","null",
        "break","continue",
        "switch","case","default",
        "new","this"
    ];

    public static function highlight(line:String):String {

        var out = line;

        // Strings
        var regex = ~/"([^"\\]|\\.)*"/g;
        out = regex.map(out, r ->
            NxAnsi.color(Green)
            + r.matched(0)
            + NxAnsi.color(Reset)
        );

        // Numbers
        regex = ~/\b\d+(\.\d+)?\b/g;
        out = regex.map(out, r ->
            NxAnsi.color(Cyan)
            + r.matched(0)
            + NxAnsi.color(Reset)
        );

        // Keywords
        for (k in KEYWORDS) {
            var kw = new EReg("\\b" + k + "\\b", "g");

            out = kw.map(out, r ->
                NxAnsi.color(Magenta)
                + r.matched(0)
                + NxAnsi.color(Reset)
            );
        }

        return out;
    }
}