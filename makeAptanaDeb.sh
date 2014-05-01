#!/usr/bin/env bash
## Name:   makeAptanaDeb.sh
## Author: Jim T. Tang(maxubuntu@gmail.com)
## Date:   2013.1.8
## Description: This script is to help Debian/Ubuntu-like users 
## to install Aptana Studio in a more practical way.
## Usage:  makeAptanaDeb.sh Aptana_Studio_3_Setup_Linux_x86_64_3.4.2.zip

#################
## file reader ##
#################
if [ "$1" == "" ]; then
	read -p "please specify path to the Aptana ZIP file: " filename
	filename=$filename
else
	filename=$1
fi

##################
## mime checker ##
##################
grep 'zip' $filename > /dev/null 2>&1
[ $? -eq 0 ] || { echo "file suffix must be in zip. exit now."; exit 2; }

file --mime-type -b $filename | grep 'zip' > /dev/null 2>&1
[ $? -eq 0 ] || { echo "MIME type be in zip. exit now."; exit 2; }

##################
## bold setting ##
##################
bold=`tput bold`
normal=`tput sgr0`

###########################
## file name transformer ##
###########################
## Aptana_Studio_3_Setup_Linux_x86_64_3.4.2.zip -- > AptanaStudio_3.4.2_amd64.deb
package=AptanaStudio
file=$(basename $filename)
version=$(basename $file .zip| awk -F_ '{print $NF}')
rPackage=$(basename $file .zip| awk -F_ '{print $1, $2, $3}')
grep 'x86_64' $filename > /dev/null 2>&1
[ $? -eq 0 ] && { arch=amd64; } || { arch=i586; }
dirName=${package}_${version}_${arch}
dataName=$(unzip -l $filename | grep "        0" | head -n1 | awk '{print $4}'| sed 's/\///')
#################
## preparation ##
#################
[ ! -d "$dirName" ] && {
        mkdir -p $dirName/{DEBIAN,opt}
} || {
        echo $dirName exists. Mission aborts.
        exit 0;
}

####################################
## copy contents and build deb... ##
####################################
echo -n "${bold}Phase1: copying files...${normal}"
sudo unzip $filename -d $dirName/opt > /dev/null
echo -e "done...\n"

echo -n "${bold}Phase2: preparing required files...${normal}"
cat << END > $dirName/DEBIAN/control
Package: $package
Version: $version
Section: editors
Homepage: http://www.aptana.com
Architecture: $arch
Priority: optional
Maintainer: Aptana
Pre-Depends: dpkg (>= 1.14.0)
Depends: java-runtime
Description: Aptana Studio $version is our code base and complete environment that includes extensive capabilities to build Ruby and Rails, PHP, and Python applications, along with complete HTML, CSS and JavaScript editing.
END
echo -n "done..."

cat << END > $dirName/DEBIAN/postinst
#!/bin/bash
if [ "\$1"="configure" ]; then
  if [ -e "/usr/bin/AptanaStudio3" ]; then
    rm -rf "/usr/bin/AptanaStudio3";
    ln -sf "/opt/$dataName/AptanaStudio3" /usr/bin/
  fi
fi

cat << HERE > "/usr/share/applications/${rPackage}.desktop"
[Desktop Entry]
Version=$version
Type=Application
Terminal=false
Exec="/opt/$dataName/AptanaStudio3"
Name=$rPackage
Icon=/opt/$dataName/icon.xpm
Categories=Development
HERE

ln -s "/opt/$dataName/AptanaStudio3" /usr/bin/

END
echo -n "done..."

cat << END > $dirName/DEBIAN/prerm
#!/bin/bash
if [ "\$1"="upgrade" -o "\$1"="remove" ]; then
  rm -rf /opt/$dataName
  rm -f /usr/bin/AptanaStudio3
  rm -f "/usr/share/applications/${rPackage}.desktop"
fi

END
echo -e "done...\n"
chmod +x $dirName/DEBIAN/*


echo  "${bold}Phase3: making ${dirName}.deb,${normal} this may take a whilst... "
sudo dpkg-deb --build $dirName > /dev/null || { echo exit; exit 2; }
sudo chown $(id -un):$(id -gn) $dirName.deb
sudo rm -r $dirName

echo "${bold}$dirName.deb ${normal}has been done."
exit 0

