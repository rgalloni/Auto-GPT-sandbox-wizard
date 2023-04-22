#!/bin/bash

echo "Welcome to the Auto-GPT setup script! This script will guide you through the installation and configuration process."

# Check if Docker is installed, otherwise install it
if ! command -v docker >/dev/null; then
    echo "Docker not found. Installing Docker now..."
    if command -v apt-get >/dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $(whoami)
        rm get-docker.sh
    elif command -v brew >/dev/null; then
        brew install docker
    else
        echo "Error: Unable to find a suitable package manager to install Docker."
        exit 1
    fi
fi

# Check if git is installed, otherwise install it
if ! command -v git >/dev/null; then
    echo "Git not found. Installing Git now..."
    if command -v apt-get >/dev/null; then
        sudo apt-get update && sudo apt-get install -y git
    elif command -v brew >/dev/null; then
        brew install git
    else
        echo "Error: Unable to find a suitable package manager to install Git."
        exit 1
    fi
fi

# Check if Auto-GPT folder exists and if it has a .git directory
if [ -d "Auto-GPT" ] && [ -d "Auto-GPT/.git" ]; then
    cd Auto-GPT
    # Fetch the latest changes from the remote repository
    git fetch

    # Check if there are updates available
    if git status -uno | grep -q "Your branch is behind"; then
        read -p "Updates are available. Would you like to update Auto-GPT to the latest version? (y/n): " update_choice
        if [ "$update_choice" == "y" ]; then
            pre_pull_env_template=$(cat .env.template)
            git pull
            post_pull_env_template=$(cat .env.template)
            
            if [ "$pre_pull_env_template" != "$post_pull_env_template" ]; then
                echo "The .env.template has been updated. Here are the differences:"
                diff -u <(echo "$pre_pull_env_template") <(echo "$post_pull_env_template")
                echo "Please update your .env file to include any new variables."
            fi
        fi
    else
        echo "Auto-GPT is already up to date."
    fi

    cd ..
else
    # Clone the Git repository
    git_url="https://github.com/Significant-Gravitas/Auto-GPT.git"
    git clone -b stable $git_url Auto-GPT
    
    # Add to .gitignore
    echo ".env" >> ./Auto-GPT/.gitignore
fi

# Modify the .env file in the cloned repository
# Check if .env file exists
if [ -f "./Auto-GPT/.env" ]; then
    echo ".env file exists. Loading your current configuration."
else
    echo "Creating .env file from template..."
    cp ./Auto-GPT/.env.template ./Auto-GPT/.env

    read -p "Enter your OpenAI API key: " openai_api_key
    awk -v api_key="$openai_api_key" '{gsub(/your-openai-api-key/, api_key); print}' ./Auto-GPT/.env > ./Auto-GPT/.env.tmp && mv ./Auto-GPT/.env.tmp ./Auto-GPT/.env
    echo "OpenAI API key has been set in the .env file."
fi

# Prompt user for workspace folder path
read -p "Enter the workspace folder [Enter for default: $HOME/auto_gpt_workspace]": workspace_path
if [ -z "$workspace_path" ]; then
    workspace_path="$HOME/auto_gpt_workspace"
fi
mkdir -p "$workspace_path"

# Build Docker image
echo "Building Docker image for Auto-GPT..."
docker build -t auto-gpt ./Auto-GPT

# Prompt user for continuous mode and GPT-3 only mode
read -p "Do you want to run in continuous mode? (y/n): " continuous_mode
if [ "$continuous_mode" == "y" ]; then
    continuous_flag="--continuous"
else
    continuous_flag=""
fi

read -p "Do you want to use GPT-3 only? (y/n): " gpt3_only_mode
if [ "$gpt3_only_mode" == "y" ]; then
    gpt3_only_flag="--gpt3only"
else
    gpt3_only_flag=""
fi

# Run Docker container
echo "Starting Auto-GPT Docker container..."
docker run -it --env-file=./Auto-GPT/.env -v "${workspace_path}:/home/appuser/auto_gpt_workspace" auto-gpt $gpt3_only_flag $continuous_flag