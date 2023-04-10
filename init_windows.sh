#!/bin/sh

TZ="Europe/Warsaw"
DEBIAN_FRONTEND=noninteractive

apt update
apt install --yes markdown > /dev/null
cd /source

echo '<!DOCTYPE html>' > index.html
echo '<html lang="en-US">' >> index.html
cat docs/head.html >> index.html

echo '<body>' >> index.html
markdown README.md >> index.html
echo '</body>' >> index.html
echo '</html>' >> index.html

apt install --yes wine apt-utils tar wget > /dev/null
dpkg --add-architecture i386 && apt-get update > /dev/null && apt-get install --yes wine32 > /dev/null

py_deps_ticlock=""
for X in $(cat requirements.txt); do
    py_deps_ticlock=$py_deps_ticlock' --collect-all '$X
done

mkdir log
touch log/ticlock-main.txt

for X in $(find . -name '__pycache__'); do
    rm -rf "$X"
done

WINEPREFIX=/wine

wget https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe -O /installer.exe
wine /installer.exe /quiet InstallAllUsers=1 SimpleInstall=1
PYTHON_EXE_FILE=$(find /root -name python.exe | head -n 1)
wine $PYTHON_EXE_FILE -m pip install pyinstaller
wine $PYTHON_EXE_FILE -m pip install -r requirements.txt

wine $PYTHON_EXE_FILE -m pyinstaller -F --onefile --console \
 --additional-hooks-dir=. --add-data ./config.py;config.py --add-data ./modules/*;modules/ --add-data ./apps/*;apps/ \
  $py_deps_ticlock --add-data ./log/*;log/ -i ./docs/icon.png -n ticlock -c main.py

mv dist/ticlock.exe .
rm -rf dist build log

chmod +x ticlock.exe

sha256sum ticlock.exe > sha256sum.txt

mkdir -pv /runner/page/
cp -rv /source/* /runner/page/