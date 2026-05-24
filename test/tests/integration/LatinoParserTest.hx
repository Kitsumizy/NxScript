package integration;

import nx.script.Bytecode.Value;
import nx.script.parsers.LatinoParser;
import sys.io.File;
import nx.script.Interpreter;
import haxe.Http;

class LatinoParserTest {
	public static function main() {
		trace(Http);
		var interp = new Interpreter();

		interp.parser = new LatinoParser();
		interp.register('achetetepe', -1, function(valores:Array<Value>):Value {
			var url = switch (valores[0]) {
				case VString(s): s;
				default:
					trace("URL inválida");
					return VNull;
			};

			if (!StringTools.startsWith(url, "https://")) {
				trace("URL debe ser https");
				return VNull;
			}

			var callback = valores[1];
			var htp = new Http(url);
			htp.onData = function(data:String) {
				interp.callResolved(callback, [VString(data)]);
			};
			htp.onError = function(err:String) {
				interp.callResolved(callback, [VNull]);
			};
			htp.request();
			return VNull;
		});
		interp.register('achetetepeese', -1, function(valores:Array<Value>):Value {
			var url = switch (valores[0]) {
				case VString(s): s;
				default:
					trace("URL inválida");
					return VNull;
			};

			if (!StringTools.startsWith(url, "http://")) {
				trace("URL debe ser http");
				return VNull;
			}

			var callback = valores[1];
			var htp = new Http(url);
			htp.onData = function(data:String) {
				interp.callResolved(callback, [VString(data)]);
			};
			htp.onError = function(err:String) {
				interp.callResolved(callback, [VNull]);
			};
			htp.request();
			return VNull;
		});
		interp.runFile('assets/LatinoTest.lat');
	}
}
