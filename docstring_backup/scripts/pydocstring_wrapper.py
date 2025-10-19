#!/usr/bin/env python3
"""
Automated Docstring Generator using pydocstring
Processes Python files to add missing docstrings using the professional pydocstring tool.
"""

import ast
import subprocess
import sys
from pathlib import Path
from typing import Any, List, Tuple


class PydocstringWrapper:
    """Wrapper for the pydocstring tool to batch process files."""
    
    def __init__(self, formatter: str = "google"):
        """Initialize the wrapper with a specific formatter.
        
        Args:
            formatter: The docstring formatter to use (google, numpy, reST)
        """
        self.formatter = formatter
        self.pydocstring_path = Path("C:/Users/kevin/AppData/Roaming/Python/Python314/Scripts/pydocstring.exe")
        
    def find_functions_without_docstrings(self, file_path: Path) -> List[Tuple[int, str]]:
        """Find functions/methods that don't have docstrings.
        
        Args:
            file_path: Path to the Python file to analyze
            
        Returns:
            List of tuples containing (line_number, function_name) for functions without docstrings
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            tree = ast.parse(content)
            functions_without_docstrings = []
            
            for node in ast.walk(tree):
                if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    # Check if function has a docstring
                    has_docstring = (
                        node.body and
                        isinstance(node.body[0], ast.Expr) and
                        isinstance(node.body[0].value, ast.Constant) and
                        isinstance(node.body[0].value.value, str)
                    )
                    
                    if not has_docstring:
                        functions_without_docstrings.append((node.lineno, node.name))
            
            return functions_without_docstrings
            
        except Exception as e:
            print(f"Error analyzing {file_path}: {e}")
            return []
    
    def generate_docstring(self, file_path: Path, line_number: int) -> str:
        """Generate a docstring for a function at the specified line.
        
        Args:
            file_path: Path to the Python file
            line_number: Line number where the function is defined
            
        Returns:
            Generated docstring content
        """
        try:
            result = subprocess.run([
                str(self.pydocstring_path),
                "--formatter", self.formatter,
                str(file_path),
                f"({line_number}, 0)"
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                # Extract just the docstring content, removing the position info
                output = result.stdout.strip()
                # Remove the first line which contains position info like "(16, 0)"
                lines = output.split('\\n')
                if lines and lines[0].strip().startswith('(') and lines[0].strip().endswith(')'):
                    # Remove position line and any empty lines at the start
                    content_lines = []
                    for line in lines[1:]:
                        if line.strip().startswith('"""') or content_lines:
                            content_lines.append(line)
                    return '\n'.join(content_lines).strip()
                return output
            print(f"Error generating docstring: {result.stderr}")
            return ""
                
        except subprocess.TimeoutExpired:
            print(f"Timeout generating docstring for {file_path}:{line_number}")
            return ""
        except Exception as e:
            print(f"Error running pydocstring: {e}")
            return ""
    
    def insert_docstring(self, file_path: Path, line_number: int, docstring: str) -> bool:
        """Insert a docstring into a file at the specified location.
        
        Args:
            file_path: Path to the Python file
            line_number: Line number where the function is defined
            docstring: Docstring content to insert
            
        Returns:
            True if successful, False otherwise
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # Find the function definition line and the next line to insert docstring
            func_line_idx = line_number - 1  # Convert to 0-based index
            
            # Find the line after the function definition (where docstring should go)
            insert_line_idx = func_line_idx + 1
            
            # Get the indentation of the function
            func_line = lines[func_line_idx]
            func_indent = len(func_line) - len(func_line.lstrip())
            docstring_indent = " " * (func_indent + 4)  # Add 4 spaces for docstring indentation
            
            # Format the docstring with proper indentation
            docstring_lines = docstring.split('\n')
            formatted_docstring = []
            
            for i, line in enumerate(docstring_lines):
                if i == 0:
                    formatted_docstring.append(f'{docstring_indent}"""{line}\n')
                elif i == len(docstring_lines) - 1:
                    formatted_docstring.append(f'{docstring_indent}"""\n')
                else:
                    formatted_docstring.append(f'{docstring_indent}{line}\n')
            
            # Insert the formatted docstring
            for i, docstring_line in enumerate(formatted_docstring):
                lines.insert(insert_line_idx + i, docstring_line)
            
            # Write the modified content back to the file
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(lines)
            
            return True
            
        except Exception as e:
            print(f"Error inserting docstring into {file_path}:{line_number}: {e}")
            return False
        """Generate a docstring for a function at the specified line.
        
        Args:
            file_path: Path to the Python file
            line_number: Line number where the function is defined
            
        Returns:
            Generated docstring content
        """
        try:
            result = subprocess.run([
                str(self.pydocstring_path),
                "--formatter", self.formatter,
                str(file_path),
                f"({line_number}, 0)"
            ], capture_output=True, text=True, timeout=30)
            
            if result.returncode == 0:
                return result.stdout.strip()
            print(f"Error generating docstring: {result.stderr}")
            return ""
                
        except subprocess.TimeoutExpired:
            print(f"Timeout generating docstring for {file_path}:{line_number}")
            return ""
        except Exception as e:
            print(f"Error running pydocstring: {e}")
            return ""
    
    def process_file(self, file_path: Path, dry_run: bool = True) -> dict:
        """Process a single file to add missing docstrings.
        
        Args:
            file_path: Path to the Python file to process
            dry_run: If True, only show what would be done without making changes
            
        Returns:
            Dictionary with processing results
        """
        print(f"\\nProcessing {file_path}...")
        
        functions_without_docstrings = self.find_functions_without_docstrings(file_path)
        
        if not functions_without_docstrings:
            print(f"  ✓ All functions in {file_path.name} already have docstrings")
            return {"file": str(file_path), "functions_processed": 0, "status": "complete"}
        
        print(f"  Found {len(functions_without_docstrings)} functions without docstrings:")
        
        for line_num, func_name in functions_without_docstrings:
            print(f"    - {func_name} (line {line_num})")
            
            if not dry_run:
                docstring = self.generate_docstring(file_path, line_num)
                if docstring:
                    print(f"      Generated docstring: {docstring[:50]}...")
                else:
                    print("      Failed to generate docstring")
        
        return {
            "file": str(file_path),
            "functions_processed": len(functions_without_docstrings),
            "status": "processed" if not dry_run else "dry_run"
        }
    
    def process_directory(self, directory: Path, pattern: str = "*.py", dry_run: bool = True) -> dict:
        """Process all Python files in a directory.
        
        Args:
            directory: Directory to process
            pattern: File pattern to match (default: *.py)
            dry_run: If True, only show what would be done
            
        Returns:
            Dictionary with overall processing results
        """
        python_files = list(directory.rglob(pattern))
        total_files = len(python_files)
        total_functions = 0
        
        print(f"Found {total_files} Python files to process...")
        
        results = []
        for file_path in python_files:
            try:
                result = self.process_file(file_path, dry_run)
                results.append(result)
                total_functions += result["functions_processed"]
            except Exception as e:
                print(f"Error processing {file_path}: {e}")
                results.append({
                    "file": str(file_path),
                    "functions_processed": 0,
                    "status": "error",
                    "error": str(e)
                })
        
        return {
            "total_files": total_files,
            "total_functions": total_functions,
            "results": results
        }


def main():
    """Main function to run the docstring automation."""
    if len(sys.argv) < 2:
        print("Usage: python pydocstring_wrapper.py <directory_or_file> [--no-dry-run]")
        print("Example: python pydocstring_wrapper.py utils/")
        return
    
    target = Path(sys.argv[1])
    dry_run = "--no-dry-run" not in sys.argv
    
    wrapper = PydocstringWrapper()
    
    if target.is_file():
        result = wrapper.process_file(target, dry_run)
        print(f"\\nProcessed {result['functions_processed']} functions")
    elif target.is_dir():
        result = wrapper.process_directory(target, dry_run=dry_run)
        print("\\nSummary:")
        print(f"  Files processed: {result['total_files']}")
        print(f"  Functions needing docstrings: {result['total_functions']}")
        print(f"  Mode: {'DRY RUN' if dry_run else 'ACTUAL PROCESSING'}")
    else:
        print(f"Error: {target} is not a valid file or directory")


if __name__ == "__main__":
    main()