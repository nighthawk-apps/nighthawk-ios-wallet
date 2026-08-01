import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    lines = content.split('\n')
    new_lines = []
    
    skip = False
    for line in lines:
        stripped = line.strip()
        # Remove #if DEBUG and #endif if they were added by us
        if stripped == '#if DEBUG':
            # lookahead to see if next line is print
            skip = True
            continue
        if skip and (stripped.startswith('print(') or stripped.startswith('NSLog(')):
            continue
        if skip and stripped == '#endif':
            skip = False
            continue
            
        if stripped.startswith('print(') or stripped.startswith('NSLog('):
            continue
        
        # also reset skip if it was True but we hit something else
        skip = False
        new_lines.append(line)
            
    with open(filepath, 'w') as f:
        f.write('\n'.join(new_lines))

sources_dir = 'modules/Sources'
for root, dirs, files in os.walk(sources_dir):
    for file in files:
        if file.endswith('.swift') and 'Generated' not in root and 'Tests' not in root:
            process_file(os.path.join(root, file))

print("Done stripping logs.")
