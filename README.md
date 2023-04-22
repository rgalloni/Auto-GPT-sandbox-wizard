# Auto-GPT Sandbox Wizard - Easy Installer

This script allows you to easily install and run the Auto-GPT application inside a Docker container. Running the application inside a Docker container provides a secure sandboxed environment, preventing any potential harm to your computer from continuous mode malfunctions. However, please note that you still need to supervise the application when running in continuous mode to avoid any unintended damage.

## UPDATE 22/09/2023

The following updates have been made:
- Now it works with official Docker file to future proof implementations
- It will keeps your Auto-GPT updated with the last release (if you ask for)
- Improved user interactions and information requests throughout the script

## Features
- Automatically installs Docker if not already installed
- Prompts for API keys and workspace folder path
- Clones the Auto-GPT repository and configures the environment
- Builds and runs the application inside a Docker container

## Requirements
In order to use the Auto-GPT Easy Installer, you will need an API key for OpenAI. You can obtain an OpenAI API key by following the instructions provided here: https://platform.openai.com/account/api-keys. You may need to edit your .env file to enable more features.

When you register for OpenAI, you will receive $18 in API credits, which provides ample room for testing and experimenting without incurring any costs. Simply follow the steps in the provided script to set up and run the Auto-GPT application inside a Docker container, ensuring a secure environment for your project.

## Installation and Usage
### Unix/Mac
1. Download the `auto_gpt_easy_install.sh` script.
2. Open a terminal and navigate to the directory where the script is located.
3. Make the script executable: `chmod +x auto_gpt_easy_install.sh`
4. Run the script: `./auto_gpt_easy_install.sh`

### Windows (currently untested)
1. Download the `auto_gpt_easy_install.ps1` script.
2. Open a PowerShell and navigate to the directory where the script is located.
3. Run the script: `.\auto_gpt_easy_install.ps1`

## For Users Without Git
If you do not have Git installed on your system, the script will attempt to install it using a suitable package manager. If this is not possible, you will need to install Git manually before running the script.

## Troubleshooting

1. If you encounter issues with Docker installation or permissions, please refer to the official [Docker documentation](https://docs.docker.com/get-docker/) for guidance.
2. If you have trouble installing Git, visit the official [Git documentation](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) for more information on installing Git on your system.
3. If you need further assistance, consider opening an issue on the [Auto-GPT GitHub repository](https://github.com/Significant-Gravitas/Auto-GPT).

## Notes

- The Auto-GPT application is designed to be run inside a Docker container for added security. However, you can still run the application outside the container if you prefer. Please refer to the [Auto-GPT GitHub repository](https://github.com/Significant-Gravitas/Auto-GPT) for more information on how to set up and run the application manually.
- Remember to supervise the application when running in continuous mode to avoid any unintended damage.
- The speech mode is not currently supported when running inside the Docker container.