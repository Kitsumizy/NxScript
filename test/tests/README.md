# NxScript Test Suite

## Organization

```
test/tests/
├── unit/           # Unit tests for individual components
├── integration/    # Integration tests (Haxe ↔ Script interaction)
├── regression/     # Bug fix tests and issue regression tests
├── benchmarks/     # Performance benchmarks
├── SpeedCheck/     # Speed comparison tests (moved to benchmarks/)
└── *.hxml          # Test runner configurations
```

## Running Tests

### Run all tests
```bash
cd test/tests
haxe test_suite.hxml
```

### Run individual tests
```bash
# Basic functionality
haxe basic.hxml

# Class system tests
haxe classes.hxml

# Parser tests (Haxe syntax)
haxe haxeparser.hxml

# Switch/case tests
haxe switchcases.hxml

# Import system tests
haxe imports.hxml

# Method/function tests
haxe methods.hxml

# Static preprocessor tests
haxe static_preprocessor.hxml

# Error formatting tests
haxe errors.hxml

# Bridge and using tests
haxe bridge_using.hxml

# Bug fix regression tests
haxe bugfix.hxml

# Parent scope integration test
haxe -cp . -cp ../../src --main integration.ParentScopeTest --interp
```

## Test Categories

### Unit Tests (`unit/`)
- Test individual components in isolation
- Pure NxScript functionality
- Data structures and helpers

### Integration Tests (`integration/`)
- Haxe ↔ Script interaction
- Parent scope feature
- Native object bridging
- Proxy tests

### Regression Tests (`regression/`)
- Bug fix verification
- Issue-specific tests (Issue21, Issue22, etc.)
- Prevents reintroducing old bugs

### Benchmarks (`benchmarks/`)
- Performance comparisons
- Speed tests
- Optimization validation

## Adding New Tests

1. Create a new `.hx` file in the appropriate folder
2. Add a corresponding `.hxml` file if needed
3. Follow the naming convention: `*Test.hx`
4. Use `trace("PASS: ...")` and `trace("FAIL: ...")` for results

Example:
```haxe
package integration;

import nx.script.Interpreter;

class MyFeatureTest {
    public function new() {
        var interp = new Interpreter();
        // ... test code
    }
    
    public static function main() {
        new MyFeatureTest();
    }
}
```
