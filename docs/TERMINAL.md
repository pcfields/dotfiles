I use (Wezterm)[https://wezfurlong.org/wezterm/], which is a powerful cross-platform terminal emulator and multiplexer.

I use (Oh My Posh)[https://ohmyposh.dev/], which is a prompt theme engine for any shell.

# Linux

(Install OhMyPosh on Linux)[https://ohmyposh.dev/docs/installation/linux]
Add it to `.bashrc` to make it the default shell.

```
eval "$(oh-my-posh init bash)"
```

Restart the computer or logout+login after making this change.
(Video explaining config changes)[https://youtu.be/9U8LCjuQzdc?si=Df9144mJpho5MRSA]
Create directory to store config `mkdir .config/ohmyposh` and `cd .config/ohmyposh`
Export base config file `oh-my-posh config export --output ./base.json`
Update `.bashrc` file to use config file

```
eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/base.json)"
```

# Windows

(Installation on Windows)[https://ohmyposh.dev/docs/installation/windows]
`Add it to profile.ps1` to make it the default shell
