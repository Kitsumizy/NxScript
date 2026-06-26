package nx.script.flixel;

#if flixel
import flixel.FlxSprite;

@:build(nx.script.macros.NxScriptClass.build())
class FlxScriptSprite extends FlxSprite {
    public function new(x:Float = 0, y:Float =0) {
        super(x,y);
    }
    override function update(elapsed:Float):Void {
        super.update(elapsed);
    }
}
#else
class FlxScriptSprite {}
#end