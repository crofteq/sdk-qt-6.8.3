set shell := ["bash", "-ec"]

container_image := "sdk/qt/6.8.3:latest"

_default:
  @just --list

# Build the container image
build:
  #!/usr/bin/env bash

  # Sanity check of Dockerfile before build
  lint_config=""
  if [ -f ./hadolint.yaml ]; then
      # Expose config file to hadolint docker if it exists
      lint_config="-v ./hadolint.yaml:/.config/hadolint.yaml"
  fi
  docker run --rm -i ${lint_config} hadolint/hadolint:v2.12.0 < ./Dockerfile

  docker build --progress plain --tag {{container_image}} .

# Start and enter the container
[no-exit-message]
start:
  docker run \
    --rm -it \
    -e USER_ID=$(id -u) \
    -e GROUP_ID=$(id -g) \
    -v .:/home/user/work:rw,z \
    --workdir /home/user/work \
    --env DISPLAY \
    --device /dev/bus/usb \
    --device /dev/dri \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v ${HOME}/.Xauthority:/home/user/.Xauthority:rw \
    {{container_image}}

# Returns the current apt package
get-package-version package:
  #!/usr/bin/env bash

  # Create a temporary directory
  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT

  # Write Dockerfile content as a string
  cat <<EOF > "${temp_dir}/Dockerfile"
  FROM ubuntu:24.04
  RUN apt-get update && apt-get install -y --no-install-recommends {{package}}
  CMD ["apt", "policy", "{{package}}"]
  EOF

  # Build the Docker image
  docker build -t get_package_version_{{package}} "$temp_dir"
  docker run --rm get_package_version_{{package}}
  docker rmi get_package_version_{{package}}
