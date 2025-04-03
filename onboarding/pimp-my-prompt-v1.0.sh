#!/bin/bash

cd "$HOME"

# Ensure Homebrew is in PATH early
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

LOG_FILE="$HOME/pimp-my-prompt.log"
ERROR_LOG="$HOME/pimp-my-prompt-errors.log"
exec > >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$ERROR_LOG" >&2)

TOTAL_STEPS=12
CURRENT_STEP=1
set -e

step() {
  echo ""
  echo "🔹 Step $CURRENT_STEP of $TOTAL_STEPS: $1"
  ((CURRENT_STEP++))
}

# Clean exit on Ctrl+C
cleanup() {
  echo -e "\n❌ Script interrupted. Exiting cleanly."
  exit 1
}
trap cleanup INT

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

echo -e "
🚀 Welcome to *Pimp My Prompt* — the interactive terminal setup wizard for devs, brought to you by CloudWave."
echo -e "\n💡 Before we begin, we need to install a few essential tools to power this experience."
echo ""
read -rp "🔁 Press Enter to check/install Homebrew..."

step "Checking and installing required setup tools (Homebrew)"
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Wait for brew to be ready
  BREW_PATH="/opt/homebrew/bin/brew"
  MAX_WAIT=10
  WAITED=0

  until [ -x "$BREW_PATH" ]; do
    if [ $WAITED -ge $MAX_WAIT ]; then
      echo "❌ Timed out waiting for Homebrew to install." >&2
      exit 1
    fi
    echo "⏳ Waiting for Homebrew to finish installing..."
    sleep 1
    ((WAITED++))
  done

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$($BREW_PATH shellenv)"
else
  echo "✅ Homebrew is already installed."
fi


step "Installing Oh My Zsh"
if read -rp "❓ Install Oh My Zsh? (y/N): " yn && [[ $yn =~ ^[Yy]$ ]]; then
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "💡 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    echo "✅ Oh My Zsh already installed. Skipping."
  fi
fi

step "Creating folders and updating .zshrc"
mkdir -p "$HOME/.zsh"
mkdir -p "$HOME/repos"
touch "$HOME/.zsh/alias.zsh"
touch "$HOME/.zsh/functions.zsh"
grep -qxF '[[ -f ~/.zsh/alias.zsh ]] && source ~/.zsh/alias.zsh' ~/.zshrc || echo '[[ -f ~/.zsh/alias.zsh ]] && source ~/.zsh/alias.zsh' >> ~/.zshrc
grep -qxF '[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh' ~/.zshrc || echo '[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh' >> ~/.zshrc

step "Installing core CLI tools (fnm, yarn, awscli, gh, eza, jq, tldr)"
if read -rp "❓ Install core CLI tools (fnm, yarn, awscli, gh, eza, jq, tldr)? (y/N): " yn && [[ $yn =~ ^[Yy]$ ]]; then
  brew install fnm yarn awscli gh eza jq tldr
  echo "✅ CLI tools installed."
fi

step "Installing Node.js"
if read -rp "❓ Install Node.js 20 using fnm? (y/N): " yn && [[ $yn =~ ^[Yy]$ ]]; then
  if fnm list | grep -q "v20"; then
    echo "✅ Node.js 20 already installed."
  else
    fnm install 20
  fi
  fnm default 20
  grep -qxF 'eval "$(fnm env --use-on-cd)"' ~/.zshrc || echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc

  # Make fnm work immediately in this shell
  eval "$($(brew --prefix fnm)/bin/fnm env --use-on-cd)"
fi

step "GitHub CLI login"
if [[ -n "$GITHUB_TOKEN" && -n "$GH_NODE_AUTH_TOKEN" ]] && gh auth status &>/dev/null; then
  echo "✅ GitHub CLI already authenticated via environment variables."
  GITHUB_LOGGED_IN=true
elif read -rp "❓ Authenticate with GitHub CLI? (y/N): " yn && [[ $yn =~ ^[Yy]$ ]]; then
  gh auth login
  GITHUB_TOKEN=$(gh auth token)
  GH_NODE_AUTH_TOKEN=$GITHUB_TOKEN
  export GITHUB_TOKEN GH_NODE_AUTH_TOKEN
  echo "export GITHUB_TOKEN=$GITHUB_TOKEN" >> ~/.zshrc
  echo "export GH_NODE_AUTH_TOKEN=$GH_NODE_AUTH_TOKEN" >> ~/.zshrc
  GITHUB_LOGGED_IN=true
else
  GITHUB_LOGGED_IN=false
fi

((CURRENT_STEP++))
step "Set up AWS SSO config"
if $GITHUB_LOGGED_IN && read -rp "❓ Download default AWS SSO config into ~/.aws/config? (y/N): " yn && [[ $yn =~ ^[Yy]$ ]]; then
  mkdir -p "$HOME/.aws"
  gh repo clone cloud-wave/onboarding-files "$HOME/.aws-config-temp"
  cp "$HOME/.aws-config-temp/aws-sso-config.ini" "$HOME/.aws/config"
  rm -rf "$HOME/.aws-config-temp"
  echo "✅ AWS SSO config set up."
fi

((CURRENT_STEP++))
step "Install global npm packages"
if read -rp "❓ Install global npm packages (serve, aws-sso-creds-helper)? (y/N): " yn && [[ $yn =~ ^[Yy]$ ]]; then
  npm install -g serve aws-sso-creds-helper
fi

((CURRENT_STEP++))
step "Clone NEONNOW GitHub repos"
if read -rp "❓ Clone NEONNOW repos from GitHub? (y/N): " yn && [[ $yn =~ ^[Yy]$ ]]; then
  REPOS=($(gh search repos --limit=100 --owner=cloud-wave --topic=neonnow --json fullName --jq '.[].fullName' | grep '^cloud-wave/neon-'))
  TOTAL_REPOS=${#REPOS[@]}
  COUNT=1
  for repo in "${REPOS[@]}"; do
    printf "%2s/%s - Cloning %-54s" "$COUNT" "$TOTAL_REPOS" "$repo"
    targetDir="$HOME/repos/$(basename "$repo")"
    if gh repo clone "$repo" "$targetDir" &>/dev/null; then
      echo " ✅"
    else
      echo " ❌"
    fi
    ((COUNT++))
  done
  rm repos.txt
  echo "✅ Repositories cloned."
fi

((CURRENT_STEP++))
step "Save Font Awesome API token"
if read -rp "❓ Add your Font Awesome API token to .zshrc? (y/N): " yn && [[ $yn =~ ^[Yy]$ ]]; then
  read -rsp "🔐 Paste your Font Awesome API key (from Keeper > Development > Font Awesome API Key): " fa_token
  echo
  echo "export FONTAWESOME_NPM_AUTH_TOKEN=$fa_token" >> ~/.zshrc
  echo "🔐 API token saved to ~/.zshrc"
fi

# Done
echo ""
echo "🎉 All done! Restart your terminal or run: source ~/.zshrc"
echo -e "\n📄 Log saved to: $LOG_FILE"
echo -e "\n⚠️  Errors (if any) saved to: $ERROR_LOG"

# Learn More Section
echo -e "\n📚 Learn More about the tools you just installed:"
echo "  • Oh My Zsh:           https://ohmyz.sh/"
echo "  • fnm (Node Manager):  https://github.com/Schniz/fnm"
echo "  • AWS CLI:             https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
echo "  • aws-sso-creds-helper: https://github.com/ryansonshine/aws-sso-creds-helper"
echo "  • GitHub CLI (gh):     https://cli.github.com/manual/"
echo "  • serve (npm):         https://www.npmjs.com/package/serve"
echo "  • jq (JSON CLI):       https://stedolan.github.io/jq/"
echo "  • tldr:                https://tldr.sh/"

echo -e "
Happy hacking! 💻✨"

