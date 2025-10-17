# DinoAir Flutter Integration Development Plan

## Convert Crypto Dashboard to Drawer Feature & Add DinoAir Tools

### Executive Summary

Transform the existing standalone Flutter crypto dashboard into a comprehensive DinoAir control center with the crypto functionality as one drawer section among multiple productivity and AI-assisted tools. The app will provide a unified interface for notes management, project tracking, file search, AI chat, pseudocode translation, and market/portfolio tracking.

---

## Phase 1: Architecture Refactor (Foundation)

### 1.1 Navigation Structure Overhaul

**Objective:** Replace bottom navigation with drawer-based navigation to accommodate expanded feature set.

**Tasks:**

- [ ] Replace `lib/app/shell_scaffold.dart` bottom nav bar with an `AppDrawer` widget
- [ ] Create `lib/core/navigation/app_drawer.dart` with sections:
  - **Productivity** (Notes, Projects, File Search)
  - **AI Tools** (Chat Assistant, Pseudocode Translator)
  - **Crypto** (Market, Watchlist, Portfolio)
  - **System** (Settings, Health Monitor)
- [ ] Update `lib/app/router.dart` to use drawer navigation pattern
- [ ] Add app bar with menu icon to open drawer and context-aware titles

**Files to modify:**

- `lib/app/shell_scaffold.dart` → Convert to drawer-based shell
- `lib/app/router.dart` → Update route structure
- `lib/main.dart` → Update app title to "DinoAir Control Center"

**New files:**

- `lib/core/navigation/app_drawer.dart`
- `lib/core/navigation/drawer_sections.dart`
- `lib/core/navigation/navigation_item.dart`

### 1.2 Backend Integration Layer

**Objective:** Establish HTTP client infrastructure for DinoAir backend API.

**Tasks:**

- [ ] Create `lib/services/api/dio_client.dart` with base configuration
  - Base URL: `http://localhost:24801` (configurable)
  - Interceptors for logging, error handling, auth (future)
  - Timeout configuration (30s default)
- [ ] Create `lib/services/api/api_endpoints.dart` with route constants
- [ ] Create error handling models: `lib/core/errors/api_exception.dart`
- [ ] Add connectivity checking: `lib/services/connectivity_service.dart`

**New files:**

- `lib/services/api/dio_client.dart`
- `lib/services/api/api_endpoints.dart`
- `lib/core/errors/api_exception.dart`
- `lib/core/errors/error_handler.dart`
- `lib/services/connectivity_service.dart`

**Dependencies to add (pubspec.yaml):**

```yaml
dependencies:
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  pretty_dio_logger: ^1.3.1
```

---

## Phase 2: Notes Feature Implementation

### 2.1 Domain Layer

**Objective:** Define entities, repositories, and use cases for notes.

**Status:** ✅ **COMPLETED**

**Tasks:**

- [x] Create `lib/features/notes/domain/note_entity.dart`
  - Fields: id, title, content, tags, projectId, createdAt, updatedAt
- [x] Create `lib/features/notes/domain/note_repository.dart` (abstract)
  - Methods: createNote, readNote, updateNote, deleteNote, searchNotes, listNotes
- [x] Create use cases:
  - `create_note_use_case.dart`
  - `update_note_use_case.dart`
  - `delete_note_use_case.dart`
  - `search_notes_use_case.dart`
  - `list_notes_use_case.dart`

**File structure:**

```
lib/features/notes/
  domain/
    note_entity.dart ✅
    note_repository.dart ✅
    usecases/
      create_note_use_case.dart ✅
      update_note_use_case.dart ✅
      delete_note_use_case.dart ✅
      search_notes_use_case.dart ✅
      list_notes_use_case.dart ✅
```

### 2.2 Data Layer

**Objective:** Implement repository with DTOs and remote data source.

**Status:** ✅ **COMPLETED**

**Tasks:**

- [x] Create `lib/features/notes/data/note_dto.dart` with JSON serialization
- [x] Create `lib/features/notes/data/note_mapper.dart` (DTO ↔ Entity)
- [x] Create `lib/features/notes/data/note_remote_data_source.dart`
  - Use Dio client for API calls to `/api/v1/notes` endpoints
- [x] Create `lib/features/notes/data/note_repository_impl.dart`
  - Implements domain repository interface
  - Handles error mapping and data transformation

**File structure:**

```
lib/features/notes/
  data/
    note_dto.dart ✅
    note_mapper.dart ✅
    note_remote_data_source.dart ✅
    note_repository_impl.dart ✅
```

### 2.3 Presentation Layer

**Objective:** Build UI for notes management.

**Status:** ✅ **COMPLETED** (October 9, 2025)

**Tasks:**

- [x] Create providers:
  - `notes_list_provider.dart` (AsyncNotifierProvider for note list)
  - `note_detail_provider.dart` (family provider for individual notes)
  - `note_form_provider.dart` (for create/edit state)
- [x] Create screens:
  - `notes_list_screen.dart` (list view with search bar)
  - `note_detail_screen.dart` (view/edit note)
  - `note_create_screen.dart` (create new note form)
- [x] Create widgets:
  - `note_card_widget.dart` (list item)
  - `tag_chip_list_widget.dart` (display/edit tags)

**File structure:**

```
lib/features/notes/
  presentation/
    providers/
      notes_list_provider.dart ✅
      note_detail_provider.dart ✅
      note_form_provider.dart ✅
    screens/
      notes_list_screen.dart ✅
      note_detail_screen.dart ✅
      note_create_screen.dart ✅
    widgets/
      note_card_widget.dart ✅
      tag_chip_list_widget.dart ✅
```

### 2.4 Backend REST API

**Objective:** Expose notes functionality via REST endpoints.

**Status:** ✅ **COMPLETED** (October 9, 2025)

**Tasks:**

- [x] Create `API/routes/notes.py` with full CRUD endpoints
- [x] Register notes router in `API/app.py`
- [x] Wire to existing database layer (`database/notes_service.py`)

**Endpoints:**

- `POST /api/v1/notes` ✅
- `GET /api/v1/notes` ✅
- `GET /api/v1/notes/{note_id}` ✅
- `PUT /api/v1/notes/{note_id}` ✅
- `DELETE /api/v1/notes/{note_id}` ✅

**See:** `docs/notes-feature-implementation.md` for complete details.

---

## Phase 3: Projects Feature Implementation

### 3.1 Domain Layer

**Tasks:**

- [ ] Create `lib/features/projects/domain/project_entity.dart`
  - Fields: id, name, description, status, color, icon, parentProjectId, tags, createdAt
- [ ] Create `lib/features/projects/domain/project_repository.dart`
- [ ] Create use cases for CRUD operations and hierarchical navigation

### 3.2 Data Layer

**Tasks:**

- [ ] Create DTOs, mappers, remote data source
- [ ] Implement repository with `/api/v1/projects` endpoint integration

### 3.3 Presentation Layer

**Tasks:**

- [ ] Create providers for project list, tree view, form state
- [ ] Create screens:
  - `projects_list_screen.dart` (hierarchical tree view)
  - `project_detail_screen.dart`
  - `project_form_screen.dart`
- [ ] Create widgets:
  - `project_tree_widget.dart` (hierarchical display)
  - `project_card_widget.dart`
  - `project_status_indicator_widget.dart`

**File structure:** Mirror notes structure under `lib/features/projects/`

---

## Phase 4: File Search Feature Implementation

### 4.1 Domain Layer

**Tasks:**

- [ ] Create `lib/features/file_search/domain/file_search_result_entity.dart`
- [ ] Create `lib/features/file_search/domain/file_search_repository.dart`
- [ ] Create use cases for keyword search, directory management, indexing

### 4.2 Data Layer

**Tasks:**

- [ ] Create DTOs and remote data source for file search endpoints
- [ ] Implement repository with error handling for file operations

### 4.3 Presentation Layer

**Tasks:**

- [ ] Create search screen with keyword input and filters
- [ ] Create result list with file metadata display
- [ ] Add directory management UI (add/remove watched directories)
- [ ] File preview/open capability (system handler integration)

**File structure:** Under `lib/features/file_search/`

---

## Phase 5: AI Chat Feature Implementation

### 5.1 Domain Layer

**Tasks:**

- [ ] Create `lib/features/ai_chat/domain/chat_message_entity.dart`
  - Fields: id, role (user/assistant), content, timestamp, toolCalls
- [ ] Create `lib/features/ai_chat/domain/chat_session_entity.dart`
- [ ] Create `lib/features/ai_chat/domain/ai_chat_repository.dart`
- [ ] Create use cases:
  - `send_message_use_case.dart`
  - `get_chat_history_use_case.dart`
  - `clear_session_use_case.dart`

### 5.2 Data Layer

**Tasks:**

- [ ] Create DTOs for ChatRequest/ChatResponse (match backend schemas)
- [ ] Create `ai_chat_remote_data_source.dart` with `/ai/chat` POST integration
- [ ] Implement streaming support (if backend supports SSE/WebSocket in future)
- [ ] Create local data source for chat history persistence (SQLite/Hive)

### 5.3 Presentation Layer

**Tasks:**

- [ ] Create providers:
  - `chat_messages_provider.dart` (list of messages)
  - `chat_input_provider.dart` (text input state)
  - `chat_loading_provider.dart` (request in progress)
- [ ] Create screens:
  - `ai_chat_screen.dart` (main chat interface)
- [ ] Create widgets:
  - `message_bubble_widget.dart` (user vs assistant styling)
  - `typing_indicator_widget.dart`
  - `chat_input_widget.dart` (text field with send button)
  - `tool_call_display_widget.dart` (show function calls)

**File structure:** Under `lib/features/ai_chat/`

---

## Phase 6: Pseudocode Translator Feature

### 6.1 Domain Layer

**Tasks:**

- [ ] Create `lib/features/translator/domain/translation_request_entity.dart`
- [ ] Create `lib/features/translator/domain/translation_result_entity.dart`
- [ ] Create `lib/features/translator/domain/translator_repository.dart`
- [ ] Create use cases for translation with config options

### 6.2 Data Layer

**Tasks:**

- [ ] Create DTOs and remote data source
- [ ] Integrate with backend translator endpoints (confirm endpoint structure)
- [ ] Handle streaming responses if translator supports chunked output

### 6.3 Presentation Layer

**Tasks:**

- [ ] Create screens:
  - `translator_screen.dart` (input/output split view)
  - `translator_settings_screen.dart` (model/config selection)
- [ ] Create widgets:
  - `code_editor_widget.dart` (pseudocode input with syntax highlighting)
  - `translation_output_widget.dart` (Python output with copy button)
  - `translation_progress_widget.dart` (streaming indicator)

**File structure:** Under `lib/features/translator/`

---

## Phase 7: Health Monitor & System Tools

### 7.1 Health Monitor Feature

**Tasks:**

- [ ] Create `lib/features/health/domain/health_check_entity.dart`
- [ ] Create data source calling `/health` and extended health endpoints
- [ ] Create screen displaying:
  - Backend API status
  - Service registry health
  - LM Studio connectivity
  - Database status
  - Metrics summary

### 7.2 Settings Enhancement

**Tasks:**

- [ ] Expand existing settings to include:
  - Backend URL configuration (default: localhost:24801)
  - Theme preferences (already present)
  - Feature toggles (enable/disable crypto, notes, etc.)
  - About screen with version info

**File structure:** Under `lib/features/health/` and expand `lib/features/settings/`

---

## Phase 8: Crypto Dashboard Integration (Drawer Placement)

### 8.1 Reposition Crypto Features

**Objective:** Move existing crypto features into drawer navigation context.

**Tasks:**

- [ ] Update route paths in `router.dart`:
  - `/crypto/market`, `/crypto/watchlist`, `/crypto/portfolio`
- [ ] Add "Crypto" section in drawer with three sub-items
- [ ] Keep existing market/watchlist/portfolio screens unchanged initially
- [ ] Add top-level crypto landing screen (dashboard summary)

### 8.2 Crypto Dashboard Summary Screen

**Tasks:**

- [ ] Create `lib/features/crypto/presentation/screens/crypto_dashboard_screen.dart`
  - Show portfolio summary card
  - Show top watchlist items
  - Show market highlights
  - Navigation cards to Market/Watchlist/Portfolio
- [ ] Update crypto drawer items to navigate to this dashboard first

**File structure:**

```
lib/features/crypto/
  presentation/
    screens/
      crypto_dashboard_screen.dart
      (existing market_screen.dart, watchlist_screen.dart, portfolio_screen.dart)
```

---

## Phase 9: Unified Dashboard & Landing

### 9.1 Home Dashboard

**Objective:** Create a landing screen when app launches showing overview of all features.

**Tasks:**

- [ ] Create `lib/features/home/presentation/screens/home_dashboard_screen.dart`
  - Welcome message with user info (future: auth integration)
  - Quick access cards for each feature section
  - Recent notes/projects widgets
  - System health indicator
  - Crypto portfolio snapshot (if enabled)
- [ ] Set home dashboard as default route (`/`)
- [ ] Add "Home" item at top of drawer

### 9.2 Theming & Branding Consistency

**Tasks:**

- [ ] Update app theme to reflect DinoAir branding
  - Define primary/secondary colors
  - Typography scale
  - Card/container styling
- [ ] Create reusable widget library:
  - `lib/core/widgets/section_header.dart`
  - `lib/core/widgets/feature_card.dart`
  - `lib/core/widgets/empty_state_widget.dart`
  - `lib/core/widgets/error_widget.dart`
  - `lib/core/widgets/loading_indicator.dart`

---

## Phase 10: Testing & Polish

### 10.1 Unit Tests

**Tasks:**

- [ ] Write unit tests for all domain use cases
- [ ] Write repository tests with mocked data sources
- [ ] Write mapper tests (DTO ↔ Entity)
- [ ] Target 80%+ coverage for domain/data layers

**File structure:** Mirror `lib/` under `test/`

### 10.2 Widget Tests

**Tasks:**

- [ ] Test key screens with fake providers
- [ ] Test navigation flows (drawer → feature screens)
- [ ] Test form validation and error states

### 10.3 Integration Tests

**Tasks:**

- [ ] Create integration test suite for backend communication
- [ ] Mock backend with test server or use recorded responses
- [ ] Test end-to-end user workflows:
  - Create note → edit → delete
  - Search files → open result
  - Send chat message → receive response

### 10.4 Performance & UX Polish

**Tasks:**

- [ ] Add loading states for all async operations
- [ ] Add error recovery UI (retry buttons, error messages)
- [ ] Implement pull-to-refresh where appropriate
- [ ] Add skeleton loaders for list views
- [ ] Optimize image/icon assets
- [ ] Add animations for drawer open/close and screen transitions

---

## Phase 11: Advanced Features (Future Enhancements)

### 11.1 Offline Support

- [ ] Add local caching layer (Hive/Drift)
- [ ] Queue operations for sync when offline
- [ ] Display offline indicator in UI

### 11.2 Authentication & Multi-User

- [ ] Integrate auth endpoints if backend adds them
- [ ] Add login/logout flows
- [ ] Store user tokens securely (flutter_secure_storage)
- [ ] User profile screen

### 11.3 Real-Time Updates

- [ ] WebSocket integration for live updates
- [ ] Push notifications for important events
- [ ] Live chat streaming from AI

### 11.4 Export & Sharing

- [ ] Export notes/projects to PDF/Markdown
- [ ] Share functionality via platform share sheet
- [ ] Backup/restore user data

---

## Implementation Timeline Estimate

| Phase                                 | Duration      | Dependencies                        |
| ------------------------------------- | ------------- | ----------------------------------- |
| Phase 1: Architecture Refactor        | 1 week        | None                                |
| Phase 2: Notes Feature                | 1.5 weeks     | Phase 1                             |
| Phase 3: Projects Feature             | 1.5 weeks     | Phase 1, Phase 2 (similar patterns) |
| Phase 4: File Search Feature          | 1 week        | Phase 1                             |
| Phase 5: AI Chat Feature              | 2 weeks       | Phase 1 (complex due to streaming)  |
| Phase 6: Pseudocode Translator        | 1.5 weeks     | Phase 1, Phase 5 (similar patterns) |
| Phase 7: Health Monitor & System      | 1 week        | Phase 1                             |
| Phase 8: Crypto Dashboard Integration | 0.5 weeks     | Phase 1, existing crypto features   |
| Phase 9: Unified Dashboard & Landing  | 1 week        | All feature phases                  |
| Phase 10: Testing & Polish            | 2 weeks       | All phases                          |
| **Total**                             | **~13 weeks** | Sequential + parallel work possible |

---

## File Structure Overview (New Additions)

```
user_interface/User_Interface/lib/
  app/
    router.dart                          [MODIFY - drawer routes]
    shell_scaffold.dart                  [MODIFY - drawer shell]

  core/
    navigation/
      app_drawer.dart                    [NEW]
      drawer_sections.dart               [NEW]
      navigation_item.dart               [NEW]
    errors/
      api_exception.dart                 [NEW]
      error_handler.dart                 [NEW]
    widgets/                             [NEW]
      section_header.dart
      feature_card.dart
      empty_state_widget.dart
      error_widget.dart
      loading_indicator.dart

  services/
    api/
      dio_client.dart                    [NEW]
      api_endpoints.dart                 [NEW]
    connectivity_service.dart            [NEW]

  features/
    home/                                [NEW]
      presentation/
        screens/
          home_dashboard_screen.dart
        widgets/
          quick_access_card.dart
          recent_items_widget.dart

    notes/                               [NEW]
      domain/
        note_entity.dart
        note_repository.dart
        usecases/
          create_note_use_case.dart
          update_note_use_case.dart
          delete_note_use_case.dart
          search_notes_use_case.dart
          list_notes_use_case.dart
      data/
        note_dto.dart
        note_mapper.dart
        note_remote_data_source.dart
        note_repository_impl.dart
      presentation/
        providers/
          notes_list_provider.dart
          note_detail_provider.dart
          note_form_provider.dart
        screens/
          notes_list_screen.dart
          note_detail_screen.dart
          note_create_screen.dart
        widgets/
          note_card_widget.dart
          note_editor_widget.dart
          tag_chip_list_widget.dart

    projects/                            [NEW - similar structure to notes]
    file_search/                         [NEW]
    ai_chat/                             [NEW]
    translator/                          [NEW]
    health/                              [NEW]

    crypto/                              [EXISTING - minor modifications]
      presentation/
        screens/
          crypto_dashboard_screen.dart   [NEW]
          market_screen.dart             [EXISTING]
          watchlist_screen.dart          [EXISTING]
          portfolio_screen.dart          [EXISTING]

    market/                              [EXISTING - keep as is]
    watchlist/                           [EXISTING - keep as is]
    portfolio/                           [EXISTING - keep as is]
    settings/                            [EXISTING - expand]
      presentation/
        screens/
          backend_config_screen.dart     [NEW]
          feature_toggles_screen.dart    [NEW]

  main.dart                              [MODIFY - app title]
```

---

## Backend API Endpoints Reference

### Notes API

- `POST /api/v1/notes` - Create note
- `GET /api/v1/notes/{note_id}` - Read note
- `PUT /api/v1/notes/{note_id}` - Update note
- `DELETE /api/v1/notes/{note_id}` - Delete note
- `GET /api/v1/notes` - List notes (with filters)
- `POST /api/v1/notes/search` - Search notes by keywords

### Projects API

- `POST /api/v1/projects` - Create project
- `GET /api/v1/projects/{project_id}` - Read project
- `PUT /api/v1/projects/{project_id}` - Update project
- `DELETE /api/v1/projects/{project_id}` - Delete project
- `GET /api/v1/projects` - List projects

### File Search API

- `POST /api/v1/file_search/search` - Search files by keywords
- `GET /api/v1/file_search/info` - Get file info
- `POST /api/v1/file_search/index` - Add file to index
- `DELETE /api/v1/file_search/index` - Remove file from index
- `GET /api/v1/file_search/stats` - Get search statistics
- `POST /api/v1/file_search/directories` - Manage search directories

### AI Chat API

- `POST /ai/chat` - Send chat message (with optional tool calling)

### Health API

- `GET /health` - Basic health check
- `GET /api/v1/health` - Extended health check

### Translator API

_(To be confirmed based on backend implementation)_

- Likely under `/api/v1/translator` or similar

---

## Key Dependencies (pubspec.yaml additions)

```yaml
dependencies:
  # Existing
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0
  shared_preferences: ^2.2.0

  # New additions
  dio: ^5.4.0 # HTTP client
  pretty_dio_logger: ^1.3.1 # Request logging
  connectivity_plus: ^5.0.2 # Network connectivity
  freezed_annotation: ^2.4.1 # Immutable models
  json_annotation: ^4.8.1 # JSON serialization
  hive: ^2.2.3 # Local storage
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0 # Secure token storage
  intl: ^0.18.1 # Date formatting
  cached_network_image: ^3.3.0 # Image caching
  flutter_markdown: ^0.6.18 # Markdown rendering for notes
  uuid: ^4.3.0 # UUID generation

dev_dependencies:
  # Existing
  flutter_test:
    sdk: flutter

  # New additions
  build_runner: ^2.4.8
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  mockito: ^5.4.4 # Mocking for tests
  mocktail: ^1.0.2 # Alternative mocking
  integration_test:
    sdk: flutter
```

---

## Risk Assessment & Mitigation

### Risk 1: Backend API Instability

**Mitigation:**

- Build comprehensive error handling from day one
- Add retry logic with exponential backoff
- Provide graceful degradation (show cached data if available)

### Risk 2: Feature Scope Creep

**Mitigation:**

- Stick to phased implementation plan
- Mark advanced features (Phase 11) as optional/future work
- Regular progress reviews after each phase

### Risk 3: Performance Issues with Large Datasets

**Mitigation:**

- Implement pagination for all list views
- Use lazy loading and virtual scrolling
- Add search debouncing and request cancellation
- Profile performance regularly

### Risk 4: State Management Complexity

**Mitigation:**

- Follow strict Riverpod patterns (AsyncNotifier for async state)
- Keep providers focused and single-purpose
- Document provider dependencies clearly
- Use code generation (Freezed) for state classes

---

## Success Criteria

### Phase Completion Criteria

- [ ] All planned routes accessible via drawer
- [ ] Backend integration working for all features
- [ ] Error handling and loading states present
- [ ] No critical bugs in core workflows
- [ ] Unit test coverage >80% for domain/data layers
- [ ] Widget tests for key user journeys
- [ ] Performance acceptable (< 16ms frame render time)

### User Experience Goals

- [ ] Intuitive navigation via drawer
- [ ] Responsive UI (no blocking operations)
- [ ] Clear error messages with recovery actions
- [ ] Consistent theming across all features
- [ ] Smooth animations and transitions
- [ ] Accessible (screen reader support, sufficient contrast)

---

## Next Steps

1. **Review & Approve Plan:** Stakeholder sign-off on scope and timeline
2. **Set Up Project Board:** Create tickets for each task in phases
3. **Environment Setup:** Ensure Flutter SDK, backend running locally
4. **Phase 1 Kickoff:** Begin architecture refactor with drawer navigation
5. **Regular Check-ins:** Weekly progress reviews, adjust plan as needed

---

## Notes

- This plan assumes backend API endpoints follow RESTful conventions and match the tool function signatures discovered in the codebase.
- Streaming support for AI chat and translator will require additional investigation into backend capabilities (SSE, WebSocket, or chunked responses).
- Authentication integration is marked for Phase 11 but can be prioritized if backend adds auth sooner.
- Crypto features remain largely untouched; only navigation and context integration required.
- Testing infrastructure should be built incrementally alongside feature development, not left to Phase 10 entirely.

---

**Document Version:** 1.0
**Last Updated:** 2025-10-08
**Author:** Development Team
**Status:** Draft - Awaiting Approval
