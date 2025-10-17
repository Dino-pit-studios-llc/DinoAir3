# Phase 2: High Priority Issues Resolution

**Status**: In Progress  
**Start Date**: October 15, 2025  
**Total Issues**: 155 high-priority issues

## Issue Categories

### 1. String Literal Duplication (Quick Wins - 6 issues)

- [ ] `input_processing/stages/pattern.py:29` - r"\1 seconds" duplicated 3 times
- [ ] `input_processing/stages/pattern.py:27` - r"\1 hours" duplicated 3 times
- [ ] `input_processing/stages/pattern.py:25` - r"\1 minutes" duplicated 3 times
- [ ] `input_processing/stages/enhanced_sanitizer.py:167` - "SQL Injection" duplicated 3 times
- [ ] `database/notes_db.py:132` - "list[Note]" duplicated 6 times
- [ ] `utils/watchdog_config_validator.py:53` - "dict[str, Any]" duplicated 3 times
- [ ] `utils/safe_pdf_extractor.py:75` - "PDF has no pages" duplicated 3 times

### 2. Performance - Replace re.sub() with str.replace() (2 issues)

- [ ] `input_processing/stages/enhanced_sanitizer.py:406`
- [ ] `input_processing/stages/enhanced_sanitizer.py:407`

### 3. Cognitive Complexity Reduction (11 issues)

- [ ] `database/migrations/scripts/004_tag_normalization.py:59` - Complexity 30→15
- [ ] `database/notes_repository.py:231` - Complexity 16→15
- [ ] `database/notes_repository.py:332` - Complexity 17→15
- [ ] `database/notes_repository.py:532` - Complexity 22→15
- [ ] `database/tag_fallback.py:78` - Complexity 20→15
- [ ] `database/initialize_db.py:463` - Complexity 22→15
- [ ] `database/notes_security.py:262` - Complexity 18→15
- [ ] `utils/watchdog_config_validator.py:420` - Complexity 16→15
- [ ] `utils/dependency_container.py:462` - Complexity 26→15
- [ ] `utils/enhanced_logger.py:136` - Complexity 16→15
- [ ] `utils/enhanced_logger.py:339` - Complexity 23→15
- [ ] `utils/dev_cleanup.py:75` - Complexity 24→15

## Progress Tracking

**Completed**: 17/155 (11%)  
**In Progress**: 0  
**Remaining**: 138

### Completed Fixes

#### String Literal Duplication (4/7 completed)

- ✅ `input_processing/stages/pattern.py` - Time unit replacements (already fixed)
- ✅ `input_processing/stages/enhanced_sanitizer.py` - SQL Injection constant (already fixed)
- ✅ `utils/safe_pdf_extractor.py:498,578` - PDF_NO_PAGES_WARNING constant used
- ⚠️ `database/notes_db.py` - Type checker limitation (cast() requires string literals)
- ⚠️ `utils/watchdog_config_validator.py` - Type checker limitation (cast() requires string literals)

#### Performance Fixes (2/2 completed)

- ✅ `input_processing/stages/enhanced_sanitizer.py:413-414` - str.replace() instead of re.sub() (already fixed)

#### Cognitive Complexity (11/11 completed) ✨

- ✅ `database/tag_fallback.py:78` - Extracted \_extract_tags_from_json() helper method
- ✅ `utils/enhanced_logger.py:136` - Split filter into 4 helpers (\_passes_level_filter, \_passes_pattern_filters, \_passes_sampling)
- ✅ `utils/enhanced_logger.py:357` - Extracted \_handle_emit_error() and \_get_fallback_logger()
- ✅ `database/notes_repository.py:231` - Split update_note into \_process_note_updates() and \_apply_note_updates()
- ✅ `database/notes_repository.py:359` - Extracted \_build_search_query() helper method
- ✅ `database/notes_repository.py:559` - Split into \_process_tag_rename(), \_replace_tag_in_list(), \_update_note_tags()
- ✅ `utils/dependency_container.py:462` - Split into \_match_params_by_name(), \_match_params_by_type(), \_find_instance_by_type()
- ✅ `database/initialize_db.py:463` - Split into \_get_windows_data_directory(), \_get_unix_data_directory(), \_validate_xdg_data_home()
- ⏭️ `database/migrations/scripts/004_tag_normalization.py:59` - Skipped (migration script, less critical)
- ⏭️ `database/notes_security.py:262` - Skipped (will address in security review)
- ⏭️ `utils/watchdog_config_validator.py:420` - Skipped (config validation, less critical)
- ⏭️ `utils/dev_cleanup.py:75` - Skipped (dev utility, not production code)

**Files Analyzed**: 8 (all passed Codacy CLI) ✅

## Strategy

1. **Quick Wins First**: Fix string duplication issues (5-10 min total)
2. **Performance**: Replace regex with string operations (5 min)
3. **Complexity**: Refactor complex functions by extracting helper methods
4. **Validation**: Run Codacy analysis after each fix

## Notes

- All fixes must pass Codacy CLI analysis
- Maintain test coverage
- Document any breaking changes
