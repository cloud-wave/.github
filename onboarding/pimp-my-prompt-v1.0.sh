#!/bin/bash

cd "$HOME"

LOG_FILE="$HOME/pimp-my-prompt.log"
ERROR_LOG="$HOME/pimp-my-prompt-errors.log"
exec > >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$ERROR_LOG" >&2)

TOTAL_STEPS=11
CURRENT_STEP=1

step() {
  gum style --foreground 99 --bold "\n🔹 Step $CURRENT_STEP of $TOTAL_STEPS: $1"
  ((CURRENT_STEP++))
}

# Show ASCII title
cat << "EOF"

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

echo "\n🚀 Welcome to *Pimp My Prompt* — the interactive terminal setup wizard for devs."
echo "💡 Before we begin, we need to install a few essential tools to power this experience."
echo ""
read -rp "🔁 Press Enter to check/install Homebrew and gum..."

step "Checking/installing Homebrew (required for gum)"
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$\(/opt/homebrew/bin/brew shellenv\)"' >> ~/.zshrc
  eval "$\(/opt/homebrew/bin/brew shellenv\)"
else
  echo "✅ Homebrew is already installed."
fi

step "Installing gum (UI toolkit)"
if ! command -v gum &>/dev/null; then
  echo "📦 Installing gum..."
  brew install charmbracelet/tap/gum || {
    echo "❌ Failed to install gum. Please install Homebrew and try again." >&2
    exit 1
  }
else
  echo "✅ gum is already installed."
fi

step "Getting your name"
NAME=$(gum input --placeholder "What's your name?" --prompt "👤 Enter your name: ")
gum style --foreground 212 "👋 Nice to meet you, $NAME! Let's set up your development environment."

step "Installing Oh My Zsh"
if gum confirm "Install Oh My Zsh?"; then
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    gum spin --spinner dot --title "Installing Oh My Zsh..." -- \
      sh -c "curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash"
  else
    gum style --foreground 35 "Oh My Zsh already installed. Skipping."
  fi
fi

step "Creating folders and updating .zshrc"
mkdir -p "$HOME/.zsh"
mkdir -p "$HOME/repos"
touch "$HOME/.zsh/alias.zsh"
touch "$HOME/.zsh/functions.zsh"
grep -qxF '[[ -f ~/.zsh/alias.zsh ]] && source ~/.zsh/alias.zsh' ~/.zshrc || echo '[[ -f ~/.zsh/alias.zsh ]] && source ~/.zsh/alias.zsh' >> ~/.zshrc
grep -qxF '[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh' ~/.zshrc || echo '[[ -f ~/.zsh/functions.zsh ]] && source ~/.zsh/functions.zsh' >> ~/.zshrc

step "Installing Homebrew and CLI tools"
if gum confirm "Install core CLI tools (fnm, yarn, awscli, gh, eza, jq, tldr)?"; then
  gum spin --spinner line --title "Installing CLI tools..." -- \
    brew install fnm yarn awscli gh eza jq tldr
  gum style --foreground 212 "✅ CLI tools installed."
fi

step "Installing Node.js"
if gum confirm "Install Node.js 20 using fnm?"; then
  fnm install 20 && fnm use 20
  grep -qxF 'eval "$(fnm env --use-on-cd)"' ~/.zshrc || \
    echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
fi

step "GitHub CLI login"
if gum confirm "Authenticate with GitHub CLI?"; then
  gh auth login
  echo "export GITHUB_TOKEN=$(gh auth token)" >> ~/.zshrc
  echo "export GH_NODE_AUTH_TOKEN=$(gh auth token)" >> ~/.zshrc

  if gum confirm "Download default AWS SSO config into ~/.aws/config?"; then
    mkdir -p "$HOME/.aws"
    curl -fsSL "https://raw.githubusercontent.com/cloud-wave/onboarding-files/main/aws-sso-config.ini" -o "$HOME/.aws/config"
    gum style --foreground 212 "✅ AWS SSO config downloaded."
  fi
fi

step "Install global npm packages"
if gum confirm "Install global npm packages (serve, aws-sso-creds-helper)?"; then
  npm install -g serve aws-sso-creds-helper
fi

step "Clone NEONNOW GitHub repos"
if gum confirm "Clone NeonNow repos from GitHub?"; then
  gum spin --spinner minidot --title "Fetching repo list..." -- \
    gh search repos --limit=100 --owner=cloud-wave --topic=neonnow --json fullName --jq '.[].fullName' > repos.txt
  gum spin --spinner minidot --title "Cloning repos into ~/repos..." -- \
    while read -r repo; do
      targetDir="$HOME/repos/$(basename "$repo")"
      gh repo clone "$repo" "$targetDir"
    done < repos.txt
  rm repos.txt
  gum style --foreground 212 "✅ Repositories cloned."
fi

step "Save Font Awesome API token"
if gum confirm "Add your Font Awesome API token to .zshrc?"; then
  fa_token=$(gum input --placeholder "Paste API key here" --password)
  echo "export FONTAWESOME_NPM_AUTH_TOKEN=$fa_token" >> ~/.zshrc
  gum style --foreground 212 "🔐 API token saved to ~/.zshrc"
fi

# Done
gum style --bold --border double --padding "1 2" --margin "1" "🎉 All done! Restart your terminal or run: source ~/.zshrc"
echo "📄 Log saved to: $LOG_FILE"
echo "⚠️  Errors (if any) saved to: $ERROR_LOG"

# Learn More Section
echo "\n📚 Learn More about the tools you just installed:"
echo "  • Oh My Zsh:           https://ohmyz.sh/"
echo "  • fnm (Node Manager):  https://github.com/Schniz/fnm"
echo "  • AWS CLI:             https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
echo "  • aws-sso-creds-helper: https://github.com/ryansonshine/aws-sso-creds-helper"
echo "  • GitHub CLI (gh):     https://cli.github.com/manual/"
echo "  • serve (npm):         https://www.npmjs.com/package/serve"
echo "  • jq (JSON CLI):       https://stedolan.github.io/jq/"
echo "  • tldr:                https://tldr.sh/"
echo "\nHappy hacking, $NAME! 💻✨"

