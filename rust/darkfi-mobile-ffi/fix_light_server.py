with open('/Users/adi/GitHub/nighthawk-ios-wallet/rust/darkfi-mobile-ffi/src/lightwallet_client.rs', 'r') as f:
    lines = f.readlines()

new_lines = []
in_struct = False
for line in lines:
    if line.startswith('pub struct LightServerInfo {'):
        in_struct = True
        new_lines.append(line)
        continue
    
    if in_struct:
        if '}' in line:
            in_struct = False
            new_lines.append(line)
        elif 'backend_version' not in line and 'best_block_hash' not in line:
            new_lines.append(line)
    else:
        new_lines.append(line)

with open('/Users/adi/GitHub/nighthawk-ios-wallet/rust/darkfi-mobile-ffi/src/lightwallet_client.rs', 'w') as f:
    f.writelines(new_lines)
