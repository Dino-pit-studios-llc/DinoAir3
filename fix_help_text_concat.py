"""Fix the help_text concatenation issues in security_issues_list.py"""

import re

# Read the file
with open("tools/security/security_issues_list.py", encoding="utf-8") as f:
    content = f.read()

# Fix the missing + operators where help text constants are followed by string literals
content = re.sub(
    r'("help_text": HELP_TEXT_UNUSED_LOCAL_VARIABLE)\n(\s+)"A local variable',
    r'\1\n\2+ "A local variable',
    content,
)

content = re.sub(
    r'("help_text": HELP_TEXT_UNUSED_GLOBAL_VARIABLE)\n(\s+)"A global',
    r'\1\n\2+ "A global',
    content,
)

# Write the file back
with open("tools/security/security_issues_list.py", "w", encoding="utf-8") as f:
    f.write(content)

print("✅ Fixed help_text concatenation in security_issues_list.py")
