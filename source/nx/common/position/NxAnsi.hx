package nx.common.position;

class NxAnsi {
    public static inline function color(c:TokenColor):String {
        return switch(c) {
            case Reset: "\x1b[0m";
            case Red: "\x1b[31m";
            case Green: "\x1b[32m";
            case Yellow: "\x1b[33m";
            case Blue: "\x1b[34m";
            case Magenta: "\x1b[35m";
            case Cyan: "\x1b[36m";
            case Gray: "\x1b[90m";
        }
    }
}