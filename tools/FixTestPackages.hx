import sys.io.File;
import sys.FileSystem;
import StringTools;
import EReg;

/**
 * Automatically fix package statements in test files.
 * 
 * Scans all .hx files in test/tests/ subdirectories and updates
 * the package statement to match the folder structure.
 * 
 * Usage:
 *   haxe --interp tools/FixTestPackages.hx
 *   
 * Or from the test/tests folder:
 *   haxe -cp ../tools --main FixTestPackages --interp
 */
class FixTestPackages {
	static var ROOT = "test/tests/";
	
	static var FOLDERS = ["unit", "integration", "regression", "benchmarks", "benchmarks/SpeedCheck"];
	
	static function main() {
		trace("Fixing package statements in test files...");
		
		var fixedCount = 0;
		var errorCount = 0;
		
		for (folder in FOLDERS) {
			var fullPath = ROOT + folder;
			if (!FileSystem.exists(fullPath)) {
				trace('Warning: Folder not found: $fullPath');
				continue;
			}
			
			var files = FileSystem.readDirectory(fullPath);
			for (file in files) {
				if (!StringTools.endsWith(file, ".hx")) continue;
				
				var filePath = fullPath + "/" + file;
				if (FileSystem.isDirectory(filePath)) continue;
				
				if (fixPackageInFile(filePath, folder)) {
					fixedCount++;
				} else {
					errorCount++;
				}
			}
		}
		
		trace('Done! Fixed $fixedCount files, $errorCount errors.');
	}
	
	static function fixPackageInFile(filePath:String, folder:String):Bool {
		try {
			var content = File.getContent(filePath);
			var packageName = folder.split("/").join(".");
			
			// Convert folder name to package convention (e.g., "SpeedCheck" stays as is)
			var expectedPackage = 'package $packageName;';
			
			// Check if file already has correct package
			var lines = content.split("\n");
			var hasPackage = false;
			var firstLineIsPackage = false;
			
			for (i in 0...Std.int(Math.min(3, lines.length))) {
				var line = StringTools.trim(lines[i]);
				if (StringTools.startsWith(line, "package ")) {
					hasPackage = true;
					if (line == expectedPackage) {
						trace('✓ ${filePath}: Already correct');
						return true;
					}
					firstLineIsPackage = (i == 0);
					break;
				}
			}
			
			// Fix package statement
			var newContent:String;
			if (hasPackage && firstLineIsPackage) {
				// Replace existing package line
				lines[0] = expectedPackage;
				newContent = lines.join("\n");
			} else if (hasPackage) {
				// Package exists but not on first line - replace it
				newContent = new EReg('^\\s*package\\s+[^;]+;\\s*$', "m").replace(content, expectedPackage);
			} else {
				// No package - add at the beginning
				newContent = expectedPackage + "\n\n" + content;
			}
			
			File.saveContent(filePath, newContent);
			trace('✓ ${filePath}: Fixed to "$packageName"');
			return true;
			
		} catch (e:Dynamic) {
			trace('✗ ${filePath}: Error - $e');
			return false;
		}
	}
}
