# Set the working directory to the user's home
cd "$HOME"

# Define log and error files
LOG_FILE="$HOME/pimp-my-prompt.log"
ERROR_LOG="$HOME/pimp-my-prompt-errors.log"

# Redirect all output to log files
exec > >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$ERROR_LOG" >&2)

# Define total steps for progress tracking
TOTAL_STEPS=10
CURRENT_STEP=1

# Define step function to print progress
step() {
  echo -e "\n🔹 Step $CURRENT_STEP of $TOTAL_STEPS: $1"
  ((CURRENT_STEP++))
}

# ASCII title block
cat << "EOF"

┌──────────────────────────────────────────────────────────────────────┐
│░█▀▀░█░░░█▀█░█░█░█▀▄░█░█░█▀█░█░█░█▀▀░░░█▀█░█▀▄░█▀▀░█▀▀░█▀▀░█▀█░▀█▀░█▀▀│
│░█░░░█░░░█░█░█░█░█░█░█▄█░█▀█░▀▄▀░█▀▀░░░█▀▀░█▀▄░█▀▀░▀▀█░█▀▀░█░█░░█░░▀▀█│
│░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀░░▀░▀░▀░▀░░▀░░▀▀▀░░░▀░░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀│
└──────────────────────────────────────────────────────────────────────┘

    ____  _                    __  ___     
   / __ \(_)___ ___  ____     /  |/  /_  __
  / /_/ / / __ `__ \/ __ \   / /|_/ / / / /
 / ____/ / / / / / / /_/ /  / /  / / /_/ / 
/_/   /_/_/ /_/ /_/ .___/  /_/  /_/\__, /  
                 /_/              /____/   
    ____                             __ 
   / __ \_________  ____ ___  ____  / /_
  / /_/ / ___/ __ \/ __ `__ \/ __ \/ __/
 / ____/ /  / /_/ / / / / / / /_/ / /_  
/_/   /_/   \____/_/ /_/ /_/ .___/\__/  
                          /_/           

EOF

# Introduction message
echo -e "\n🚀 Welcome to *Pimp My Prompt* — the interactive terminal setup wizard for devs, brought to you by CloudWave."
echo -e "\n💡 Before we begin, we need to install a few essential tools to power this experience."
echo ""
read -rp "🔁 Press Enter to check/install Homebrew..."

# Check and install Homebrew
step "Checking and installing Homebrew"
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "✅ Homebrew is already installed."
fi

# Install core CLI tools
step "Installing core CLI tools"
brew install fnm yarn awscli gh eza jq tldr

# Create folders for shell customization
step "Creating folders and updating .zshrc"
mkdir -p "$HOME/.zsh"
mkdir -p "$HOME/repos"
touch "$HOME/.zsh/alias.zsh"
touch "$HOME/.zsh/functions.zsh"
grep -qxF '[[ -f ~/.zsh/alias.zsh ]] && source ~/.zsh/alias.zsh' ~/.zshrc || echo '[[ -f ~/.zsh/alias.zsh ]] && source ~/.zsh/alias.zsh' >> ~/.zshrc
grep -qxF '[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh' ~/.zshrc || echo '[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh' >> ~/.zshrc

# Install Node.js using fnm
step "Installing Node.js"
if fnm list | grep -q "v20"; then
  echo "✅ Node.js 20 already installed."
else
  fnm install 20 && fnm use 20
  eval "$(fnm env --use-on-cd)"
fi

# GitHub CLI login
step "Authenticate with GitHub CLI"
if gh auth status &>/dev/null; then
  echo "✅ Already authenticated with GitHub CLI."
else
  gh auth login
  echo "export GITHUB_TOKEN=$(gh auth token)" >> ~/.zshrc
  echo "export GH_NODE_AUTH_TOKEN=$(gh auth token)" >> ~/.zshrc
fi

# Optional AWS SSO config
step "Set up AWS SSO config"
if [ -n "$GITHUB_TOKEN" ]; then
  mkdir -p "$HOME/.aws"
  git clone https://github.com/cloud-wave/onboarding-files.git /tmp/aws-config
  cp /tmp/aws-config/aws-sso-config.ini "$HOME/.aws/config"
  rm -rf /tmp/aws-config
  echo "✅ AWS SSO config set up."
fi

# Install global npm packages
step "Install global npm packages"
npm install -g serve aws-sso-creds-helper

# Clone NEONNOW GitHub repos
step "Clone NEONNOW GitHub repos"
REPOS=( $(gh search repos --limit=100 --owner=cloud-wave --topic=neonnow --json fullName --jq '.[].fullName' | grep '^cloud-wave/neon-') )
TOTAL_REPOS=${#REPOS[@]}
COUNT=1
for repo in "${REPOS[@]}"; do
  targetDir="$HOME/repos/$(basename "$repo")"
  printf "%2s/%s - Cloning %-54s" "$COUNT" "$TOTAL_REPOS" "$repo"
  if gh repo clone "$repo" "$targetDir" &>/dev/null; then
    echo " ✅"
  else
    echo " ❌"
  fi
  ((COUNT++))
done

# Save Font Awesome API token
step "Save Font Awesome API token"
read -rsp "🔐 Paste your Font Awesome API key (from Keeper > Development): " fa_token
echo "export FONTAWESOME_NPM_AUTH_TOKEN=$fa_token" >> ~/.zshrc

# Completion message
echo -e "
🎉 All done! Restart your terminal or run: source ~/.zshrc"
echo -e "
📄 Log saved to: $LOG_FILE"
echo -e "
⚠️  Errors (if any) saved to: $ERROR_LOG"

# Learn more links for tools installed
echo -e "
📚 Learn more about the tools you've just installed:"
echo -e "- fnm: https://github.com/Schniz/fnm"
echo -e "- aws-sso-creds-helper: https://github.com/ryansonshine/aws-sso-creds-helper"
echo -e "- eza: https://github.com/eza-community/eza"
echo -e "- tldr: https://tldr.sh"
echo -e "- gh (GitHub CLI): https://cli.github.com"
echo -e "- yarn: https://yarnpkg.com"
echo -e "- jq: https://stedolan.github.io/jq""

echo -e "
Happy hacking! 💻✨"

