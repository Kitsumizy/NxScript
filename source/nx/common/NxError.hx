package nx.common;

class NxError {
    public final message:String;
    public final infopos:NxPosition;

    public function new(message:String, infopos:NxPosition) {
        this.message = message;
        this.infopos = infopos;
    }

    public function toString():String {
        return
            'Error: ${message}\n\n'
            + ' --> ${infopos.location()}\n\n'
            + infopos.codeFrame();
    }
}