"""Security issues list for verification and testing."""

# Constants
TIMESTAMP_DEFAULT = "2024-01-01T00:00:00Z"
RULE_UNUSED_LOCAL_VARIABLE = "unused-local-variable"
RULE_UNUSED_GLOBAL_VARIABLE = "unused-global-variable"
TITLE_UNUSED_LOCAL_VARIABLE = "Unused local variable"
TITLE_UNUSED_GLOBAL_VARIABLE = "Unused global variable"
HELP_TEXT_UNUSED_LOCAL_VARIABLE = ""
HELP_TEXT_UNUSED_GLOBAL_VARIABLE = ""
CWE_563 = "CWE-563"
FILE_INPUT_SANITIZER = "input_processing/sanitizer.py"

# Duplicate string literals converted to constants
MSG_LOCAL_VAR_UNUSED = "A local variable is defined (by an assignment) but never used.\n"
MSG_GLOBAL_VAR_UNUSED = (
    "A global (module-level) variable is defined (by an assignment) but never used and "
)

# Security issues list
security_issues = [
    {
        "id": 332,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_LOCAL_VARIABLE,
        "rule_name": RULE_UNUSED_LOCAL_VARIABLE,
        "title": TITLE_UNUSED_LOCAL_VARIABLE,
        "state": "open",
        "file_path": FILE_INPUT_SANITIZER,
        "line_start": 216,
        "line_end": 216,
        "column_start": 13,
        "column_end": 16,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/332",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_LOCAL_VARIABLE
        + MSG_LOCAL_VAR_UNUSED
        + "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to remove only the left hand side of "
        "the assignment in line 10.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "def write_random():\n"
        "    random_no = write_random_to_file()\n"
        '    print "A random number was written to random.txt"\n'
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/2/reference/simple_stmts.html#assignment-statements).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 331,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_LOCAL_VARIABLE,
        "rule_name": RULE_UNUSED_LOCAL_VARIABLE,
        "title": TITLE_UNUSED_LOCAL_VARIABLE,
        "state": "open",
        "file_path": FILE_INPUT_SANITIZER,
        "line_start": 211,
        "line_end": 211,
        "column_start": 13,
        "column_end": 22,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/331",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_LOCAL_VARIABLE
        + MSG_LOCAL_VAR_UNUSED
        + "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to remove only the left hand side of "
        "the assignment in line 10.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "def write_random():\n"
        "    random_no = write_random_to_file()\n"
        '    print "A random number was written to random.txt"\n'
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/2/reference/simple_stmts.html#assignment-statements).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 330,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_LOCAL_VARIABLE,
        "rule_name": RULE_UNUSED_LOCAL_VARIABLE,
        "title": TITLE_UNUSED_LOCAL_VARIABLE,
        "state": "open",
        "file_path": FILE_INPUT_SANITIZER,
        "line_start": 198,
        "line_end": 198,
        "column_start": 13,
        "column_end": 28,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/330",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_LOCAL_VARIABLE
        + MSG_LOCAL_VAR_UNUSED
        + "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to remove only the left hand side of "
        "the assignment in line 10.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "def write_random():\n"
        "    random_no = write_random_to_file()\n"
        '    print "A random number was written to random.txt"\n'
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/2/reference/simple_stmts.html#assignment-statements).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 329,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_LOCAL_VARIABLE,
        "rule_name": RULE_UNUSED_LOCAL_VARIABLE,
        "title": TITLE_UNUSED_LOCAL_VARIABLE,
        "state": "open",
        "file_path": FILE_INPUT_SANITIZER,
        "line_start": 192,
        "line_end": 192,
        "column_start": 13,
        "column_end": 30,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/329",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_LOCAL_VARIABLE
        + MSG_LOCAL_VAR_UNUSED
        + "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to remove only the left hand side of "
        "the assignment in line 10.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "def write_random():\n"
        "    random_no = write_random_to_file()\n"
        '    print "A random number was written to random.txt"\n'
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/2/reference/simple_stmts.html#assignment-statements).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 328,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_LOCAL_VARIABLE,
        "rule_name": RULE_UNUSED_LOCAL_VARIABLE,
        "title": TITLE_UNUSED_LOCAL_VARIABLE,
        "state": "open",
        "file_path": FILE_INPUT_SANITIZER,
        "line_start": 165,
        "line_end": 165,
        "column_start": 13,
        "column_end": 39,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/328",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_LOCAL_VARIABLE
        + MSG_LOCAL_VAR_UNUSED
        + "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to remove only the left hand side of "
        "the assignment in line 10.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "def write_random():\n"
        "    random_no = write_random_to_file()\n"
        '    print "A random number was written to random.txt"\n'
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/2/reference/simple_stmts.html#assignment-statements).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 327,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_LOCAL_VARIABLE,
        "rule_name": RULE_UNUSED_LOCAL_VARIABLE,
        "title": TITLE_UNUSED_LOCAL_VARIABLE,
        "state": "open",
        "file_path": FILE_INPUT_SANITIZER,
        "line_start": 153,
        "line_end": 153,
        "column_start": 13,
        "column_end": 31,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/327",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_LOCAL_VARIABLE
        + MSG_LOCAL_VAR_UNUSED
        + "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to remove only the left hand side of "
        "the assignment in line 10.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "def write_random():\n"
        "    random_no = write_random_to_file()\n"
        '    print "A random number was written to random.txt"\n'
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/2/reference/simple_stmts.html#assignment-statements).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 326,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_LOCAL_VARIABLE,
        "rule_name": RULE_UNUSED_LOCAL_VARIABLE,
        "title": TITLE_UNUSED_LOCAL_VARIABLE,
        "state": "open",
        "file_path": "tools/pseudocode_translator/config_tool.py",
        "line_start": 393,
        "line_end": 393,
        "column_start": 17,
        "column_end": 22,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/326",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_LOCAL_VARIABLE
        + MSG_LOCAL_VAR_UNUSED
        + "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to remove only the left hand side of "
        "the assignment in line 10.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "def write_random():\n"
        "    random_no = write_random_to_file()\n"
        '    print "A random number was written to random.txt"\n'
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/2/reference/simple_stmts.html#assignment-statements).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 325,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_LOCAL_VARIABLE,
        "rule_name": RULE_UNUSED_LOCAL_VARIABLE,
        "title": TITLE_UNUSED_LOCAL_VARIABLE,
        "state": "open",
        "file_path": "tools/pseudocode_translator/config_tool.py",
        "line_start": 375,
        "line_end": 375,
        "column_start": 17,
        "column_end": 21,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/325",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_LOCAL_VARIABLE
        + MSG_LOCAL_VAR_UNUSED
        + "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to remove only the left hand side of "
        "the assignment in line 10.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "def write_random():\n"
        "    random_no = write_random_to_file()\n"
        '    print "A random number was written to random.txt"\n'
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/2/reference/simple_stmts.html#assignment-statements).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 324,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_LOCAL_VARIABLE,
        "rule_name": RULE_UNUSED_LOCAL_VARIABLE,
        "title": TITLE_UNUSED_LOCAL_VARIABLE,
        "state": "open",
        "file_path": "tools/pseudocode_translator/models/codegen.py",
        "line_start": 152,
        "line_end": 152,
        "column_start": 9,
        "column_end": 20,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/324",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_LOCAL_VARIABLE
        + MSG_LOCAL_VAR_UNUSED
        + "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to remove only the left hand side of "
        "the assignment in line 10.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "def write_random():\n"
        "    random_no = write_random_to_file()\n"
        '    print "A random number was written to random.txt"\n'
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/2/reference/simple_stmts.html#assignment-statements).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 323,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_GLOBAL_VARIABLE,
        "rule_name": RULE_UNUSED_GLOBAL_VARIABLE,
        "title": TITLE_UNUSED_GLOBAL_VARIABLE,
        "state": "open",
        "file_path": "tools/pseudocode_translator/translator.py",
        "line_start": 146,
        "line_end": 146,
        "column_start": 1,
        "column_end": 19,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/323",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_GLOBAL_VARIABLE
        + MSG_GLOBAL_VAR_UNUSED
        + "is not explicitly made public by inclusion in the `__all__` list.\n"
        "\n"
        "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to only remove the left hand side of "
        "the assignment in line 9.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "random_no = write_random_to_file()\n"
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/reference/simple_stmts.html#assignment-statements), "
        "[The import "
        "statement](https:///docs.python.org/reference/simple_stmts.html#the-import-statement).\n"
        "* Python Tutorial: [Importing \\* from a "
        "package](https:///docs.python.org/2/tutorial/modules.html#importing-from-a-package).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 321,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_GLOBAL_VARIABLE,
        "rule_name": RULE_UNUSED_GLOBAL_VARIABLE,
        "title": TITLE_UNUSED_GLOBAL_VARIABLE,
        "state": "open",
        "file_path": "database/initialize_db.py",
        "line_start": 1120,
        "line_end": 1120,
        "column_start": 9,
        "column_end": 19,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/321",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_GLOBAL_VARIABLE
        + MSG_GLOBAL_VAR_UNUSED
        + "is not explicitly made public by inclusion in the `__all__` list.\n"
        "\n"
        "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to only remove the left hand side of "
        "the assignment in line 9.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "random_no = write_random_to_file()\n"
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/reference/simple_stmts.html#assignment-statements), "
        "[The import "
        "statement](https:///docs.python.org/reference/simple_stmts.html#the-import-statement).\n"
        "* Python Tutorial: [Importing \\* from a "
        "package](https:///docs.python.org/2/tutorial/modules.html#importing-from-a-package).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 320,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_GLOBAL_VARIABLE,
        "rule_name": RULE_UNUSED_GLOBAL_VARIABLE,
        "title": TITLE_UNUSED_GLOBAL_VARIABLE,
        "state": "open",
        "file_path": "tools/examples/adaptive_benchmark.py",
        "line_start": 136,
        "line_end": 136,
        "column_start": 5,
        "column_end": 12,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/320",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_GLOBAL_VARIABLE
        + MSG_GLOBAL_VAR_UNUSED
        + "is not explicitly made public by inclusion in the `__all__` list.\n"
        "\n"
        "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to only remove the left hand side of "
        "the assignment in line 9.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "random_no = write_random_to_file()\n"
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/reference/simple_stmts.html#assignment-statements), "
        "[The import "
        "statement](https:///docs.python.org/reference/simple_stmts.html#the-import-statement).\n"
        "* Python Tutorial: [Importing \\* from a "
        "package](https:///docs.python.org/2/tutorial/modules.html#importing-from-a-package).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
    {
        "id": 319,
        "type": "code_scanning",
        "severity": "note",
        "rule_id": RULE_UNUSED_GLOBAL_VARIABLE,
        "rule_name": RULE_UNUSED_GLOBAL_VARIABLE,
        "title": TITLE_UNUSED_GLOBAL_VARIABLE,
        "state": "open",
        "file_path": "tools/examples/adaptive_benchmark.py",
        "line_start": 135,
        "line_end": 135,
        "column_start": 5,
        "column_end": 11,
        "url": "https://github.com/dinoopitstudios/DinoAir/security/code-scanning/319",
        "created_at": TIMESTAMP_DEFAULT,
        "updated_at": TIMESTAMP_DEFAULT,
        "tags": [CWE_563, "maintainability", "quality", "useless-code"],
        "help_text": HELP_TEXT_UNUSED_GLOBAL_VARIABLE
        + MSG_GLOBAL_VAR_UNUSED
        + "is not explicitly made public by inclusion in the `__all__` list.\n"
        "\n"
        "It is sometimes necessary to have a variable which is not used. These unused "
        "variables should have distinctive names, to make it clear to readers of the code "
        "that they are deliberately not used. The most common conventions for indicating "
        "this are to name the variable `_` or to start the name of the variable with "
        "`unused` or `_unused`.\n"
        "\n"
        "The query accepts the following names for variables that are intended to be "
        "unused:\n"
        "\n"
        "* Any name consisting entirely of underscores.\n"
        "* Any name containing `unused`.\n"
        "* The names `dummy` or `empty`.\n"
        '* Any "special" name of the form `__xxx__`.\n'
        "Variables that are defined in a group, for example `x, y = func()` are handled "
        "collectively. If they are all unused, then this is reported. Otherwise they are "
        "all treated as used.\n"
        "\n"
        "\n"
        "## Recommendation\n"
        "If the variable is included for documentation purposes or is otherwise "
        "intentionally unused, then change its name to indicate that it is unused, "
        "otherwise delete the assignment (taking care not to delete right hand side if it "
        "has side effects).\n"
        "\n"
        "\n"
        "## Example\n"
        "In this example, the `random_no` variable is never read but its assignment has a "
        "side effect. Because of this it is important to only remove the left hand side of "
        "the assignment in line 9.\n"
        "\n"
        "\n"
        "```python\n"
        "import random\n"
        "\n"
        "def write_random_to_file():\n"
        "    no = random.randint(1, 10)\n"
        '    with open("random.txt", "w") as file:\n'
        "        file.write(str(no))\n"
        "    return no\n"
        "\n"
        "random_no = write_random_to_file()\n"
        "```\n"
        "\n"
        "## References\n"
        "* Python: [Assignment "
        "statements](https:///docs.python.org/reference/simple_stmts.html#assignment-statements), "
        "[The import "
        "statement](https:///docs.python.org/reference/simple_stmts.html#the-import-statement).\n"
        "* Python Tutorial: [Importing \\* from a "
        "package](https:///docs.python.org/2/tutorial/modules.html#importing-from-a-package).\n"
        "* Common Weakness Enumeration: "
        "[CWE-563](https://cwe.mitre.org/data/definitions/563.html).\n",
    },
]
