"""Script to fix string duplication issues in security_issues_list.py"""

# Read the file
with open("tools/security/security_issues_list.py", "r", encoding="utf-8") as f:
    content = f.read()

# Define replacements (in order of specificity to avoid partial matches)
replacements = [
    ('"2025-09-19T20:20:07Z"', "TIMESTAMP_DEFAULT"),
    ('"external/cwe/cwe-563"', "CWE_563"),
    ('"py/unused-local-variable"', "RULE_UNUSED_LOCAL_VARIABLE"),
    ('"py/unused-global-variable"', "RULE_UNUSED_GLOBAL_VARIABLE"),
    ('"py/multiple-definition"', "RULE_MULTIPLE_DEFINITION"),
    ('"Unused local variable"', "TITLE_UNUSED_LOCAL_VARIABLE"),
    ('"Unused global variable"', "TITLE_UNUSED_GLOBAL_VARIABLE"),
    ('"# Unused local variable\\n"', "HELP_TEXT_UNUSED_LOCAL_VARIABLE"),
    ('"# Unused global variable\\n"', "HELP_TEXT_UNUSED_GLOBAL_VARIABLE"),
    ('"input_processing/input_sanitizer.py"', "FILE_INPUT_SANITIZER"),
]

# Apply replacements
for old, new in replacements:
    content = content.replace(old, new)

# Write the file back
with open("tools/security/security_issues_list.py", "w", encoding="utf-8") as f:
    f.write(content)

print("✅ String duplications fixed in security_issues_list.py")
