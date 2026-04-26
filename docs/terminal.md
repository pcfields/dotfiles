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

## Shell configuration across terminals

The default shell is configured in `fish/.config/fish/config.fish` via setting the
`SHELL` environment variable. This runs early in the login process (via stow)
and ensures terminals that use the `SHELL` environment variable (e.g., Cosmic
Terminal, GNOME Terminal) use Fish.

WezTerm explicitly sets its own shell, so it works regardless of the SHELL
environment variable.

If a terminal does not respect SHELL, you can create a profile that launches
fish directly:

1. Right-click in the terminal > Profiles > New Profile
2. Set the command to `/usr/bin/fish` (or wherever fish is installed)
3. Set it as default

### Troubleshooting

If a terminal is still opening bash:

1. Verify SHELL is set: `echo $SHELL`
2. Check the terminal's config for profile settings
3. Try launching with explicit shell: `SHELL=/usr/bin/fish terminal-name`

## Windows

On Windows, Oh My Posh should be initialized from the PowerShell profile rather
than from Bash startup files.

If you keep a Windows bootstrap script, prefer storing it under `windows/`
instead of mixing it with Linux install scripts.
