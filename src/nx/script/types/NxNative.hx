package nx.script.types;

import nx.script.Bytecode.Value;

/**
 * Simple wrapper for native host objects passed through script values.
 */
class NxNative<T> extends NxObject {
	public var value(default, null):T;

	public function new(value:T) {
		super(null, VNativeObject(cast value));
		this.value = value;
	}
}
