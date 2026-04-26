# Linux Clean system (re)install guide

This document captures the prerequisites and step-by-step process for getting from a fresh Pop!_OS install to the point where the dotfiles repository can be cloned and the install scripts can be run.

## Scope

This guide covers the very first stage after installing Pop!_OS:

- Getting online.
- Accessing email and the password manager.
- Creating a new SSH key for GitHub.
- Adding the SSH key to GitHub.
- Cloning the dotfiles repository over SSH.

GitHub documents the SSH flow as: generate a new key pair locally, add the public key to the GitHub account, and then connect or clone using SSH.

## Prerequisites

The following items are required before the scripted install stage can begin:

- A completed Linux(Pop!_OS) installation.
- A working internet connection.
- Access to Wi‑Fi credentials if using wireless networking.
- Access to the password manager so account credentials can be retrieved.
- Access to email for login links, 2FA codes, or verification codes.
- Access to the GitHub account where the SSH key will be added.

Some of these prerequisites are inherently manual because they depend on interactive login, credentials, and web-based account flows rather than local machine state.

## Manual prerequisites

These steps should stay manual:

1. Connect to Wi‑Fi.
2. Open browser(Firefox).
3. Log in to the password manager.
4. Log in to email.
5. Complete any required 2FA or recovery steps.
6. Log in to GitHub in the browser if needed.

Adding an SSH key to GitHub is also a manual browser step because GitHub requires the public key to be added through the account settings UI.

## Terminal steps

Once network access is working and account credentials are available, run the terminal steps below.

### 1. Generate a new SSH key

Create a new Ed25519 SSH key pair:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

GitHub recommends generating an Ed25519 key when creating a new SSH key for account access.

By default, this creates the private key at `~/.ssh/id_ed25519` and the public key at `~/.ssh/id_ed25519.pub` unless a different file path is chosen during the prompt.

### 2. Start the SSH agent

```bash
eval "$(ssh-agent -s)"
```

GitHub documents starting the SSH agent before adding the private key to it.

### 3. Add the private key to the agent

```bash
ssh-add ~/.ssh/id_ed25519
```

This loads the private key into the running SSH agent for later GitHub authentication over SSH.

### 4. Copy the public key

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the full public key output so it can be pasted into GitHub SSH settings.

### 5. Add the public key to GitHub

Open the GitHub SSH key settings page and add the new public key:

- https://github.com/settings/keys

GitHub requires adding the public key to the account before SSH authentication to GitHub will work.

### 6. Test the GitHub SSH connection

```bash
ssh -T git@github.com
```

GitHub documents testing the SSH connection after the key is configured.

### 7. Clone the dotfiles repository

```bash
git clone git@github.com:pcfields/dotfiles.git
```

### 8. Set git identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

Git needs your identity to make commits.

GitHub supports cloning repositories with SSH URLs once SSH access is configured for the account.

## Script candidate

A good first automation target is a script that:

- Validates that an email address was passed in.
- Generates the SSH key if it does not already exist.
- Starts the SSH agent.
- Adds the key to the agent.
- Prints the public key.
- Pauses while the key is added to GitHub.
- Tests the SSH connection.
- Clones the dotfiles repository if it is not already present.