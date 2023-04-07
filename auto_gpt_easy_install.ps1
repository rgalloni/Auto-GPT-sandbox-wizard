# Check if Docker is installed, otherwise install it
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "Docker not found. Installing Docker..."
    if (Get-Command "apt-get" -ErrorAction SilentlyContinue) {
        Invoke-WebRequest -Uri "https://get.docker.com" -OutFile "get-docker.ps1"
        Start-Process "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File .\get-docker.ps1" -Verb RunAs
        & sudo usermod -aG docker $(whoami)
        Remove-Item "get-docker.ps1"
    } elseif (Get-Command "brew" -ErrorAction SilentlyContinue) {
        brew install docker
    } else {
        Write-Host "Error: Unable to find a suitable package manager to install Docker"
        exit 1
    }
}

# Check if the Docker container exists
$container_exists = docker ps -a --filter "name=auto-gpt-container" --format "{{.Names}}"

# Run Docker container if it doesn't exist, or start the existing container
if (-not $container_exists) {

    # Remove the cloned git repository from the local machine
    Remove-Item -Recurse -Force "cloned_repo"

    # Prompt user for API keys
    $OPENAI_API_KEY = Read-Host "Enter your OpenAI API Key: "
    $PINECONE_API_KEY = Read-Host "Enter your Pinecone API Key (long term memory: get for free at https://pinecone.io): "
    $PINECONE_API_ENV = Read-Host "Enter your Pinecone API Env (long term memory: get for free at https://pinecone.io): "

    # Prompt user for workspace folder path
    $default_workspace_path = Join-Path $env:USERPROFILE "auto_gpt_workspace"
    $workspace_path = Read-Host "Enter the path of the workspace folder [press Enter for the default path: $($default_workspace_path)]"
    if (-not $workspace_path) {
        $workspace_path = $default_workspace_path
    }
    New-Item -ItemType Directory -Force -Path $workspace_path

    # Check if git is installed, otherwise install it
    if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
        if (Get-Command "apt-get" -ErrorAction SilentlyContinue) {
            sudo apt-get update
            sudo apt-get install -y git
        } elseif (Get-Command "brew" -ErrorAction SilentlyContinue) {
            brew install git
        } else {
            Write-Host "Error: Unable to find a suitable package manager to install git"
            exit 1
        }
    }

    # Clone the Git repository
    $git_url = "https://github.com/Torantulino/Auto-GPT.git"
    git clone $git_url cloned_repo

    # Modify the .env file in the cloned repository
    $env_template = Get-Content "cloned_repo/.env.template" -Raw
    $env_template = $env_template.Replace("your-openai-api-key", $OPENAI_API_KEY)
    $env_template = $env_template.Replace("your-pinecone-api-key", $PINECONE_API_KEY)
    $env_template = $env_template.Replace("your-pinecone-region", $PINECONE_API_ENV)
    Set-Content -Path "cloned_repo/.env" -Value $env_template

    # Create start_auto_gpt.ps1 script in the cloned repository
    $start_auto_gpt_script = @"
`$continuous = Read-Host 'Do you want to run AutoGPT in continuous mode? (y/n) (default n): '
`$gpt_version = Read-Host 'Which GPT version do you want to use? Enter 3 for GPT-3, any other key for GPT-4 (default GPT-4): '
if (`$gpt_version -eq '3') {
    `$gpt_flag = '--gpt3only'
} else {
    `$gpt_flag = ''
}
if (`$continuous -eq 'y' -or `$continuous -eq 'Y') {
    python scripts/main.py --continuous `$gpt_flag
} else {
    python scripts/main.py `$gpt_flag
}
"@
    Set-Content -Path "cloned_repo/start_auto_gpt.ps1" -Value $start_auto_gpt_script

    # Add to .gitignore
    Add-Content "cloned_repo/.gitignore" ".env"
    Add-Content "cloned_repo/.gitignore" "start_auto_gpt.ps1"

    # Create Dockerfile
    $dockerfile_content = @"
FROM python:3.8

RUN apt-get update && \
    apt-get install -y libgirepository1.0-dev

WORKDIR /app

COPY ./cloned_repo /app

RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir PyGObject && \
    chmod +x start_auto_gpt.ps1

CMD ["powershell", "-c", "git config pull.rebase false && ./start_auto_gpt.ps1"]
"@
    Set-Content -Path "Dockerfile" -Value $dockerfile_content

    # Create .dockerignore
    Set-Content -Path ".dockerignore" "__pycache__"

    # Build Docker image
    docker build -t auto-gpt .

    # Remove the cloned git repository from the local machine
    Remove-Item -Recurse -Force "cloned_repo"

    # Run Docker container
    docker run -it --name auto-gpt-container -v "${workspace_path}:/app/auto_gpt_workspace" auto-gpt

} else {
    docker start -ai auto-gpt-container
}