package nx.script.flixel;

#if flixel
import flixel.FlxState;

@:build(nx.script.macros.NxScriptClass.build())
class FlxScriptState extends FlxState {

	override public function create():Void {
		super.create();
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
	}
}
#else
class FlxScriptState {}
#end
