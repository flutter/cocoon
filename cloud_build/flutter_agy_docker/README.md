# Flutter Antigravity Docker Environment

This folder contains the files necessary to build and run a highly opinionated Docker container, designed to get a developer up and running with Antigravity in a sandbox instantly.

Below are step-by-step instructions for getting started.

## 1. (Optional) Building the Docker Image Locally

> **Important Platform Note:** Flutter does not fully support `linux/arm64` yet. If you are on an Apple Silicon (M1/M2/M3) machine, you *must* set the platform to `linux/amd64` when building and running.

### For x86 / Intel:
```shell
podman build -t flutter_docker .
```

### For Apple Silicon (using podman):
```shell
podman build --platform linux/amd64 -t flutter_docker .
```

### Building a specific Flutter version:
You can override the default Flutter version using the `FLUTTER_VERSION` build argument.
```shell
podman build --platform linux/amd64 --build-arg FLUTTER_VERSION=3.45.0 -t flutter_docker:3.45.0 .
```

## 2. Running the Docker Image Locally

You can run the container in any project folder. The current working directory (`$PWD`) will be mapped to `/app` inside the container.

### For x86 / Intel:
```shell
podman run --userns=keep-id:uid=1000,gid=1000 -it \
  -v ".:/app:z" \
  -v "dart_tool_cache:/app/.dart_tool" \
  -v "dart_build_cache:/app/build" \
  -v "$USER/.gemini:/home/coder/.gemini:z" \
  flutter_docker:latest
```

### For Apple Silicon (using podman):
```shell
podman run --platform linux/amd64 --userns=keep-id:uid=1000,gid=1000 -it \
  -v "${PWD}:/app:z" \
  -v "dart_tool_cache:/app/.dart_tool" \
  -v "dart_build_cache:/app/build" \
  -v "$USER/.gemini:/home/coder/.gemini:z" \
  flutter_docker:latest
```

## 3. Pulling the Pre-built Image (Flutter Staff Only)

If you are a member of the Flutter staff, you can pull the image directly from the Google Cloud registry without building it locally.

```shell
gcloud auth login
gcloud config set project flutter-infra
gcloud auth configure-docker us-docker.pkg.dev
podman pull us-docker.pkg.dev/flutter-infra/flutter-infra/flutter_docker:latest
```

## 4. Setting up Docker Compose and Shell Functions

For a more convenient workflow, you can set up `docker-compose.yml` and shell aliases to easily start and attach to background containers.

### Install `docker-compose.yml`
Create the destination directory if it doesn't exist, and copy the compose file there:
```shell
mkdir -p ~/.config/coder-env
cp docker-compose.yml ~/.config/coder-env/
```

### Install Shell Functions
Copy the contents of `functions.sh` into your `~/.bashrc` or `~/.zshrc`:
```shell
cat functions.sh >> ~/.zshrc
source ~/.zshrc
```
*(Use `~/.bashrc` if you are using Bash)*

Once configured, you can use these shortcuts in any project folder:
* `coder-up`: Starts the development environment in the background.
* `coder-attach`: Attaches to the active `tmux` session in the container.
* `coder-down`: Stops and tears down the container.

## 5. Connecting via SSH to a Remote Container

If you are running the Docker/Podman container on a remote machine, you can connect to the internal `tmux` session directly using SSH:

```shell
ssh -t <user>@<hostname> "podman exec -it -t <container-name> tmux attach"
```

## 6. Connecting with VS Code

You can use Visual Studio Code to connect directly to the running container, whether it's running locally or remotely.

### Prerequisites
Install the following extensions in VS Code:
* **Dev Containers** (`ms-vscode-remote.remote-containers`)
* **Remote - SSH** (`ms-vscode-remote.remote-ssh`) *(required for remote connections)*

### Attaching to a Local Container
1. Start your container (e.g., using `coder-up`).
2. Open the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`).
3. Select **Dev Containers: Attach to Running Container...**
4. Choose the running `flutter_docker` container from the list.

### Attaching to a Remote Container
1. Open the Command Palette and select **Remote-SSH: Connect to Host...**
2. Connect to your remote machine `<user>@<hostname>`.
3. Once the SSH connection is established, open the Command Palette again.
4. Select **Dev Containers: Attach to Running Container...**
5. Choose the running container on the remote machine.

## 7. FAQ & Troubleshooting

### Using Git Worktrees

When using Git worktrees with this container, you must configure Git to use relative paths. Failure to do so will result in broken worktree references because absolute paths differ between your host machine and the container.

To configure Git to use relative paths, run the following command on your **host machine** (not inside the container):

```shell
git config --global worktree.useRelativePaths true && git worktree repair
```

After repairing, ensure you run `podman run` (or `coder-up`) from the **root of the worktree** so that the container mounts the correct paths.
