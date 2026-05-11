# NxScript Optimization TODOs

## Performance Optimizations (Issue #20)

### ✅ COMPLETED - Cache Type.getInstanceFields()
- **File**: `src/nx/script/MemberResolver.hx`
- **Change**: Added `nativeFieldsCache` to cache instance fields by class name
- **Impact**: Avoids expensive reflection calls in hot path for native object access
- **Status**: ✅ Done - Commited in 8e64d8a

### ✅ COMPLETED - Switch `=>` syntax support
- **File**: `src/nx/script/Parser.hx`
- **Change**: Accept both `:` and `=>` in switch case patterns
- **Impact**: Fixes 17 failing tests
- **Status**: ✅ Done - Commited in 8e64d8a

---

## Pending Optimizations

### 1. Hot Path Calling Optimization
**Description**: Reduce overhead in function calls, especially for native methods

**Potential improvements**:
- Inline common native method calls
- Cache method resolution results more aggressively
- Avoid unnecessary closure creation for bound methods

**Files to check**:
- `src/nx/script/VM.hx` - `callFunction()`, `callResolved()`
- `src/nx/script/MemberResolver.hx` - `cacheNativeMethodById()`

**Priority**: HIGH

---

### 2. Native Object Hot Path
**Description**: Further optimize native object field/method access

**Current bottleneck**: Even with field caching, `Reflection.getField()` and `Reflection.callMethod()` are slow

**Potential improvements**:
- Use direct `Reflect.field()` for known objects instead of Reflection wrapper
- Cache `Dynamic` field access results more aggressively
- Consider special-casing common native types (Array, String, etc.)

**Files to check**:
- `src/nx/script/MemberResolver.hx` - lines 178-229
- `src/nx/script/NativeClasses.hx` - Reflection helpers

**Priority**: HIGH

---

### 3. Hot Reloading (SYS only)
**Description**: Enable hot reloading ONLY when SYS (scripting system) is active

**Current state**: Unknown - need to investigate current hot reload implementation

**Requirements**:
- Add flag/config for hot reload mode
- Only enable when explicitly requested (SYS context)
- Ensure zero overhead when disabled

**Files to check**:
- `src/nx/script/Interpreter.hx`
- `src/nx/script/VM.hx`
- Search for "hot reload", "reload", "watch"

**Priority**: MEDIUM

---

### 4. VM Performance Investigation
**Description**: Profile VM to identify remaining bottlenecks

**Known slow operations**:
- Member access on native objects (partially fixed)
- Closure creation for bound methods
- Instruction dispatch in VM run loop

**Tools to use**:
- `test/tests/SpeedCheck/SpeedCheckTest.hx` - existing benchmarks
- Add profiling counters to VM.run()

**Priority**: MEDIUM

---

## Test Failures (3 remaining)

### 1. `sandbox blocks Sys`
**File**: `test/tests/TestSuite.hx:495`
**Expected**: `Sys.exit(3)` should throw sandbox error
**Status**: Not throwing error as expected

### 2. `Int_from(3.5) throws`
**File**: `test/tests/TestSuite.hx:517`
**Expected**: `Int_from(3.5)` should throw (invalid float to int conversion)
**Status**: Not throwing

### 3. `fromInt(2.5) throws`
**File**: `test/tests/TestSuite.hx:531`
**Expected**: `fromInt(2.5)` should throw
**Status**: Not throwing

**Priority**: LOW - These are validation/sandbox features, not core functionality

---

## Next Steps

1. **Profile VM** - Run SpeedCheckTest to establish baseline performance
2. **Investigate hot path calling** - Look at callFunction and callResolved
3. **Optimize native object access** - Consider bypassing Reflection for common cases
4. **Fix sandbox tests** - Review sandbox implementation

---

## Test Results Summary

- **Total tests**: 243
- **Passing**: 240 ✅
- **Failing**: 3 (sandbox/validation - low priority)

Last updated: 2026-05-11
