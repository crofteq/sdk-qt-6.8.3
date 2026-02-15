FROM ubuntu:24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Noninteractive installs via apt-get to avoid questions
ARG DEBIAN_FRONTEND=noninteractive 

# Delete the default ubuntu user that is created in the base image
RUN userdel -r ubuntu || true

# Prepare for the user to be created at runtime
ENV USER=user
ENV HOME="/home/${USER}"
RUN mkdir -p "${HOME}"

# Install download tools
# ca-certificates               - needed for download
# curl                          - needed for download
# wget                          - needed for download
RUN apt-get update && apt-get -y install --no-install-recommends \
    ca-certificates=20* \
    curl=8.5.* \
    wget=1.21.* \
    && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    update-ca-certificates

# Install Just - the command runner
ARG JUST_VERSION=1.45.0
# COPY install_just.sh /tmp/
# RUN chmod a+x /tmp/install_just.sh && /tmp/install_just.sh --tag ${JUST_VERSION} --to /usr/local/bin
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --tag ${JUST_VERSION} --to /usr/local/bin

ARG AQT_VERSION=3.3.0
ARG QT_VERSION=6.8.3
ARG QT_PATH=/opt/Qt

ENV DEBCONF_NONINTERACTIVE_SEEN=true \
    AQT_VERSION=${AQT_VERSION} \
    QT_VERSION=${QT_VERSION} \
    QT_PATH=${QT_PATH} \
    QT_GCC=${QT_PATH}/${QT_VERSION}/gcc_64 \
    PATH=${QT_PATH}/Tools/CMake/bin:${QT_PATH}/Tools/QtCreator/bin:${QT_PATH}/${QT_VERSION}/gcc_64/bin:$PATH

# Install Qt
COPY install_qt.sh /tmp/
RUN chmod a+x /tmp/install_qt.sh && /tmp/install_qt.sh

# Install Qt dependencies
ARG ADDITIONAL_PACKAGES="libgl1-mesa-dev libglu1-mesa-dev libxkbcommon-dev libvulkan-dev locales"
COPY install_qt_dependencies.sh /tmp/
RUN chmod a+x /tmp/install_qt_dependencies.sh && /tmp/install_qt_dependencies.sh

# Install linuxdeploy dependencies
# appstream - needed by appimage tool
# file - needed by appimage tool
# gpg - needed by appimage tool
RUN apt-get update && apt-get -y install --no-install-recommends \
    appstream=1.0.* \
    file=1:5.* \
    gpg=2.4.* \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and install linuxdeploy and appimagetool
RUN wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage -O /usr/local/bin/linuxdeploy && \
    chmod +x /usr/local/bin/linuxdeploy && \
    wget -q https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage -O /usr/local/bin/linuxdeploy-plugin-qt && \
    chmod +x /usr/local/bin/linuxdeploy-plugin-qt && \
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O /usr/local/bin/appimagetool && \
    chmod +x /usr/local/bin/appimagetool

# Setup the UTF-8 locale to avoid complaints from QtCreator
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Setup this parameter to avoid complaints from QtCreator
ENV XDG_RUNTIME_DIR=/tmp/runtime-user

# Install basic build tools
# git               - needed during building
# gosu              - needed to change user in runtime
# inkscape          - needed to generate icons from svg
# p7zip-full        - needed to unpack and pack archives using 7z
# ripgrep           - nice to have searchtool
# sudo              - needed to be able to run as root
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential=12.10* \
    git=1:2.43.* \
    gosu=1.17-1* \
    inkscape=1.2.* \
    p7zip-full=16.02* \
    ripgrep=14.1.* \
    sudo=1.9.* \
    && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    # turn the detected dubious ownership message off
    git config --global --add safe.directory '*' && \
    # turn the detached message off
    git config --global advice.detachedHead false

# Install the windows environment (wine64), git, qt
# aqt                   - another qt installer (https://aqtinstall.readthedocs.io/en/latest/)
#                         Note: The --base option to aqt should be possible to be omitted, but
#                         there were some download issues from time to time during development.
# git                   - git for windows
# wine32, wine64        - the windows environment
ARG AQT_URL=
ARG QT_PATH_WIN=C:\\Qt
ENV WINEDEBUG=-all
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get -y install --no-install-recommends \
    wine64=9.* \
    wine32=9.* \
    && ln -s /usr/lib/wine/wine64 /usr/local/bin/wine && \
    # install git for windows
    curl -k -fLs "https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/PortableGit-2.52.0-64-bit.7z.exe" -o /tmp/git.exe && \
    7z x /tmp/git.exe -o/home/user/.wine/drive_c/git && \
    rm -rf /tmp/git.exe && \
    # install qt for windows using aqt
    curl -k -fLs "https://github.com/miurahr/aqtinstall/releases/download/v${AQT_VERSION}/aqt.exe" -o /tmp/aqt.exe && \
    wine /tmp/aqt.exe list-qt --help && \
    wine /tmp/aqt.exe list-qt windows desktop && \
    wine /tmp/aqt.exe list-qt windows desktop --arch "${QT_VERSION}" && \
    wine /tmp/aqt.exe list-tool windows desktop && \
    wine /tmp/aqt.exe install-qt --base http://mirror.accum.se/mirror/qt.io/qtproject/ -O "${QT_PATH_WIN}" windows desktop "${QT_VERSION}" win64_mingw -m qtserialport qt5compat qtpdf && \
    wine /tmp/aqt.exe install-tool --base http://mirror.accum.se/mirror/qt.io/qtproject/ -O "${QT_PATH_WIN}" windows desktop tools_mingw1310 && \
    wine /tmp/aqt.exe install-tool --base http://mirror.accum.se/mirror/qt.io/qtproject/ -O "${QT_PATH_WIN}" windows desktop tools_cmake && \
    # cleanup
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/aqt.exe /tmp/wine-* && \
    chmod -R 777 ~/.wine

COPY .bashrc .bash_history ${HOME}/

WORKDIR "${HOME}/work"

# Call a script to dynamically create the user at runtime
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash"]
