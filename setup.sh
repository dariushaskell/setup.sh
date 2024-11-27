#!/bin/bash

print_message() {
    echo -e "\n\033[1;32m$1\033[0m\n"
}

if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a non-root user with sudo privileges."
    exit 1
fi

read -p "Enter your Github work email: " WORK_EMAIL
read -p "Enter your Github work username " WORK_USERNAME
read -p "Enter your Github personal email: " PERSONAL_EMAIL
read -p "Enter your Github personal username: " PERSONAL_USERNAME

print_message "Creating directories for work and personal projects..."
mkdir -p ~/work ~/personal

print_message "Generating SSH keys..."
ssh-keygen -t ed25519 -C "$WORK_EMAIL" -f ~/.ssh/work_key -N ""
ssh-keygen -t ed25519 -C "$PERSONAL_EMAIL" -f ~/.ssh/personal_key -N ""

print_message "Configuring SSH agent to load keys automatically..."
cat <<EOF > ~/.ssh/config
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/work_key
    AddKeysToAgent yes

Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/personal_key
    AddKeysToAgent yes
EOF

chmod 600 ~/.ssh/config

print_message "Ensuring SSH agent starts with keys on every terminal session..."
if ! grep -q "ssh-agent" ~/.bashrc; then
    cat <<'EOF' >> ~/.bashrc
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi

ssh-add ~/.ssh/work_key ~/.ssh/personal_key 2>/dev/null
EOF
    source ~/.bashrc
fi

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/work_key ~/.ssh/personal_key

print_message "Creating Git configurations for work and personal..."
cat <<EOF > ~/.gitconfig-work
[user]
    name = $WORK_USERNAME
    email = $WORK_EMAIL

[url "git@github.com-work:"]
    insteadOf = https://github.com/
EOF

cat <<EOF > ~/.gitconfig-personal
[user]
    name = $PERSONAL_USERNAME
    email = $PERSONAL_EMAIL

[url "git@github.com-personal:"]
    insteadOf = https://github.com/
EOF

cat <<EOF > ~/.gitconfig
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work

[includeIf "gitdir:~/personal/"]
    path = ~/.gitconfig-personal
EOF

print_message "Creating Git wrapper script..."
cat <<'EOF' > ~/git-wrapper.sh
#!/bin/bash
if [[ $PWD == /home/$USER/work/* ]]; then
    GIT_SSH_COMMAND="ssh -i ~/.ssh/work_key" git "$@"
elif [[ $PWD == /home/$USER/personal/* ]]; then
    GIT_SSH_COMMAND="ssh -i ~/.ssh/personal_key" git "$@"
else
    git "$@"
fi
EOF

chmod +x ~/git-wrapper.sh

if ! grep -q "alias git=" ~/.bashrc; then
    echo "alias git='~/git-wrapper.sh'" >> ~/.bashrc
    source ~/.bashrc
fi

print_message "Setup complete! Now you need to add your SSH keys to GitHub."

echo "Work SSH public key:"
cat ~/.ssh/work_key.pub
echo -e "\nCopy the above key and add it to your Work GitHub account under SSH keys."

echo "Personal SSH public key:"
cat ~/.ssh/personal_key.pub
echo -e "\nCopy the above key and add it to your Personal GitHub account under SSH keys."

read -p "Press Enter after you've added the SSH keys to your GitHub accounts to proceed with testing..."

print_message "Testing SSH connections..."
ssh -T git@github.com-work
ssh -T git@github.com-personal

print_message "All done! You can now use separate SSH keys and Git configurations for work and personal projects."
