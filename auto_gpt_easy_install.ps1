Write-Host "Welcome to the Auto-GPT setup script! This script will guide you through the installation and configuration process."

# Install Chocolatey if not already installed
if (-not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

$softwareInstalled = $false

# Check if Docker is installed, otherwise install it
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "Docker not found. Installing Docker..."
    choco install docker-desktop -y
    Write-Host "Updating Linux sub-system for Docker..."
    $softwareInstalled = $true
}

# Check if git is installed, otherwise install it
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Installing Git..."
    choco install git -y
    $softwareInstalled = $true
}

if ($softwareInstalled) {
    Write-Host "Software installed! Please restart your computer and run this script again."
    exit
}

# Updating WSL
wsl --update

Write-Host "Please make sure Docker Desktop is running. If it's not, start Docker Desktop before proceeding."
Read-Host "Press ENTER when Docker Desktop is running"

# Check if Auto-GPT folder exists and if it has a .git directory
if ((Test-Path "Auto-GPT") -and (Test-Path "Auto-GPT/.git")) {
    Set-Location Auto-GPT
    # Fetch the latest changes from the remote repository
    git fetch

    # Check if there are updates available
    if (git status -uno | Select-String "Your branch is behind") {
        $update_choice = Read-Host "Updates are available. Would you like to update Auto-GPT to the latest version? (y/n): "
        if ($update_choice -eq "y") {
            $pre_pull_env_template = Get-Content .env.template
            git pull
            $post_pull_env_template = Get-Content .env.template
            
            if ($pre_pull_env_template -ne $post_pull_env_template) {
                Write-Host "The .env.template has been updated."
                Write-Host "Please update your .env file to include any new variables."
            }
        }
    }
    else {
        Write-Host "Auto-GPT is already up to date."
    }

    Set-Location ..
}
else {
    # Clone the Git repository
    $git_url = "https://github.com/Significant-Gravitas/Auto-GPT.git"
    git clone -b stable $git_url Auto-GPT
    
    # Add to .gitignore
    Add-Content -Path ./Auto-GPT/.gitignore -Value ".env"
}

# Modify the .env file in the cloned repository
# Check if .env file exists
if (Test-Path "./Auto-GPT/.env") {
    Write-Host ".env file exists. Loading your current configuration."
}
else {
    Write-Host "Creating .env file from template..."
    Copy-Item ./Auto-GPT/.env.template ./Auto-GPT/.env

    $openai_api_key = Read-Host "Enter your OpenAI API key: "
    (Get-Content ./Auto-GPT/.env).Replace('your-openai-api-key', $openai_api_key) | Set-Content ./Auto-GPT/.env
    Write-Host "OpenAI API key has been set in the .env file."
}

# Prompt user for workspace folder path
$workspace_path = Read-Host "Enter the workspace folder [Enter for default: $($env:USERPROFILE)/auto_gpt_workspace]"
if ([string]::IsNullOrEmpty($workspace_path)) {
    $workspace_path = "$($env:USERPROFILE)/auto_gpt_workspace"
}
New-Item -ItemType Directory -Force -Path $workspace_path

# Build Docker image
Write-Host "Building Docker image for Auto-GPT..."
try {
    docker build -t auto-gpt ./Auto-GPT
} catch {
    Write-Host "An error occurred while building the Docker image. Please check the error message and try again."
    exit
}

# Prompt user for continuous mode and GPT-3 only mode
$continuous_mode = Read-Host "Do you want to run in continuous mode? (y/n): "
if ($continuous_mode -eq "y") {
    $continuous_flag = "--continuous"
}
else {
    $continuous_flag = ""
}

$gpt3_only_mode = Read-Host "Do you want to use GPT-3 only? (y/n): "
if ($gpt3_only_mode -eq "y") {
    $gpt3_only_flag = "--gpt3only"
}
else {
    $gpt3_only_flag = ""
}

# Run Docker container
Write-Host "Starting Auto-GPT Docker container..."
docker run -it --env-file=./Auto-GPT/.env -v "${workspace_path}:/home/appuser/auto_gpt_workspace" auto-gpt $gpt3_only_flag $continuous_flag
