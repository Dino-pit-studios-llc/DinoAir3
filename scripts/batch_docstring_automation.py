#!/usr/bin/env python3
"""
Batch Docstring Automation
Safely runs the docstring fixer on the entire codebase with safeguards.

This script:
1. Creates a backup of the current state
2. Runs the fixer on all files
3. Shows statistics
4. Allows rollback if needed
"""

import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def create_backup():
    """Create a backup of the current codebase."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = Path(f"backup_before_docstrings_{timestamp}")
    
    print(f"Creating backup in {backup_dir}...")
    
    # Files and directories to backup
    important_dirs = ['utils', 'tools', 'scripts', 'input_processing', 'rag', 'database', 'core_router']
    
    backup_dir.mkdir(exist_ok=True)
    
    for dir_name in important_dirs:
        src_dir = Path(dir_name)
        if src_dir.exists():
            dst_dir = backup_dir / dir_name
            shutil.copytree(src_dir, dst_dir, ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
            print(f"  ✓ Backed up {dir_name}")
    
    print(f"✓ Backup created in {backup_dir}")
    return backup_dir


def run_docstring_fixer(dry_run=False):
    """Run the docstring fixer on the entire codebase."""
    print("\n" + "="*60)
    print("RUNNING DOCSTRING AUTOMATION")
    print("="*60)
    
    # Run on major directories
    directories = ['utils', 'tools', 'scripts', 'input_processing', 'rag', 'database', 'core_router']
    
    total_files = 0
    total_docstrings = 0
    
    for directory in directories:
        if not Path(directory).exists():
            continue
            
        print(f"\nProcessing {directory}/...")
        cmd = ['python', 'scripts/simple_docstring_fixer.py']
        if dry_run:
            cmd.append('--dry-run')
        cmd.append(directory)
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            
            # Parse output for statistics
            output_lines = result.stdout.split('\n')
            for line in output_lines:
                if 'Files processed:' in line:
                    files = int(line.split(':')[1].strip())
                    total_files += files
                elif 'Docstrings added:' in line:
                    docstrings = int(line.split(':')[1].strip())
                    total_docstrings += docstrings
            
            # Show non-empty results
            if 'Would add' in result.stdout or 'Added' in result.stdout:
                relevant_lines = [line for line in output_lines 
                                if 'Would add' in line or 'Added' in line or '✓' in line]
                for line in relevant_lines[:10]:  # Limit output
                    print(f"  {line}")
                if len(relevant_lines) > 10:
                    print(f"  ... and {len(relevant_lines) - 10} more files")
        
        except subprocess.CalledProcessError as e:
            print(f"  Error processing {directory}: {e}")
            if e.stdout:
                print(f"  Stdout: {e.stdout}")
            if e.stderr:
                print(f"  Stderr: {e.stderr}")
    
    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)
    print(f"Total files processed: {total_files}")
    print(f"Total docstrings {'would be ' if dry_run else ''}added: {total_docstrings}")
    
    if dry_run:
        print("\n[DRY RUN] No files were modified")
    else:
        print(f"\n✓ Docstring automation completed successfully!")
    
    return total_files, total_docstrings


def main():
    """Main entry point."""
    print("DinoAir3 Docstring Automation Tool")
    print("="*40)
    
    # Check if we have the required scripts
    if not Path('scripts/simple_docstring_fixer.py').exists():
        print("Error: simple_docstring_fixer.py not found!")
        return 1
    
    # Ask user what they want to do
    print("\nOptions:")
    print("1. Dry run (show what would be changed)")
    print("2. Full run with backup")
    print("3. Full run without backup (dangerous!)")
    print("4. Exit")
    
    while True:
        choice = input("\nEnter your choice (1-4): ").strip()
        
        if choice == '1':
            print("\n--- DRY RUN MODE ---")
            run_docstring_fixer(dry_run=True)
            break
            
        elif choice == '2':
            print("\n--- FULL RUN WITH BACKUP ---")
            backup_dir = create_backup()
            files, docstrings = run_docstring_fixer(dry_run=False)
            
            if docstrings > 0:
                print(f"\nChanges made! Backup is available at: {backup_dir}")
                print("If you need to rollback, manually copy files back from the backup.")
            else:
                print("No changes made, backup can be deleted if desired.")
            break
            
        elif choice == '3':
            confirm = input("Are you sure you want to run without backup? (yes/no): ")
            if confirm.lower() == 'yes':
                print("\n--- FULL RUN WITHOUT BACKUP ---")
                run_docstring_fixer(dry_run=False)
                break
            else:
                print("Cancelled.")
                continue
                
        elif choice == '4':
            print("Exiting.")
            return 0
            
        else:
            print("Invalid choice. Please enter 1, 2, 3, or 4.")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())