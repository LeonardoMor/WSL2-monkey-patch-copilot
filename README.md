# WSL2 Copilot and Chat Workarounds
Beware, these are probably not very safe.

I got weird errors when using Copilot Chat from repos on WSL2 on Windows 11. See https://github.com/microsoft/vscode-copilot-release/issues/439

Installing VS Code Insiders and the latest pre-release versions of Copilot and Copilot Chat gives better error messages, such as
```
  2023-10-27T23:21:56.713Z [ERROR] [extension] Error on conversation request: (SR) self-signed certificate in certificate chain
```

The scripts below go around this problem. There's no need to run the two. It's probably better if you use `WSL2-js-allow-selfsigned.sh`.

Use one or the other.

## WSL2-monkey-patch-copilot.sh
This is very unsafe. Very much based on: https://stackoverflow.com/a/72136715/7830232


## WSL2-js-allow-selfsigned.sh
Roughly: https://sidd.io/2023/01/github-copilot-self-signed-cert-issue/
