import os

path = r'\\wsl.localhost\Ubuntu\home\sman_olla\luxury-watch-tokenization-cre\cre-templates\starter-templates\stablecoin-ace-ccip\deploy_registry.txt'
with open(path, 'rb') as f:
    content = f.read().decode('utf-16')
    print("Full Content:")
    print(content)
