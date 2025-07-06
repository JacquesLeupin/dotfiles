#!/usr/bin/env bash
# run_once_20_react-native-setup.sh
# Sets up a complete React Native development tool‑chain on macOS.
set -euo pipefail

# ---- helpers -----------------------------------------------------------------
command_exists() { command -v "$1" >/dev/null 2>&1; }
brew_has()        { brew list --formula "$1"   &>/dev/null; }
cask_has()        { brew list --cask   "$1"    &>/dev/null; }

# ---- 1. Homebrew -------------------------------------------------------------
if ! command_exists brew; then
  echo "Installing Homebrew …"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple‑silicon default path
fi
brew update

# ---- 2. Core CLI tools (Node ≥18, Watchman) ----------------------------------
for pkg in node watchman; do                 # Node & Watchman required
  brew_has "$pkg" || brew install "$pkg"
done

# Optional but handy: Yarn classic. 
brew_has yarn || brew install yarn

# ---- 3. Java 17 LTS (required by Android/Gradle) -----------------------------
if ! /usr/libexec/java_home -v 17 &>/dev/null; then
  brew install --cask zulu@17                # Azul Zulu JDK 17 recommended
fi
JDK_HOME=$(/usr/libexec/java_home -v 17)
grep -q "JAVA_HOME.*zulu-17" ~/.zshrc 2>/dev/null || {
  {
    echo ""
    echo "# >>> JDK for React Native >>>"
    echo "export JAVA_HOME=${JDK_HOME}"
    echo 'export PATH=$PATH:$JAVA_HOME/bin'
    echo "# <<< JDK for React Native <<<"
  } >> ~/.zshrc
}

# ---- 4. iOS tool‑chain -------------------------------------------------------
if ! xcode-select -p &>/dev/null; then       # Full Xcode, simulators etc.
  echo "Installing Xcode (large download)…"
  brew install --cask xcode                  # Will open App Store UI if needed
  sudo xcodebuild -license accept
fi
command_exists pod || sudo gem install cocoapods   # CocoaPods gem 

# ---- 5. Android tool‑chain ---------------------------------------------------
for cask in android-studio android-platform-tools; do
  cask_has "$cask" || brew install --cask "$cask"  # Installs SDK, ADB, emulator
done

ANDROID_LINES='
# >>> React‑Native Android vars >>>
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
# <<< React‑Native Android vars <<<
'
grep -q "React‑Native Android vars" ~/.zshrc 2>/dev/null || \
  printf "%s\n" "$ANDROID_LINES" >> ~/.zshrc

# Accept SDK licences (safe to skip if cmd‑line tools not yet installed)
if [ -f "$HOME/Library/Android/sdk/tools/bin/sdkmanager" ]; then
  yes | "$HOME/Library/Android/sdk/tools/bin/sdkmanager" --licenses || true
fi

# ---- 6. Done -----------------------------------------------------------------
echo "✅  React Native tool‑chain installation complete."
echo "   Open a new terminal or run:  source ~/.zshrc"

