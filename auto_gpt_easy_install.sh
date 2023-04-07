#!/bin/bash

# Check if Docker is installed, otherwise install it
if ! command -v docker >/dev/null; then
    echo "Docker not found. Installing Docker..."
    if command -v apt-get >/dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $(whoami)
        rm get-docker.sh
    elif command -v brew >/dev/null; then
        brew install docker
    else
        echo "Error: Unable to find a suitable package manager to install Docker"
        exit 1
    fi
fi

# Check if the Docker container exists
container_exists=$(docker ps -a --filter "name=auto-gpt-container" --format "{{.Names}}")

# Run Docker container if it doesn't exist, or start the existing container
if [ -z "$container_exists" ]; then

    # Remove the cloned git repository from the local machine
    rm -rf cloned_repo

    # Prompt user for API keys
    read -p "Enter your OpenAI API Key: " OPENAI_API_KEY
    #read -p "Enter your ElevenLabs API Key (leave empty if not using Speech Mode): " ELEVEN_LABS_API_KEY

    read -p "Enter your Pinecone API Key (long term memory: get for free at https://pinecone.io): " PINECONE_API_KEY

    read -p "Enter your Pinecone API Env (long term memory: get for free at https://pinecone.io): " PINECONE_API_ENV

    # Prompt user for workspace folder path
    read -p "Enter the path of the workspace folder [press Enter for the default path: $HOME/auto_gpt_workspace]": workspace_path
    if [ -z "$workspace_path" ]; then
        workspace_path="$HOME/auto_gpt_workspace"
    fi
    mkdir -p "$workspace_path"

    # Check if git is installed, otherwise install it
    if ! command -v git >/dev/null; then
        if command -v apt-get >/dev/null; then
            sudo apt-get update && sudo apt-get install -y git
        elif command -v brew >/dev/null; then
            brew install git
        else
            echo "Error: Unable to find a suitable package manager to install git"
            exit 1
        fi
    fi

    # Clone the Git repository
    git_url="https://github.com/Torantulino/Auto-GPT.git"
    git clone $git_url cloned_repo

    # Modify the .env file in the cloned repository
    env_template=$(cat cloned_repo/.env.template)
    env_template=${env_template//your-openai-api-key/$OPENAI_API_KEY}
    env_template=${env_template//your-pinecone-api-key/$PINECONE_API_KEY}
    env_template=${env_template//your-pinecone-region/$PINECONE_API_ENV}
    #env_template=${env_template//your-elevenlabs-api-key/$ELEVEN_LABS_API_KEY}
    echo "$env_template" > cloned_repo/.env

    # Create start_auto_gpt.sh script in the cloned repository
    cat > cloned_repo/start_auto_gpt.sh <<EOL
#!/bin/bash

read -p "Do you want to run AutoGPT in continuous mode? (y/n) (default n): " continuous

read -p "Which GPT version do you want to use? Enter 3 for GPT-3, any other key for GPT-4 (default GPT-4): " gpt_version

if [ "$gpt_version" == "3" ]; then
    gpt_flag="--gpt3only"
else
    gpt_flag=""
fi

if [ "$continuous" == "y" ] || [ "$continuous" == "Y" ]; then
    python scripts/main.py --continuous $gpt_flag
else
    python scripts/main.py $gpt_flag
fi
EOL

    # Add to .gitignore
    echo ".env" >> cloned_repo/.gitignore
    echo "start_auto_gpt.sh" >> cloned_repo/.gitignore

    # Create Dockerfile
    cat > Dockerfile <<EOL
FROM python:3.8

RUN apt-get update && \
    apt-get install -y libgirepository1.0-dev

WORKDIR /app

COPY ./cloned_repo /app

RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir PyGObject && \
    chmod +x start_auto_gpt.sh

CMD ["bash", "-c", "git config pull.rebase false && ./start_auto_gpt.sh"]
EOL

# Create .dockerignore
echo "__pycache__" > .dockerignore

# Build Docker image
docker build -t auto-gpt .

# Remove the cloned git repository from the local machine
rm -rf cloned_repo

# Run Docker container
docker run -it --name auto-gpt-container -v "${workspace_path}:/app/auto_gpt_workspace" auto-gpt

else
    docker start -ai auto-gpt-container
fi