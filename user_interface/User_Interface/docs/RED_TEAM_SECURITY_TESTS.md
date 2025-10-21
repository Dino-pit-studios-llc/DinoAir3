# Red Team Security Testing Documentation

## Overview

Comprehensive security test coverage for all security utilities in the DinoAir3 Flutter application. Tests are organized by attack vector for easy security auditing and penetration testing validation.

## Test Organization

```
test/
├── core/
│   ├── config/
│   │   └── env_config_test.dart          (35 tests - Environment & API security)
│   ├── utils/
│   │   └── sanitizer_test.dart           (60+ tests - Input sanitization)
│   └── security/
│       └── file_access_security_test.dart (70+ tests - File system security)
```

## Security Coverage Matrix

| Attack Vector | EnvConfig | InputSanitizer | FileAccessSecurity |
|--------------|-----------|----------------|-------------------|
| SQL Injection | ✅ | ✅ | N/A |
| XSS (Cross-Site Scripting) | ✅ | ✅ | N/A |
| CRLF Injection | ✅ | ✅ | N/A |
| Command Injection | ✅ | ✅ | N/A |
| Path Traversal | ✅ | ✅ | ✅ |
| SSRF (Server-Side Request Forgery) | ✅ | N/A | N/A |
| Credential Injection | ✅ | N/A | N/A |
| Unicode/Homograph Attacks | ✅ | ✅ | ✅ |
| Header Injection | ✅ | N/A | N/A |
| Information Disclosure | ✅ | ✅ | N/A |
| Directory Traversal | N/A | ✅ | ✅ |
| Blacklist Bypass | N/A | N/A | ✅ |
| Whitelist Bypass | N/A | N/A | ✅ |
| File Extension Validation | N/A | ✅ | ✅ |
| LDAP Injection | N/A | ✅ | N/A |
| XXE (XML External Entity) | N/A | ✅ | N/A |
| Template Injection | N/A | ✅ | N/A |

## Test Files

### 1. EnvConfig Security Tests (`test/core/config/env_config_test.dart`)

**Purpose**: Validate environment configuration and API key security

**Test Groups** (35 tests total):
- **API Key Length Validation** (5 tests)
  - Minimum 16 character enforcement
  - Rejection of short/empty keys
  - Support for long keys (128+ chars)
  
- **API Key Injection Prevention** (6 tests)
  - SQL injection patterns (DROP, DELETE, --, etc.)
  - CRLF injection (\r\n)
  - Command injection (`, $)
  - Script tags (<script>, javascript:)
  - Safe alphanumeric patterns with dashes/dots
  
- **URL Protocol Validation** (6 tests)
  - HTTPS enforcement for production
  - HTTP allowed for localhost only
  - Rejection of dangerous protocols (ftp, file, javascript)
  
- **URL Injection Attacks** (4 tests)
  - Credential injection via @ symbol
  - Unicode homograph attacks (Cyrillic characters)
  - Trailing whitespace handling
  - Empty URL handling
  
- **Header Injection Prevention** (2 tests)
  - Safe Authorization headers
  - Proper Bearer token formatting
  
- **Sanitized Logging** (3 tests)
  - Redaction of sensitive query parameters (api_key, token, password, secret)
  - Preservation of safe parameters
  - Multiple sensitive parameter handling
  
- **Runtime Update Security** (3 tests)
  - URL update validation
  - API key update validation
  - Valid update acceptance
  
- **Edge Cases** (3 tests)
  - Very long URLs (1900+ chars)
  - URL fragments
  - Query parameters
  
- **SSRF Prevention** (3 tests)
  - Localhost/127.0.0.1 allowed in debug mode
  - Private IP ranges (192.168.x.x) allowed in debug mode
  - Blocked in release mode for production security

**Key Attack Scenarios Tested**:
```dart
// SQL Injection in API keys
'DROP-TABLE-users--' // ✅ Blocked

// CRLF Injection
'valid-key-123\r\nAuthorization: Bearer evil' // ✅ Blocked

// Command Injection
'valid`whoami`key' // ✅ Blocked

// Credential Injection
'https://attacker@api.example.com' // ✅ Blocked

// SSRF Attempts
'http://127.0.0.1/admin' // ✅ Blocked in release, allowed in debug
```

### 2. InputSanitizer Security Tests (`test/core/utils/sanitizer_test.dart`)

**Purpose**: Validate all input sanitization methods against injection attacks

**Test Groups** (60+ tests total):
- **Text Sanitization** (15 tests)
  - Control character removal (null bytes, CRLF, tabs)
  - Length limiting (10,000 char default)
  - Whitespace normalization
  - Newline preservation options
  
- **Filename Sanitization** (20 tests)
  - Path traversal prevention (../, ..\\)
  - Windows reserved names (CON, PRN, AUX, COM1-9, LPT1-9)
  - Special character removal (<>:"|?*)
  - Null byte injection
  - Absolute path blocking
  
- **Path Sanitization** (10 tests)
  - Directory traversal attacks
  - Encoded traversal (%2e%2e%2f)
  - Double-encoded traversal
  - Null byte injection
  - Path normalization
  
- **Email Sanitization** (10 tests)
  - Format validation
  - Injection attempts (CRLF)
  - Case normalization
  - Length limits (254 chars per RFC 5321)
  
- **URL Sanitization** (10 tests)
  - Protocol validation (http/https only)
  - Dangerous protocol rejection (javascript:, data:, file:, vbscript:)
  - Malformed URL handling
  
- **SQL Injection Prevention** (3 tests)
  - SQL keyword removal (DROP, DELETE, INSERT, UNION, SELECT)
  - Comment sequence removal (--, /*, */)
  - Stored procedure blocking (xp_, sp_)
  
- **XSS Prevention** (4 tests)
  - HTML entity escaping (&, <, >, ", ', /)
  - Script tag handling
  
- **Search Query Sanitization** (3 tests)
  - SQL pattern removal
  - Length limiting (500 chars)
  - Whitespace normalization
  
- **Tag Sanitization** (5 tests)
  - Lowercase normalization
  - Space-to-hyphen conversion
  - Special character removal
  - Length limiting (50 chars)
  
- **File Extension Validation** (4 tests)
  - Allowed extensions (documents, images, code)
  - Dangerous extension blocking (exe, dll, bat, sh)
  
- **Red Team Combined Attacks** (4 tests)
  - Polyglot injection attacks
  - LDAP injection (*)(uid=*))(|(uid=*)
  - XXE (XML External Entity) injection
  - Template injection ({{7*7}})

**Key Attack Scenarios Tested**:
```dart
// Path Traversal
'../../../etc/passwd' // ✅ Blocked
'%2e%2e%2f' // ✅ Blocked (encoded)

// XSS
'<script>alert("XSS")</script>' // ✅ Escaped to &lt;script&gt;...

// SQL Injection
"'; DROP TABLE users; --" // ✅ SQL keywords removed

// XXE Injection
'<?xml version="1.0"?><!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>' // ✅ DOCTYPE/ENTITY removed

// Windows Reserved Names
'CON', 'PRN', 'AUX', 'COM1' // ✅ Prefixed with underscore

// Null Byte Injection
'/safe/path\x00../../etc/passwd' // ✅ Null bytes removed
```

### 3. FileAccessSecurity Security Tests (`test/core/security/file_access_security_test.dart`)

**Purpose**: Validate file system access controls and directory security

**Test Groups** (70+ tests total):
- **Initialization** (5 tests)
  - Default settings
  - Custom allowed extensions
  - Custom whitelisted directories
  - Extension normalization
  - Directory sanitization on init
  
- **Blacklist Enforcement** (7 tests)
  - /etc, /sys, /proc, /dev, /root blocking
  - C:\Windows\System32 blocking
  - C:\Program Files blocking
  
- **Path Traversal Prevention** (5 tests)
  - ../ sequences
  - ..\ sequences (Windows)
  - Multiple traversal attempts
  - Null byte injection
  - Encoded traversal
  
- **Whitelist Enforcement** (5 tests)
  - Whitelisted path access
  - Non-whitelisted blocking
  - Subdirectory inheritance
  - Similar path differentiation (/safe vs /safehouse)
  - Case-insensitive matching
  
- **Extension Validation** (7 tests)
  - Whitelisted extension acceptance
  - Non-whitelisted blocking
  - Dangerous executable blocking (exe, dll, so)
  - Case-insensitive extension checks
  - Leading dot handling
  - Files without extensions
  
- **Directory Validation** (5 tests)
  - Whitelisted directory access
  - Blacklisted directory blocking
  - Subdirectory access
  - Non-whitelisted blocking
  - No-whitelist behavior
  
- **Whitelist Management** (5 tests)
  - Adding directories
  - Removing directories
  - Blacklisted directory rejection
  - Whitelist clearing
  - Path sanitization on add
  
- **Extension Management** (4 tests)
  - Adding extensions
  - Removing extensions
  - Extension normalization
  - Empty extension rejection
  
- **Edge Cases** (7 tests)
  - Null path handling
  - Empty path handling
  - Very long paths (4096+ chars)
  - Multiple dots in filenames
  - Trailing slashes
  
- **Batch Operations** (2 tests)
  - Multiple path validation
  - Empty list handling
  
- **Security Status** (2 tests)
  - Status reporting
  - Whitelist active detection
  
- **Red Team Combined Attacks** (7 tests)
  - Case variation bypass attempts
  - Path traversal whitelist bypass
  - Double extension attacks (.exe.txt)
  - Unicode path attacks
  - Mixed separator attacks
  - Homograph attacks in paths
  - TOCTOU (Time-of-Check Time-of-Use) conceptual
  
- **Platform-Specific Attacks** (3 tests)
  - Windows UNC paths (\\\\server\\share)
  - Windows alternate data streams (file.txt:hidden)
  - Unix hidden files (.malware.txt)

**Key Attack Scenarios Tested**:
```dart
// Path Traversal
'/safe/../etc/passwd' // ✅ Blocked by sanitization
'C:\\safe\\..\\Windows\\System32' // ✅ Blocked

// Blacklist Bypass
'/ETC/passwd' // ✅ Blocked (case-insensitive)
'/etc/PASSWD' // ✅ Blocked

// Whitelist Bypass
'/safehouse/file.txt' // ✅ Blocked (not under /safe)

// Double Extension
'/safe/malware.exe.txt' // ✅ Checks .txt (last extension)
'/safe/file.txt.exe' // ✅ Blocked (.exe not allowed)

// Unicode Attacks
'/sаfe/file.txt' // ✅ Blocked (Cyrillic 'a' doesn't match /safe)

// Windows UNC
'\\\\evil-server\\share\\file.txt' // ✅ Sanitized or rejected

// Windows ADS
'C:\\safe\\file.txt:hidden' // ✅ Colon removed by sanitizer
```

## Running Security Tests

### Run All Security Tests
```bash
cd user_interface/User_Interface

# Run all security tests
flutter test test/core/

# With coverage
flutter test --coverage test/core/

# Verbose output
flutter test --reporter expanded test/core/
```

### Run Individual Test Suites
```bash
# EnvConfig tests (35 tests)
flutter test test/core/config/env_config_test.dart

# InputSanitizer tests (60+ tests)
flutter test test/core/utils/sanitizer_test.dart

# FileAccessSecurity tests (70+ tests)
flutter test test/core/security/file_access_security_test.dart
```

### Run Specific Test Groups
```bash
# Run only SQL injection tests
flutter test --plain-name "SQL Injection"

# Run only path traversal tests
flutter test --plain-name "Path Traversal"

# Run only red team tests
flutter test --plain-name "Red Team"
```

## Integration with Penetration Testing Tools

### Recommended Tools

**1. Metasploit Framework**
- **Use**: Module development for exploit testing
- **Integration**: Use test cases to validate exploit payloads are blocked
- **Example**: `use exploit/multi/handler` with test payloads from our test suites

**2. OWASP ZAP (Zed Attack Proxy)**
- **Use**: Automated vulnerability scanning
- **Integration**: Configure ZAP to test API endpoints with our attack vectors
- **Example**: Import test payloads as fuzzing vectors

**3. Burp Suite**
- **Use**: Manual penetration testing and payload crafting
- **Integration**: Use test cases as baseline for custom payload development
- **Example**: Test SQL injection payloads from sanitizer tests

**4. Promptfoo (LLM Security Testing)**
- **Use**: Test LLM prompt injection and jailbreaking
- **Integration**: Validate API key sanitization against LLM-specific attacks
- **Example**: Test prompt injection payloads: "Ignore previous instructions..."

**5. Garak (LLM Vulnerability Scanner)**
- **Use**: Automated LLM red teaming
- **Integration**: Test EnvConfig against Garak's probe set
- **Example**: Run Garak probes against API key validation

**6. PyRIT (Python Risk Identification Tool for AI)**
- **Use**: AI red teaming automation
- **Integration**: Use PyRIT to generate attack payloads for our sanitizers
- **Example**: Generate adversarial inputs for InputSanitizer

**7. Nmap**
- **Use**: Network vulnerability scanning
- **Integration**: Validate SSRF protection by attempting internal network scans
- **Example**: Test if URLs like `http://192.168.1.1/admin` are blocked

**8. Wireshark**
- **Use**: Network traffic analysis
- **Integration**: Verify sanitized logging doesn't leak secrets in network traffic
- **Example**: Capture API requests and verify `[REDACTED]` appears in logs

## Security Testing Checklist

### Pre-Release Security Audit

- [ ] All 165+ security tests passing
- [ ] Code coverage > 95% for security utilities
- [ ] No analyzer warnings in security code
- [ ] Manual penetration testing completed
- [ ] OWASP Top 10 validation
- [ ] Third-party security audit (if applicable)

### Test Maintenance

- [ ] Update tests when new attack vectors discovered
- [ ] Review tests after security incidents
- [ ] Sync tests with OWASP/SANS Top 25
- [ ] Annual security test review
- [ ] Add tests for CVEs affecting similar systems

### Continuous Integration

```yaml
# Example GitHub Actions workflow
name: Security Tests
on: [push, pull_request]
jobs:
  security-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test test/core/ --coverage
      - run: lcov --list coverage/lcov.info
      - run: |
          # Fail if security test coverage < 95%
          coverage=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}' | sed 's/%//')
          if (( $(echo "$coverage < 95" | bc -l) )); then
            echo "Security test coverage too low: $coverage%"
            exit 1
          fi
```

## Red Team Attack Vectors Reference

### OWASP Top 10 (2021) Coverage

1. **A01:2021 - Broken Access Control** ✅
   - FileAccessSecurity: whitelist/blacklist enforcement
   - Path traversal prevention
   - Directory access controls

2. **A02:2021 - Cryptographic Failures** ✅
   - EnvConfig: HTTPS enforcement
   - Sensitive data redaction in logs
   - API key validation

3. **A03:2021 - Injection** ✅
   - InputSanitizer: SQL, XSS, command, LDAP injection prevention
   - EnvConfig: Header injection, CRLF injection blocking

4. **A04:2021 - Insecure Design** ✅
   - Security-by-design architecture
   - Fail-safe defaults
   - Input validation at all boundaries

5. **A05:2021 - Security Misconfiguration** ✅
   - EnvConfig: Secure defaults
   - Debug mode safety checks
   - Configuration validation

6. **A06:2021 - Vulnerable Components** ⚠️
   - Dependency scanning (manual process)
   - Regular Flutter/Dart SDK updates

7. **A07:2021 - Identification/Authentication Failures** ✅
   - API key validation (16+ chars, no injection)
   - Credential injection prevention

8. **A08:2021 - Software/Data Integrity Failures** ✅
   - File extension validation
   - Path sanitization
   - Input integrity checks

9. **A09:2021 - Security Logging/Monitoring Failures** ✅
   - Sanitized logging with secret redaction
   - Access attempt logging (FileAccessSecurity)
   - Debug-safe logging

10. **A10:2021 - Server-Side Request Forgery (SSRF)** ✅
    - EnvConfig: Private IP blocking in release mode
    - URL validation
    - Localhost restrictions

## Contributing New Security Tests

When adding new security tests:

1. **Identify the attack vector** (e.g., SQL injection, XSS, path traversal)
2. **Research real-world exploits** (CVEs, OWASP, security blogs)
3. **Create test cases** following existing patterns
4. **Document the attack** in test comments
5. **Verify blocking** with actual attack payloads
6. **Update this document** with new coverage

Example test template:
```dart
test('blocks [ATTACK_NAME] attack', () {
  // Attack vector: [DESCRIPTION]
  // Reference: [CVE/OWASP/URL]
  final maliciousInput = '[ATTACK_PAYLOAD]';
  
  expect(
    () => SecurityUtility.validate(maliciousInput),
    throwsArgumentError,
  );
});
```

## Security Contact

For security vulnerabilities discovered through testing:
- **DO NOT** create public GitHub issues
- Contact: [Security Contact Email]
- Include: Test case demonstrating the vulnerability
- Expected response: 48 hours acknowledgment

## References

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- SANS Top 25: https://www.sans.org/top25-software-errors/
- CWE Top 25: https://cwe.mitre.org/top25/
- Flutter Security Best Practices: https://flutter.dev/security
- Dart Security: https://dart.dev/guides/libraries/security

---

**Last Updated**: ${DateTime.now().toString().split(' ')[0]}
**Test Count**: 165+ security tests
**Coverage**: EnvConfig (35), InputSanitizer (60+), FileAccessSecurity (70+)
**Status**: ✅ All tests passing
