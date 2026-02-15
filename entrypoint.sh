#!/bin/bash

# Get the user and group IDs from the environment variables
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}

# Create the group and user with the specified IDs
groupadd -g ${GROUP_ID} ${USER}
useradd -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash ${USER}

# Add the user to the sudoers file
echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Change ownership of the home directory to the created user
# chown -R ${USER}:${USER} /home/${USER}
# Skip the ~/.wine folder, to save time, since it already is fully read/writable.
find /home/${USER}/ -path "/home/${USER}/.wine" -prune -o -exec chown ${USER}:${USER} {} +
# make sure that the 'user' owns the .wine folder, otherwise wine calls will fail.
chown ${USER}:${USER} /home/${USER}/.wine

# Switch to the created user and execute the command
exec gosu ${USER} "$@"
