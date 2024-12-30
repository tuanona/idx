#!/bin/bash

# Loading animation function (unchanged)
loading() {
  local message="$1"
  local -i i=0
  local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧")
  while [[ -n "$running" ]]; do
    printf "\r\e[32m%s %s\e[0m" "${frames[$i]}" "$message"
    i=$(( (i+1) % ${#frames[@]} ))
    sleep 0.1
  done
  printf "\r\e[32m%s %s\e[0m\n" "✓" "$message completed."
}

# Check if the script is run within the 'idx' directory (unchanged)
if [[ ! -f "nix.sh" ]]; then
  echo "This script must be run from within the 'idx' directory."
  exit 1
fi

# Function to display options and get user input (unchanged)
choose_option() {
    local prompt="$1"
    local options=("${@:2}")
    local i=1
    for option in "${options[@]}"; do
        echo "$i. $option"
        ((i++))
    done
    read -p "$prompt: " choice
    if [[ "$choice" -gt "${#options[@]}" || "$choice" -lt 1 ]]; then
        echo "Invalid choice."
        return 1
    fi
    echo "${options[$((choice-1))]}"
}

# Main steps
echo "[1] Generate template for your project"
echo "[2] Push to your GitHub repository (Ready to clone in idx)"
echo ""

# Get the list of languages (unchanged)
languages=()
mapfile -t languages < <(find . -maxdepth 1 -mindepth 1 -type d -print -not -name "." -not -name ".idx" -not -name "." -not -name "nix.sh" | sort)

chosen_lang=$(choose_option "Choose a language" "${languages[@]}") || exit 1

# Get the list of runtimes/frameworks/libraries (unchanged)
options=()
mapfile -t options < <(find "$chosen_lang" -maxdepth 1 -mindepth 1 -print | sort)

chosen_option=$(choose_option "Choose a runtime/framework/library" "${options[@]}") || exit 1

# Determine the template path (unchanged)
if [[ -d "$chosen_option" ]]; then # Runtime
    template_file=$(find "$chosen_option" -maxdepth 1 -name "*.nix" -print -quit)
else # Framework/Library
    template_file="$chosen_option"
fi

# Create .idx and copy the template (handle cases where template is not found) (unchanged)
if [[ -z "$template_file" ]]; then
    echo "Template not found."
    exit 1
fi

mkdir .idx
cp "$template_file" .idx/dev.nix

# Remove everything except .idx and nix.sh (unchanged)
find . -mindepth 1 -not -path './.idx/*' -not -path './nix.sh' -exec rm -rf {} \;

# Push to GitHub
read -p "Enter your GitHub repository URL (e.g., https://github.com/YOUR_USERNAME/your-repo.git): " repo_url

if [[ -z "$repo_url" ]]; then
    echo "Repository URL is required."
    exit 1
fi

git init
git add .
git commit -m "Initial commit"

git remote add origin "$repo_url"

running=1
loading "Pushing to GitHub..." &
loading_pid=$!

git push -u origin main

running=
wait "$loading_pid"

if [[ $? -eq 0 ]]; then
    echo "Successfully pushed to GitHub. You can now clone this repository in your idx project."
else
    echo "Failed to push to GitHub. Please check your repository URL and Git configuration."
fi