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

### ✅ COMPLETED - Native Object Field Value Caching
- **File**: `src/nx/script/MemberResolver.hx`
- **Change**: Added `nativeFieldValueCache` for direct field value caching
- **Impact**: Avoids `Reflection.getField()` on repeated field access
- **Cache invalidation**: On `setMember()` for consistency
- **Status**: ✅ Done - Commited in 7fbff63

---

## ✅ ALL TASKS COMPLETED

### 1. ✅ Profiling Analysis
- Ran profiling with `-D nx_profile`
- Identified hotspots: POP (21.7%), STORE/LOAD_GLOBAL (~22%), FOR_ITER/ADD (~21%)
- Member access now cached - only 0.1% of operations

### 2. ✅ Native Object Optimization
- Implemented field value cache (`nativeFieldValueCache`)
- Avoids repeated `Reflection.getField()` calls
- Cache invalidation on field set operations

### 3. ✅ Test Fixes
- **All 243 tests passing** (was 240/243)
- Fixed syntax error in VM.hx that was causing 3 sandbox tests to fail
- Tests: sandbox blocks Sys, Int_from(3.5), fromInt(2.5)

### 4. ✅ Compiler Optimizations (NEW)
- **Constant Folding**: Arithmetic on literals computed at compile time
- **Peephole Optimization**: Removes redundant instruction sequences
- **Dead Code Elimination**: Removes unreachable code after RETURN/THROW
- **Exported to Interpreter**: `interp.optimize = true` to enable
- All tests pass with optimizations enabled (243/243) ✅

---

## Test Results Summary

- **Total tests**: 243
- **Passing**: 243 ✅ **ALL TESTS PASSING!**
- **Failing**: 0

---

## Recent Commits

- `c799bca` - Export compiler optimization options to Interpreter
- `a75975e` - Feat: Add compiler optimizations (disabled by default)
- `7fbff63` - All tests passing + Native object field caching
- `42d324b` - docs: Update TODO.md
- `3c709a9` - Hot path improvements and profiling support
- `8e64d8a` - Switch `=>` syntax + MemberResolver caching
- `315abea` - Default function arguments (Issue #21)
- `e931057` - Anonymous functions (Issue #22)

---

## Profiling Usage

```bash
# Compile with profiling
haxe -D nx_profile build.hxml

# Run and print report
# In your code: interp.vm.printProfileReport()
```

Example output:
```
═══════════════════════════════════════
  NxScript VM Profiling Report
═══════════════════════════════════════
Total function calls: 0
Total native calls: 1
Total member accesses: 1

Instruction breakdown:
  POP: 205 (21.7%)
  STORE_GLOBAL: 105 (11.1%)
  LOAD_GLOBAL: 103 (10.9%)
  ...
═══════════════════════════════════════
```

---

## Compiler Optimizations Usage

```haxe
var interp = new Interpreter();

// Enable all optimizations
interp.optimize = true;

// Or configure individually
interp.optimizeDCE = true;              // Dead code elimination
interp.optimizeConstantFolding = true;  // Constant folding
interp.optimizePeephole = true;         // Peephole optimization

interp.run(sourceCode);
```

**Default**: All optimizations disabled (safe mode)
**Performance**: Expected 10-30% improvement on compute-heavy code when enabled

Last updated: 2026-05-11
