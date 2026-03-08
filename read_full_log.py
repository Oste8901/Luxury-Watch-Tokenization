import os

path = r'\\wsl.localhost\Ubuntu\home\sman_olla\luxury-watch-tokenization-cre\cre-templates\starter-templates\stablecoin-ace-ccip\deploy_registry.txt'
try:
    with open(path, 'rb') as f:
        raw = f.read()
    
    # Try UTF-16LE decoding (PowerShell redirect)
    try:
        content = raw.decode('utf-16-le')
    except:
        try:
            content = raw.decode('utf-16')
        except:
            content = raw.decode('utf-8', errors='ignore')
            
    print("--- CONTENT START ---")
    print(content)
    print("--- CONTENT END ---")
except Exception as e:
    print(f"Error: {e}")
