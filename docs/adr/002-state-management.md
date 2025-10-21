# ADR 002: State Management with Riverpod

**Status**: Accepted  
**Date**: 2025-10-21  
**Deciders**: Development Team  
**Context**: Phase 3 - Architecture Standardization

---

## Context and Problem Statement

The DinoAir Flutter application requires a robust state management solution to handle:
- Asynchronous data fetching from backend APIs
- Complex feature interactions and dependencies
- Testable and maintainable state logic
- Global and local state management
- Dependency injection

**Key Requirements**:
- Type-safe dependency injection
- Easy testing and mocking
- Compile-time safety
- Support for async operations
- Provider composition and dependencies
- Auto-disposal of resources
- DevTools integration for debugging

---

## Decision Drivers

* **Type Safety**: Compile-time errors over runtime crashes
* **Testability**: Easy to test providers in isolation
* **Performance**: Efficient rebuilds and caching
* **Developer Experience**: Clear and concise syntax
* **Maintainability**: Easy to understand and refactor
* **Community Support**: Active maintenance and documentation
* **Flutter Best Practices**: Aligned with Flutter's ecosystem

---

## Considered Options

### Option 1: setState and InheritedWidget
**Approach**: Use Flutter's built-in state management.

**Pros**:
- No external dependencies
- Simple for small apps
- Well-documented

**Cons**:
- Verbose for complex state
- Difficult to test
- No dependency injection
- Poor separation of concerns
- Boilerplate-heavy

### Option 2: Provider Package
**Approach**: Use the original `provider` package.

**Pros**:
- Mature and stable
- Good documentation
- Community adoption
- Simple API

**Cons**:
- Runtime errors for missing providers
- No compile-time safety for dependencies
- Manual disposal management
- Limited async support
- Verbose provider setup

### Option 3: BLoC Pattern
**Approach**: Use `flutter_bloc` package for state management.

**Pros**:
- Well-defined architecture
- Good for complex state machines
- Strong typing
- Good DevTools support

**Cons**:
- Steep learning curve
- Verbose (lots of boilerplate)
- Overkill for simple features
- Event/State classes add complexity
- More files per feature

### Option 4: Riverpod (SELECTED)
**Approach**: Use `flutter_riverpod` package for state management.

**Pros**:
- ✅ Compile-time safe dependency injection
- ✅ No BuildContext needed for reading providers
- ✅ Auto-disposal and lifecycle management
- ✅ Excellent async support (`AsyncValue`, `FutureProvider`)
- ✅ Provider dependencies tracked at compile-time
- ✅ Easy testing with `ProviderContainer`
- ✅ Minimal boilerplate
- ✅ Family and AutoDispose modifiers
- ✅ DevTools integration
- ✅ Excellent documentation

**Cons**:
- Different API from original Provider
- Requires `ConsumerWidget` or `Consumer`
- Learning curve for advanced features

### Option 5: GetX
**Approach**: Use `get` package for state management and routing.

**Cons**:
- Uses global state (anti-pattern)
- Poor testability
- Runtime errors
- Encourages tight coupling
- Not aligned with Flutter best practices

---

## Decision Outcome

**Chosen option: "Option 4: Riverpod"**

We standardized on **Riverpod** (`flutter_riverpod` package) for all state management throughout the application.

### Implementation Patterns

#### 1. Repository Provider (Dependency Injection)
```dart
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final dio = ref.watch(backendDioProvider);
  final dataSource = NoteRemoteDataSourceImpl(client: dio, baseUrl: '/api/v1');
  return NoteRepositoryImpl(remoteDataSource: dataSource);
});
```

#### 2. Use Case Provider
```dart
final getAllNotesUseCaseProvider = Provider((ref) {
  return GetAllNotesUseCase(ref.watch(noteRepositoryProvider));
});
```

#### 3. Async Data Provider (with caching)
```dart
final notesListProvider = FutureProvider<List<NoteEntity>>((ref) async {
  final useCase = ref.watch(getAllNotesUseCaseProvider);
  final result = await useCase(NoParams());

  return result.fold(
    (failure) => throw Exception(failure.message),
    (notes) => notes,
  );
});
```

#### 4. State Notifier Provider (for mutable state)
```dart
class ChatInputNotifier extends Notifier<ChatInputState> {
  @override
  ChatInputState build() => const ChatInputState();

  void updateMessage(String message) {
    state = state.copyWith(message: message);
  }
}

final chatInputProvider = NotifierProvider<ChatInputNotifier, ChatInputState>(
  ChatInputNotifier.new,
);
```

#### 5. Consumer Widget (UI Layer)
```dart
class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);

    return notesAsync.when(
      data: (notes) => ListView(children: ...),
      loading: () => LoadingIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

---

## Architectural Integration

### Clean Architecture Alignment

Riverpod fits perfectly with our Clean Architecture layers:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  ┌───────────────────────────────────┐  │
│  │ ConsumerWidget / Consumer         │  │
│  │ ref.watch(provider)               │  │
│  └───────────────────────────────────┘  │
│                   │                      │
│                   ▼                      │
│  ┌───────────────────────────────────┐  │
│  │ State Providers                   │  │
│  │ (NotifierProvider, FutureProvider)│  │
│  └───────────────────────────────────┘  │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│         Domain Layer                    │
│  ┌───────────────────────────────────┐  │
│  │ Use Case Providers                │  │
│  │ (Business Logic)                  │  │
│  └───────────────────────────────────┘  │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│         Data Layer                      │
│  ┌───────────────────────────────────┐  │
│  │ Repository Providers              │  │
│  │ (Data Sources, API Clients)       │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Key Benefits for Clean Architecture

1. **Dependency Inversion**: Providers naturally enforce dependency injection
2. **Single Responsibility**: Each provider has one clear purpose
3. **Testability**: Easy to mock providers in tests
4. **Separation of Concerns**: Clear boundaries between layers

---

## Consequences

### Positive

* ✅ **Type Safety**: Compile-time errors for missing providers
* ✅ **Testability**: Easy to test with `ProviderContainer`
* ✅ **Auto-Disposal**: Resources automatically cleaned up
* ✅ **Async Support**: `AsyncValue` handles loading/error/data states elegantly
* ✅ **DevTools**: Excellent debugging experience
* ✅ **Performance**: Efficient rebuild optimization
* ✅ **Code Clarity**: Clear provider dependencies
* ✅ **No BuildContext**: Read providers anywhere (not just in build method)

### Negative

* ⚠️ **Learning Curve**: Different API from original Provider
* ⚠️ **Migration**: Existing code using `Provider` requires migration
* ⚠️ **ConsumerWidget**: Must use `ConsumerWidget` or `Consumer` wrapper

### Neutral

* Riverpod is maintained by the same author as the original Provider package
* Active community and frequent updates
* Aligned with Flutter's future direction

---

## Testing Strategy

### Unit Testing Providers

```dart
void main() {
  test('noteRepository should return notes', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(MockNoteRepository()),
      ],
    );

    final repository = container.read(noteRepositoryProvider);
    final result = await repository.getAllNotes();

    expect(result.isRight(), true);
  });
}
```

### Widget Testing

```dart
testWidgets('NotesListScreen shows loading indicator', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notesListProvider.overrideWith((ref) => AsyncValue.loading()),
      ],
      child: MaterialApp(home: NotesListScreen()),
    ),
  );

  expect(find.byType(LoadingIndicator), findsOneWidget);
});
```

---

## Implementation Evidence

### Provider Structure Across Features

All features follow consistent Riverpod patterns:

- **Notes Feature**: `notes/presentation/providers/` (5 providers)
- **Projects Feature**: `projects/presentation/providers/` (5 providers)
- **File Search Feature**: `file_search/presentation/providers/` (12 providers)
- **AI Chat Feature**: `ai_chat/presentation/providers/` (4 providers)
- **Translator Feature**: `translator/presentation/providers/` (5 providers)

### Standard Provider File Structure

```
features/
└── [feature_name]/
    └── presentation/
        └── providers/
            ├── [feature]_repository_provider.dart
            ├── [feature]_use_case_providers.dart
            ├── [feature]_state_provider.dart
            └── [feature]_list_provider.dart
```

---

## Metrics

**After implementing Riverpod**:
- ✅ **117 unit tests** passing (including provider tests)
- ✅ **Zero runtime provider errors**
- ✅ **~40 providers** across 7 features
- ✅ **Consistent patterns** throughout codebase
- ✅ **Easy to add new features** following established patterns

---

## Best Practices

### DO ✅

- Use `ConsumerWidget` for widgets that need to read providers
- Use `FutureProvider` for async data that doesn't change often
- Use `NotifierProvider` for mutable state that changes over time
- Use `Provider` for dependency injection (repositories, use cases)
- Use `.family` modifier for parameterized providers
- Use `.autoDispose` for providers that should be disposed when not used
- Override providers in tests for mocking

### DON'T ❌

- Don't use global state outside of providers
- Don't read providers in initState (use `ref.read` in callbacks instead)
- Don't forget to use `ConsumerWidget` when watching providers
- Don't create circular dependencies between providers
- Don't overuse state - prefer `FutureProvider` for read-only data

---

## Links and References

* [Riverpod Documentation](https://riverpod.dev/)
* [Flutter Riverpod Package](https://pub.dev/packages/flutter_riverpod)
* [Clean Architecture Guide](../architecture/clean_architecture.md)
* [Riverpod Best Practices](https://riverpod.dev/docs/essentials/first_request)

---

## Related Decisions

* ADR 001: JSON Serialization with Freezed (immutable state for Riverpod)
* ADR 003: Error Handling with Either Monad (works seamlessly with Riverpod)

---

## Notes

- All 117 unit tests pass using Riverpod's testing utilities
- DevTools integration helps debug provider dependencies
- Migration from original Provider to Riverpod was straightforward
- Provider code generation (with Riverpod Generator) considered for future

---

**Last Updated**: 2025-10-21  
**Review Date**: 2026-01-21 (Quarterly Review)
