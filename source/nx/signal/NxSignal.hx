package nx.signal;

/**
 * A signal that can be emitted and listened to. Duh.
 */
class NxSignal<T> {
    /**
     * The name of the signal. This is used for debugging purposes.
     */
    public final name:String;
    /**
     * The listeners that are connected to this signal.
     */
    private var listeners:Array<(value:T)->Void> = [];

    /**
     * Creates a new signal with the given name.
     * @param name The name of the signal.
     */
    public function new(name:String) {
        this.name = name;
    }

    /**
     * Checks if this signal is equal to another signal.
     * @param other The other signal to compare to.
     * @return True if the signals are equal, false otherwise.
     */
    public function equals(other:NxSignal<T>):Bool {
        return this.name == other.name;
    }
    /**
     * Connects a listener to this signal.
     * @param listener The listener to connect.
     * @return The index of the connected listener.
     */
    public function connect(listener:(value:T)->Void):Int {
        return listeners.push(listener);
    }
    /**
     * Disconnects a listener from this signal.
     * @param listener The listener to disconnect.
     * @return True if the listener was disconnected, false otherwise.
     */
    public function disconnect(listener:(value:T)->Void):Bool {
        return listeners.remove(listener);
    }
    public function onceConnect(listener:(value:T)->Void):Void {
        var fn:(value:T)->Void = null;
        
        fn = (value:T) -> {
            listener(value);
            disconnect(fn);
        };
        connect(fn);
    }
    /**
     * Clears all listeners from this signal.
     */
    public function clear():Void {
        listeners = [];
    }

    /**
     * Emits this signal with the given value.
     * @param value The value to emit.
     */
    public function emit(value:T ):Void {
        for (listener in listeners) {
            listener(value);
        }
    }

    public function toString():String {
        return 'NxSignal(name: ${name})';
    }
}