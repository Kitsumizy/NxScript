package nx.ast;

class NodeIdGenerator {
	static var nextId:NodeId = 0;

	public static inline function next():NodeId {
		return nextId++;
	}
}