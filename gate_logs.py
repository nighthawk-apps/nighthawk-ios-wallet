import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # We want to replace `print(...)` or `NSLog(...)` with `#if DEBUG \n print(...) \n #endif`
    # But only if it's on a line by itself (ignoring leading whitespace).
    
    lines = content.split('\n')
    new_lines = []
    
    # Simple state machine to not double-wrap if already wrapped
    in_debug = False
    
    for line in lines:
        if '#if DEBUG' in line:
            in_debug = True
        elif '#endif' in line:
            in_debug = False
            
        # Match print or NSLog at the start of the line (with optional whitespace)
        # Using a simple regex
        stripped = line.strip()
        if not in_debug and (stripped.startswith('print(') or stripped.startswith('NSLog(')):
            indent = line[:len(line) - len(line.lstrip())]
            new_lines.append(f"{indent}#if DEBUG")
            new_lines.append(line)
            new_lines.append(f"{indent}#endif")
        else:
            new_lines.append(line)
            
    with open(filepath, 'w') as f:
        f.write('\n'.join(new_lines))

sources_dir = 'modules/Sources'
for root, dirs, files in os.walk(sources_dir):
    for file in files:
        if file.endswith('.swift') and 'Generated' not in root and 'Tests' not in root:
            process_file(os.path.join(root, file))

print("Done gating logs.")
