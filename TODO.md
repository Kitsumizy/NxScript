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

### ✅ COMPLETED - Hot Path Calling Optimizations
- **File**: `src/nx/script/VM.hx`
- **Changes**:
  - Optimized `callFunction()`: single loop for args+defaults
  - Optimized `OP_CALL`: combined defaults+locals initialization
  - Removed redundant variable declarations
  - Added `#if nx_profile` profiling support
- **Profiling features**:
  - `instructionCount`: opcode execution frequency
  - `callCount`: total function calls
  - `nativeCallCount`: native function calls  
  - `memberAccessCount`: member access operations
  - `printProfileReport()`: detailed breakdown
- **Status**: ✅ Done - Commited in 3c709a9

### ✅ COMPLETED - Hot Reloading Conditional
- **File**: `src/nx/script/Main.hx`
- **Change**: Watch mode now requires `#if SYS` compilation flag
- **Impact**: Zero overhead in production builds
- **Status**: ✅ Done - Commited in 3c709a9

---

## Pending Optimizations

### 1. Native Object Hot Path
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

### 2. VM Profiling Analysis
**Description**: Use new profiling tools to identify remaining bottlenecks

**How to use**:
```bash
haxe -D nx_profile build.hxml
# Run your benchmark
# Call vm.printProfileReport()
```

**What to look for**:
- Most executed instructions
- Ratio of native vs script calls
- Member access patterns

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

1. **Run profiling** - Use `-D nx_profile` to identify hotspots
2. **Optimize native access** - Consider bypassing Reflection for common cases
3. **Fix sandbox tests** - Review sandbox implementation

---

## Test Results Summary

- **Total tests**: 243
- **Passing**: 240 ✅
- **Failing**: 3 (sandbox/validation - low priority)

Last updated: 2026-05-11

## Recent Commits

- `3c709a9` - Hot path improvements and profiling support
- `8e64d8a` - Switch `=>` syntax + MemberResolver caching
- `315abea` - Default function arguments (Issue #21)
- `e931057` - Anonymous functions (Issue #22)
