#!/bin/bash

# Set the working directory to the user's home
cd "$HOME"

# Define log and error files
LOG_FILE="$HOME/pimp-my-prompt.log"
ERROR_LOG="$HOME/pimp-my-prompt-errors.log"

# Redirect all output to log files
exec > >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$ERROR_LOG" >&2)

# Define total steps for progress tracking
TOTAL_STEPS=9
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

  # Determine the correct Homebrew path based on architecture
  if [[ $(uname -m) == 'arm64' ]]; then
    BREW_PATH="/opt/homebrew/bin/brew"
  else
    BREW_PATH="/usr/local/bin/brew"
  fi

  # Add Homebrew to current session immediately
  if [ -f "$BREW_PATH" ]; then
    eval "$($BREW_PATH shellenv)"
  fi

  # Add to .zprofile for future sessions
  if [[ $(uname -m) == 'arm64' ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  else
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
  fi

else
  echo "✅ Homebrew is already installed."
fi

# Ensure brew is available in current session
if command -v brew &>/dev/null; then
  eval "$(brew shellenv)"
else
  # Fallback: try to load it manually
  if [[ $(uname -m) == 'arm64' ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# Verify brew is now available
if ! command -v brew &>/dev/null; then
  echo "❌ ERROR: Homebrew installation failed or cannot be loaded."
  echo "Please run: eval \"\$(brew shellenv)\" and try again."
  exit 1
else
  echo "✅ Homebrew is ready to use."
fi

# Install core CLI tools
step "Installing core CLI tools"
brew install fnm yarn awscli gh eza jq tldr

# Create folders for shell customization
step "Creating folders and updating .zshrc"
mkdir -p "$HOME/.zsh"
mkdir -p "$HOME/repos"
touch "$HOME/.zshrc"
touch "$HOME/.zsh/alias.zsh"
touch "$HOME/.zsh/functions.zsh"
grep -qxF '[[ -f ~/.zsh/alias.zsh ]] && source ~/.zsh/alias.zsh' ~/.zshrc || echo '[[ -f ~/.zsh/alias.zsh ]] && source ~/.zsh/alias.zsh' >> ~/.zshrc
grep -qxF '[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh' ~/.zshrc || echo '[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh' >> ~/.zshrc

# Install Node.js using fnm
step "Installing Node.js"

# Ensure fnm is available
if ! command -v fnm &>/dev/null; then
  echo "❌ ERROR: fnm was not installed correctly."
  exit 1
fi

# Initialize fnm in current session BEFORE using it
eval "$(fnm env --use-on-cd)"

# Add fnm initialization to .zshrc for future sessions
if ! grep -q 'fnm env' ~/.zshrc; then
  echo '' >> ~/.zshrc
  echo '# Initialize fnm (Fast Node Manager)' >> ~/.zshrc
  echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
fi

# Now install and use Node.js
if fnm list | grep -q "v20"; then
  echo "✅ Node.js 20 already installed."
  fnm use 20
fi

# GitHub CLI login
step "Authenticate with GitHub CLI"
if gh auth status &>/dev/null; then
  echo "✅ Already authenticated with GitHub CLI."
else
  gh auth login -s 'write:packages'
fi

# Export tokens for current session and future sessions
if gh auth status &>/dev/null; then
  GITHUB_TOKEN=$(gh auth token)
  export GITHUB_TOKEN
  export GH_NODE_AUTH_TOKEN="$GITHUB_TOKEN"

  # Add to .zshrc for future sessions (avoid duplicates)
  if ! grep -q 'GITHUB_TOKEN.*gh auth token' ~/.zshrc; then
    echo '' >> ~/.zshrc
    echo '# GitHub CLI tokens' >> ~/.zshrc
    echo 'export GITHUB_TOKEN=$(gh auth token)' >> ~/.zshrc
    echo 'export GH_NODE_AUTH_TOKEN=$(gh auth token)' >> ~/.zshrc
  fi

  echo "✅ GitHub tokens exported."
fi

# Optional AWS SSO config
step "Set up AWS SSO config"
if [ -n "$GITHUB_TOKEN" ]; then
    echo "📥 Cloning AWS SSO configuration..."
    # Use gh CLI to clone (which handles auth automatically)
    if gh repo clone cloud-wave/onboarding-files /tmp/aws-config 2>/dev/null; then
      if [ -f /tmp/aws-config/aws-sso-config.ini ]; then
        mkdir -p "$HOME/.aws"
        cp /tmp/aws-config/aws-sso-config.ini "$HOME/.aws/config"
        echo "✅ AWS SSO config set up."
      else
        echo "⚠️  AWS config file not found in repository."
      fi
      rm -rf /tmp/aws-config
    else
      echo "⚠️  Could not clone AWS config repository. Skipping."
    fi
else
  echo "⚠️  GitHub authentication not completed. Skipping AWS SSO config."
fi

# Install global npm packages
step "Install global npm packages (serve, aws-sso-creds-helper)"
if npm list -g serve aws-sso-creds-helper >/dev/null 2>&1; then
  echo "✅ 'serve' and 'aws-sso-creds-helper' already installed globally."
else
  if npm install -g serve aws-sso-creds-helper; then
    echo "✅ Installed 'serve' and 'aws-sso-creds-helper' globally."
  else
    echo "⚠️  Failed to install 'serve' and/or 'aws-sso-creds-helper'. Please check your npm setup."
  fi
fi

# Clone CloudWave repos
step "Clone NEONNOW GitHub repos"
echo "🔍 Searching for NEONNOW repositories..."
REPOS=( $(gh search repos --limit=100 --owner=cloud-wave --topic=neonnow --json fullName --jq '.[].fullName' | grep '^cloud-wave/neon-') )
TOTAL_REPOS=${#REPOS[@]}

if [ "$TOTAL_REPOS" -eq 0 ]; then
  echo "⚠️  No NEONNOW repositories found."
else
  echo "📦 Found $TOTAL_REPOS repositories."

  # Ask if user wants to update existing repos
  read -rp "🔄 Update existing repositories? (y/N): " UPDATE_EXISTING
  UPDATE_EXISTING=${UPDATE_EXISTING:-n}

  COUNT=1
  CLONED=0
  UPDATED=0
  SKIPPED=0
  FAILED=0

  for repo in "${REPOS[@]}"; do
    targetDir="$HOME/repos/$(basename "$repo")"
    printf "%2s/%s - %-62s" "$COUNT" "$TOTAL_REPOS" "$repo"

    if [ -d "$targetDir" ]; then
      if [[ "$UPDATE_EXISTING" =~ ^[Yy]$ ]]; then
        if (cd "$targetDir" && git pull --quiet &>/dev/null); then
          echo " 🔄 (updated)"
          ((UPDATED++))
        else
          echo " ⚠️  (update failed)"
          ((FAILED++))
        fi
      else
        echo " ⏭️  (already exists)"
        ((SKIPPED++))
      fi
    else
      if gh repo clone "$repo" "$targetDir" &>/dev/null; then
        echo " ✅"
        ((CLONED++))
      else
        echo " ❌"
        ((FAILED++))
      fi
    fi
    ((COUNT++))
  done

  echo ""
  echo "📊 Summary:"
  [ "$CLONED" -gt 0 ] && echo "   ✅ Cloned: $CLONED"
  [ "$UPDATED" -gt 0 ] && echo "   🔄 Updated: $UPDATED"
  [ "$SKIPPED" -gt 0 ] && echo "   ⏭️  Skipped: $SKIPPED"
  [ "$FAILED" -gt 0 ] && echo "   ❌ Failed: $FAILED"
fi

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
echo -e "- jq: https://stedolan.github.io/jq"

echo -e "
Happy hacking! 💻✨"
