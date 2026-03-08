import os
import re

path = r'\\wsl.localhost\Ubuntu\home\sman_olla\luxury-watch-tokenization-cre\cre-templates\starter-templates\stablecoin-ace-ccip\deploy_registry.txt'
with open(path, 'rb') as f:
    raw = f.read()
    try:
        content = raw.decode('utf-16')
    except:
        content = raw.decode('utf-8', errors='ignore')
    
    match = re.search(r'Deployed to: (0x[a-fA-F0-9]{40})', content)
    if match:
        addr = match.group(1)
        with open('REGISTRY_ADDR.txt', 'w') as out:
            out.write(addr)
        print("ADDR_SAVED")
