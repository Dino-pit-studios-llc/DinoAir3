# ADR 001: JSON Serialization with Freezed

**Status**: Accepted  
**Date**: 2025-10-21  
**Deciders**: Development Team  
**Context**: Phase 1 - Critical Foundation Fixes

---

## Context and Problem Statement

The DinoAir Flutter application requires a robust and maintainable approach to JSON serialization for:
- API communication with the backend
- Local data persistence
- State management with immutable data structures

We encountered issues with duplicate JSON serialization annotations causing build failures when using both `@JsonSerializable` and `@freezed` together.

**Key Requirements**:
- Type-safe JSON serialization/deserialization
- Immutable data classes
- Code generation for boilerplate reduction
- Support for complex nested structures
- Maintainable and testable code

---

## Decision Drivers

* **Build Stability**: Eliminate conflicting code generation
* **Type Safety**: Prevent runtime serialization errors
* **Developer Experience**: Reduce boilerplate code
* **Immutability**: Enforce immutable state management patterns
* **Pattern Matching**: Support exhaustive pattern matching with sealed classes
* **Testing**: Enable easy mocking and testing
* **Performance**: Efficient serialization/deserialization

---

## Considered Options

### Option 1: Manual JSON Serialization
**Approach**: Hand-write `toJson()` and `fromJson()` methods for each model.

**Pros**:
- No code generation dependencies
- Full control over serialization logic
- No build step required
- Easy to debug

**Cons**:
- High maintenance burden
- Prone to human error
- Verbose and repetitive code
- No compile-time safety for JSON keys
- Difficult to maintain consistency across large codebase

### Option 2: json_serializable Package Alone
**Approach**: Use `@JsonSerializable` annotation with `json_serializable` package.

**Pros**:
- Widely adopted in Flutter community
- Good documentation
- Flexible configuration options
- Generates clean serialization code

**Cons**:
- Requires manual implementation of `copyWith` methods
- No built-in immutability
- No union types or sealed classes
- Verbose class definitions
- Pattern matching not supported

### Option 3: Freezed Package (SELECTED)
**Approach**: Use `@freezed` annotation which automatically includes JSON serialization.

**Pros**:
- ✅ Immutability by default
- ✅ Automatic `copyWith` generation
- ✅ `toJson/fromJson` generated automatically
- ✅ Pattern matching with sealed classes
- ✅ Union types support
- ✅ Equality and `hashCode` implemented correctly
- ✅ `toString()` method generated
- ✅ Single annotation handles everything
- ✅ Integrates with `json_serializable` under the hood

**Cons**:
- Additional build dependency
- Slightly longer build times
- Generated files can be large
- Learning curve for advanced features

### Option 4: Freezed + Manual json_serializable (Anti-pattern)
**Approach**: Use both `@freezed` and `@JsonSerializable` together.

**Cons**:
- ❌ Causes build conflicts
- ❌ Duplicate code generation
- ❌ Increases build time unnecessarily
- ❌ Confusing for developers
- **Result**: This was causing our Phase 1 issues

---

## Decision Outcome

**Chosen option: "Option 3: Freezed Package"**

We standardized on using **Freezed exclusively** for all DTOs and domain entities.

### Implementation

**Standard DTO Template**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_name.freezed.dart';
part 'model_name.g.dart';

@freezed
class ModelName with _$ModelName {
  const factory ModelName({
    required String id,
    required String name,
    DateTime? createdAt,
  }) = _ModelName;

  factory ModelName.fromJson(Map<String, dynamic> json) =>
      _$ModelNameFromJson(json);
}
```

**Key Points**:
- Single `@freezed` annotation
- No `@JsonSerializable` annotation (handled by Freezed)
- Part files for generated code (`*.freezed.dart` and `*.g.dart`)
- Factory constructors for `fromJson`
- Immutable by default

### Migration Strategy

1. **Audit**: Identified all files using duplicate annotations
2. **Migration Script**: Created `scripts/migrate_dtos.dart` to automate fixes
3. **Standardization**: Updated all DTOs to use consistent Freezed template
4. **Build Configuration**: Configured `build.yaml` for proper code generation
5. **Documentation**: Created comprehensive guide in `docs/architecture/dto_audit.md`

---

## Consequences

### Positive

* ✅ **Build Stability**: Eliminated all code generation conflicts
* ✅ **Reduced Boilerplate**: 50-70% less code per model
* ✅ **Type Safety**: Compile-time errors for serialization issues
* ✅ **Immutability**: Prevents accidental state mutations
* ✅ **Pattern Matching**: Enhanced when/map methods for sealed classes
* ✅ **Testing**: Easy to create test fixtures and mock data
* ✅ **Consistency**: Single pattern across entire codebase
* ✅ **Documentation**: Generated `toString()` aids debugging

### Negative

* ⚠️ **Build Time**: Increased by ~10-15 seconds for full rebuilds
* ⚠️ **File Count**: Each model generates 2 additional files
* ⚠️ **Learning Curve**: New developers need to learn Freezed patterns
* ⚠️ **Dependency**: Additional package dependency

### Neutral

* Generated code is verbose but hidden in `.freezed.dart` and `.g.dart` files
* Requires running `flutter pub run build_runner build` after changes
* Build runner conflicts require `--delete-conflicting-outputs` flag

---

## Implementation Evidence

### Before (Anti-pattern with Conflicts)
```dart
@freezed
@JsonSerializable()  // ❌ Causes conflict
class UserDto with _$UserDto {
  // Duplicate serialization logic
}
```

### After (Correct Pattern)
```dart
@freezed  // ✅ Single annotation
class UserDto with _$UserDto {
  const factory UserDto({
    required String id,
    required String name,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
}
```

### Build Configuration (`build.yaml`)
```yaml
targets:
  $default:
    builders:
      freezed:
        enabled: true
        options:
          # Let Freezed handle JSON serialization
          union_key: 'type'
          union_value_case: 'pascal'
```

---

## Metrics

**After implementing this decision**:
- ✅ **117 unit tests** passing
- ✅ **Zero build errors** related to serialization
- ✅ **23 DTO files** migrated successfully
- ✅ **~1,500 lines** of boilerplate code eliminated
- ✅ **Clean `flutter analyze`** output

---

## Links and References

* [Freezed Package](https://pub.dev/packages/freezed)
* [json_serializable Package](https://pub.dev/packages/json_serializable)
* [DTO Audit Documentation](../architecture/dto_audit.md)
* [Migration Script](../../scripts/migrate_dtos.dart)
* [Clean Architecture Guide](../architecture/clean_architecture.md)

---

## Related Decisions

* ADR 002: State Management with Riverpod (immutable state from Freezed)
* ADR 003: Error Handling with Either Monad (Freezed union types)

---

## Notes

- This decision eliminated the primary cause of Phase 1 build failures
- Future DTOs must follow the Freezed-only pattern
- The migration script can detect and fix violations automatically
- All feature implementations (Notes, Projects, File Search, Chat, Translator) now follow this pattern

---

**Last Updated**: 2025-10-21  
**Review Date**: 2026-01-21 (Quarterly Review)
