#!/bin/sh -xe
# Script to install Qt 6 in docker container

[ "$AQT_VERSION" ] || AQT_VERSION="3.3.0"
[ "$QT_VERSION" ] || QT_VERSION="6.8.3"
[ "$QT_PATH" ] || QT_PATH="/opt/Qt"
[ "$HOME" ] || HOME="/home/user"

apt update

echo '======================================================='
echo ' Save the original installed packages list'
echo '======================================================='
dpkg --get-selections | cut -f 1 > /tmp/packages_orig.lst
cat /tmp/packages_orig.lst

echo '======================================================='
echo ' Install the packages needed for the install'
echo '======================================================='
apt-get -y install --no-install-recommends \
    git \
    python3-pip \
    libglib2.0-0

echo '======================================================='
echo ' Install the python packages needed'
echo '======================================================='
pip3 install --break-system-packages --no-cache-dir aqtinstall=="${AQT_VERSION}"

echo '======================================================='
echo ' List some Qt-installation options'
echo '======================================================='
aqt list-qt --help
aqt list-qt linux desktop
aqt list-qt linux desktop --arch "${QT_VERSION}"
aqt list-qt linux desktop --archives "${QT_VERSION}" linux_gcc_64
aqt list-qt linux desktop --long-modules "${QT_VERSION}" linux_gcc_64
aqt list-tool linux desktop
aqt list-tool linux desktop tools_cmake --long
aqt list-tool linux desktop tools_qtcreator --long

echo '======================================================='
echo ' Install Qt, cmake, and qtcreator'
echo '======================================================='
aqt install-qt --base http://mirror.accum.se/mirror/qt.io/qtproject/ -O "$QT_PATH" linux desktop "$QT_VERSION" linux_gcc_64 -m qtserialport qt5compat qtpdf
aqt install-tool --base http://mirror.accum.se/mirror/qt.io/qtproject/ -O "$QT_PATH" linux desktop tools_cmake qt.tools.cmake
aqt install-tool --base http://mirror.accum.se/mirror/qt.io/qtproject/ -O "$QT_PATH" linux desktop tools_qtcreator qt.tools.qtcreator

echo '======================================================='
echo ' Remove python packages'
echo '======================================================='
pip3 freeze | grep -v setuptools | grep -v wheel | xargs pip3 uninstall -y --break-system-packages

echo '======================================================='
echo ' Remove the packages used during installation'
echo '======================================================='
dpkg --get-selections | cut -f 1 > /tmp/packages_curr.lst
grep -Fxv -f /tmp/packages_orig.lst /tmp/packages_curr.lst | xargs apt remove -y --purge
apt -qq clean
rm -rf /var/lib/apt/lists/*

echo '======================================================='
echo ' QtCreator preinitialization'
echo '======================================================='
mkdir -p /home/user/.config/QtProject/
if [ ! -f "${HOME}/.config/QtProject/QtCreator.ini" ]; then
    cat > "${HOME}/.config/QtProject/QtCreator.ini" << 'EOF'
[General]
SuppressedWarnings=TakeUITour
EOF
fi
