# Terminal setup notes

This repo uses WezTerm as the terminal emulator and Oh My Posh for prompt
rendering.

## Linux

WezTerm config should be managed through the dotfiles repo and linked into place
by the stow step.

Oh My Posh should be installed by the normal machine setup flow, not manually
pasted into `.bashrc` unless you are intentionally debugging outside the repo.

If you need a minimal manual test in Bash, this is the basic init command:

```bash
eval "$(oh-my-posh init bash)"
```

If you want to load a specific config file manually:

```bash
eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/base.json)"
```

After changing shell startup files, restart the shell or log out and back in.

## Windows

On Windows, Oh My Posh should be initialized from the PowerShell profile rather
than from Bash startup files.

If you keep a Windows bootstrap script, prefer storing it under `windows/`
instead of mixing it with Linux install scripts.
