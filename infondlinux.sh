#!/bin/sh
# script config infondlinux
# distributed under New BSD Licence
# created by t0ka7a
# version 0.2
# this script makes a post-installation on Ubuntu
# careful: the script stops firefox if it is running.

# debian packages
# - vim 
# - less 
# - gimp 
# - wipe 
# - xchat 
# - pidgin 
# - vlc 
# - nautilus-open-terminal
# - nmap
# - sun-java6-plugin et jre
# - bluefish
# - flash-plugin-nonfree
# - aircrack-ng
# - wireshark
# - ruby
# - ascii
# - httrack
# - socat
# - nasm
# - w3af

# third party packages
# - tor
# - virtualbox 3.2

# manually downloaded softwares and version
# - dirBuster-1.0-RC1 2009-02-27
# - truecrypt-7.0-linux-x86
# - metasploit framework 3.4.1-linux-i386
# - webscarab
# - burp suite v1.3.03
# - paros 3.2.13
# - jmeter 2.4

# home made scripts
# - hextoasm

# firefox extensions
# - livehttpheaders 
# - firebug 
# - tamperdata 
# - noscript 
# - flashblock 
# - flashgot 
# - foxyproxy
# - useragentswitcher

######################################################
# trick to know: to share the current directory:
# $ sudo python -m SimpleHTTPServer 8080
######################################################

#####################################
# function log()
#####################################
# write in /usr/share/infond/log/install.log
# @param1: type '+' or 'E' or 'I'
# @param2: 'message' 
log() (
  echo $1": $(date +%D' '%R':'%S) "$2 >> /usr/share/infond/log/install.log
  echo $1": $(date +%D' '%R':'%S) "$2 > /dev/stdout
)

###########################
# function addBinEntry()
###########################
# adds a file .sh with the command line in the application directory
# adds a symbolic link in /usr/bin
# param1: name of the application
# param2: command line
# param3: term (default=NULL). To start the application in a new term 
# ex: addBinEntry dirbuster "java -jar /usr/share/infond/bin/DirBuster-1.0-RC1/DirBuster-1.0-RC1.jar" term
#     creates a file dirbuster.sh in /usr/share/infond/bin
addBinEntry() (
  # exit if file already in /usr/bin
  if [ -z $(ls /usr/share/infond/bin | grep $1.sh ) ]; then
    echo "#!/bin/sh" > /usr/share/infond/bin/$1.sh
    echo "\n\
# $1.sh\n\
# generated by infond post installation infond\n\
# launcher to start $1 in a terminal\n\
# a symbolic link was created in /usr/bin\n" >> /usr/share/infond/bin/$1.sh

    # run application from terminal if $4 set to 'term'
    if ( [ ! -z $3 ] && [ $3 = 'term' ] ); then 
      echo "gnome-terminal --title=$1 --working-directory=\"/tmp\" --command=\"$2\"" >> /usr/share/infond/bin/$1.sh
    else
      echo "$2" >> /usr/share/infond/bin/$1.sh
    fi

    # log
    log "+" "$1.sh created in /usr/share/infond/bin/."

    # make $1.sh executable
    chmod +x /usr/share/infond/bin/$1.sh 
    log "+" "$1.sh chmod +x"

  else
    log "I" "$1 already in /usr/share/infond/bin. Not added."
  fi

  # create symbolic link in /usr/bin
  if [ -z $(ls /usr/bin | grep $1.sh ) ]; then
    ln -s /usr/share/infond/bin/$1.sh /usr/bin/$1
    log "+" "symbolic link to $1.sh created in /usr/bin/."
  else
    log "I" "$1 already in /usr/bin. Not added." && return 1
  fi
)

#####################################
# function aptremove()
#####################################
# remove package using apt
aptremove() ( 
  # if package not installed
  [ -z $(	dpkg --list $1 | grep ii) ] && log "I" "$1 not installed. can't be removed" && return 1
  # remove package
  apt-get --auto-remove -y --allow-unauthenticated remove $1
  # if package well removed
  [ -z $(dpkg --list $1 | grep ii) ] && log "+" "$1 removed"   
)

#####################################
# function aptinstall()
#####################################
# install package using apt
aptinstall() (
  # if package already installed 
  [ ! -z "$(dpkg --list $1 | grep ii)" ] && log "I" "$1 already installed. can't be installed" && return 1
  # install package
  apt-get --auto-remove -y --allow-unauthenticated install $1 
  # if package well installed
  [ ! -z "$(dpkg --list $1 | grep ii)" ] && log "+" "$1 installed"
)

#################################
# function firefoxadd()
#################################
# download firefox extension .xpi into /usr/lib/firefox-addons/extensions
# firefox will install it at next sudo start
# @param1: name of the extension
# @param2: number of extension on addons.mozilla.org 
firefoxadd() (
  if [ -z "$(ls -R /usr/lib/firefox-addons/extensions | grep $1)" ]; then 
    wget https://addons.mozilla.org/en-US/firefox/downloads/latest/$2/addon-$2-latest.xpi -nc -P /usr/lib/firefox-addons/extensions
    log "+" "$1 ready to install."
  else
   log "I" "$1 already installed. .xpi not downloaded."
  fi
)

###########################
# function downloadicon()
###########################
# download picture and create icon
# @param1: name for the icon
# @param2: downloading address
# ex: downloadicon msf http://metasploit.com/icon.jpg
downloadicon() (
  if [ -z "$(ls /usr/share/infond/pictures | grep $1.png )" ]; then
    wget $2 -P /tmp
    convert -size 48x48 /tmp/$(echo $2|awk -F/ '{print $NF}') -resize 48x48 -extent 48x48 +profile '*' /usr/share/infond/pictures/$1.png
    log "+" "$1 icon downloaded"
    rm /tmp/$(echo $2|awk -F/ '{print $NF}')
  else
    log "I" "$1 icon already exists. Not downloaded."
  fi
)

###########################
# function addmenu()
###########################
# add an entry to gnome menu
# @param1: name
# @param2: comment
# @param3: command line
# @param4: terminal (true or false)
# @param5: categorie
addmenu() (
  if [ -z "$(ls /usr/share/applications | grep $1.desktop)" ];then
    echo "
[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=$1
Comment=$2
Icon=/usr/share/infond/pictures/$1.png
Exec=$3
Terminal=$4
Categories=$5
" > /usr/share/applications/$1.desktop
    log "+" "$1.desktop created"
  else
    log "I" "$1.desktop already exists. Not updated."
  fi
)


###########################
# function addcategory()
###########################
# add a category to .desktop file
# @param1: name
# @param2: category
addcategory() (
[ -z $(cat /usr/share/applications/$1.desktop | grep $2) ] && sed -i "/Categories/s|$|$2;|" /usr/share/applications/$1.desktop
)

#####################################
# installation start
#####################################
# test sudo
[ $(id -u) -ne "0" ] && echo "You must be sudo to use this script." && exit 1

# mode verbose
#set -v
1>/dev/null
2>/dev/null

# catch CTRL-C
trap "echo ''; echo CTR-C was pressed. Exit; log 'E' 'CTRL-C pressed.; exit 1" 2

# create log file if not already created
echo "****************" >> /usr/share/infond/log/install.log
log "+" "install begin"
echo "****************" >> /usr/share/infond/log/install.log

# create install directory
if [ -z "$(ls /usr/share | grep infond)" ]; then
  mkdir /usr/share/infond
  mkdir /usr/share/infond/bin
  mkdir /usr/share/infond/pictures
  mkdir /usr/share/infond/log
  log "+" "/usr/share/infond and subdirectories created"
else
  log "I" "directory /usr/share/infond already exists. Not updated."
fi

##############################
# 1st start
###############################

# if dist-upgrade not done yet
if [ -z "$(cat /usr/share/infond/log/install.log | grep dist-upgrade )" ]; then

  # dist-upgrade
  apt-get --auto-remove -y --allow-unauthenticated dist-upgrade

  # update log
  log "+" "dist-upgrade"

  # reboot
  echo "System will reboot. Please restart script after reboot"
  read pause 

  # reboot
  log "I" "reboot"
  reboot
fi

#################################
# apt
#################################

# tor
if [ -z "$(cat /etc/apt/sources.list | grep torproject)" ]; then
  echo "" >> /etc/apt/sources.list
  echo "## tor" >> /etc/apt/sources.list
  echo "deb http://deb.torproject.org/torproject.org lucid main" >> /etc/apt/sources.list
  gpg --keyserver keys.gnupg.net --recv 886DDD89
  gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -
  apt-get update
  log "+" "tor added to apt sources list"
else
  log "I" "tor already in apt sources list. Not added"
fi

# update
apt-get update > /dev/null
log "+" "apt-get update"
apt-get upgrade
log "+" "apt-get upgrade"

# apt remove useless packages
aptremove gwibber
aptremove empathy
aptremove gbrainy
aptremove f-spot
aptremove evolution
aptremove quadrapassel
aptremove totem

# apt install
aptinstall vim
aptinstall less
aptinstall gimp
aptinstall tor
aptinstall vlc
aptinstall nautilus-open-terminal
aptinstall sun-java6-plugin 
aptinstall flashplugin-nonfree
aptinstall bluefish
aptinstall xchat
aptinstall pidgin
aptinstall ruby
aptinstall nasm

# add category to .desktop
addcategory bluefish Accessories
addcategory xchat Accessories
addcategory pidgin Accessories

##################################
# menu GNOME
##################################

# see $ gnome-help , (search for keyword ".desktop")

# add pictures (if not already in directory)
downloadicon infond http://3.bp.blogspot.com/_Jna6k5HsSu4/TDH4lKIz1cI/AAAAAAAAAHc/a-P6uy2wHjI/s1600/infond48x48.jpg
downloadicon pentest http://3.bp.blogspot.com/_Jna6k5HsSu4/TDMceNplaqI/AAAAAAAAAHs/iWG1MOPS0uw/s320/pentest.png

# add directory entries in /usr/share/infond/desktop-directories
if [ -z "$(ls /usr/share/desktop-directories | grep Infond.directory)" ]; then
  echo "[Desktop Entry]
Name=Infond
Comment=Security tools
Icon=/usr/share/infond/pictures/infond.png
Type=Directory
Categories=Pentest
" > /usr/share/desktop-directories/Infond.directory
  log "+" "Infond.directory written"
else
  log "I" "Infond.directory already exists. Not updated."
fi

if [ -z "$(ls /usr/share/desktop-directories | grep Pentest.directory)" ]; then
  echo "[Desktop Entry]
Name=Pentest
Icon=/usr/share/infond/pictures/pentest.png
Comment=Network pentest oriented applications
Type=Directory
" > /usr/share/desktop-directories/Pentest.directory
  log "+" "Pentest.directory written"
else
  log "I" "Pentest.directory already exists. Not updated."
fi

# modify /etc/xdg/menus/applications.menu
# the directory /etc/xdg is in $XDG_CONFIG_DIRS (see $ gnome-help)
if [ -z "$( cat /etc/xdg/menus/applications.menu | grep Infond.directory )" ]; then
  sed -i '/<!-- Accessories submenu -->/i\
  \
  <!-- Infond submenu -->\
  <Menu>\
    <Name>Infond</Name>\
    <Directory>Infond.directory</Directory>\
    <Menu>\
      <Name>Pentest</Name>\
      <Directory>Pentest.directory</Directory>\
      <Include>\
        <And>\
          <Category>Pentest</Category>\
        </And>\
      </Include>\
    </Menu>\
    <Menu>
      <Name>Accessories</Name>
      <Directory>Utility.directory</Directory>
      <Include>
        <And><Category>Accessories</Category></And>
      </Include>
    </Menu>
  </Menu>\
  ' /etc/xdg/menus/applications.menu
  log "+" "applications.menu modified"
else
  log "I" "applications.menu already correct. Not modified."
fi

##################################
# nmap
##################################

# apt install
aptinstall nmap

# download icon
downloadicon nmap http://www.ansi.tn/gfx/nmap.png

# add entry in Gnome menu
addmenu nmap "Nmap (\"Network Mapper\") is a free and open source utility for network exploration or security auditing." "bash -c 'cd /tmp;nmap -h;nmap -V;bash'" "true" "Pentest"

##################################
# w3af
##################################

# apt install
aptinstall w3af

# add entry in Gnome menu
addcategory w3af Pentest

##################################
# hextoasm
##################################
# script to print asm instructions from a hex string
echo 'usage() (
  echo "********************************************************"
  echo "* script adapted from a tip by ivanlef0u               *"
  echo "* written by t0ka7a for infondlinux                    *"
  echo "* http://infond.blogspot.com                           *"
  echo "*                                                      *"
  echo "* prints asm instructions from an hex strings          *"
  echo "*                                                      *"
  echo "* ex:                                                  *"
  echo "* $ hextoasm "\x90\x31\x90\x90\xea\x42\x42\x42"        *"
  echo "* 00000000  90                nop                      *"
  echo "* 00000001  319090EA4242      xor \eax+0x4242ea90],edx *"
  echo "* 00000007  42                inc edx                  *"
  echo "********************************************************"
  echo
)

# help
[ $1 = "-h" ] && usage && exit 0

# test nb of arguments
[ $# != 1 ] && echo one argument needed && exit -1

# test nasm installed
[ -z "$(dpkg --list nasm | grep ii)" ] && echo "please install nasm:  apt-get install nasm" && exit -1

python -c "print \"$1\"" | tr -d "\r\n" | ndisasm -u -
' > /usr/share/infond/bin/hextoasm
chmod +x /usr/share/infond/bin/hextoasm
ln -s /usr/share/infond/bin/hextoasm /usr/bin/hextoasm

# download icon
downloadicon hextoasm http://info.sio2.be/python/1/images/assembler.png
 
# add entry in Gnome menu for DirBuster
addmenu hextoasm "prints asm instructions from an hex strings ." "bash -c 'cd /tmp;hextoasm -h;bash'" "true" "Accessories"

##################################
# dirBuster-1.0-RC1 2009-02-27
##################################

# install
if [ -z "$(ls /usr/share/infond/bin | grep DirBuster)" ]; then
  wget "http://sourceforge.net/projects/dirbuster/files/DirBuster%20%28jar%20%2B%20lists%29/1.0-RC1/DirBuster-1.0-RC1.tar.bz2/download" -nc -P /tmp
  tar xjvf /tmp/DirBuster* -C /usr/share/infond/bin
  rm /tmp/DirBuster-1.0-RC1.tar.bz2
  log "+" "dirbuster downloaded"
else
  log "I" "dirbuster already in /usr/share/infond/bin. Not downloaded."
fi

# download icon
downloadicon dirbuster http://a.fsdn.com/con/icons/di/dirbuster@sf.net/ologo.gif 

# create dirbuster.sh and add dirbuster.sh shortcut in /usr/bin
addBinEntry dirbuster "java -jar /usr/share/infond/bin/DirBuster-1.0-RC1/DirBuster-1.0-RC1.jar"

# add entry in Gnome menu for DirBuster
addmenu dirbuster "DirBuster is a multi threaded java application designed to brute force directories and files names on web/application servers. Often is the case now of what looks like a web server #in a state of default installation is actually not, and has pages and applications hidden within. DirBuster attempts to find these." dirbuster "true" "Pentest"

##################################
# burp suite 1.3.03
##################################

# install
if [ -z "$(ls /usr/share/infond/bin | grep burp)" ]; then
  rm -r /tmp/burp*
  wget "http://portswigger.net/suite/burpsuite_v1.3.03.zip" -nc -P /tmp
  unzip /tmp/burp* -d /tmp
  rm /tmp/burp*.zip
  mv /tmp/burp* /usr/share/infond/bin/burp/
  rm -r /tmp/burp*
  log "+" "burp downloaded"
else
  log "I" "burp already in /usr/share/infond/bin. Not downloaded."
fi

# download icon
downloadicon burp http://www.crazynfunny.com/wp-content/uploads/2010/05/how-to-burp-on-command.gif 

# create burp.sh and add burp.sh shortcut in /usr/bin
addBinEntry burp "java -jar /usr/share/infond/bin/burp/burp*.jar"

# add entry in Gnome menu
addmenu burp "Burp Suite is free to use for personal and commercial purposes." burp "true" "Pentest"

##################################
# webscarab
##################################

# install
if [ -z "$(ls /usr/share/infond/bin | grep webscarab)" ]; then
  rm -r /tmp/webscarab*
  wget "http://dawes.za.net/rogan/webscarab/webscarab-current.zip" -nc -P /tmp
  unzip /tmp/webscarab-current.zip -d /tmp
  rm /tmp/webscarab-current.zip
  mv /tmp/webscarab* /usr/share/infond/bin/webscarab/
  rm -r /tmp/webscarab*
  log "+" "webscarab downloaded"
else
  log "I" "webscarab already in /usr/share/infond/bin. Not downloaded."
fi

# download icon
downloadicon webscarab http://www.owasp.org/skins/monobook/ologo.gif 

# create webscarab.sh and add webscarab.sh shortcut in /usr/bin
addBinEntry webscarab "java -jar /usr/share/infond/bin/webscarab/webscarab.jar"

# add entry in Gnome menu
addmenu webscarab "WebScarab is a framework for analysing applications that communicate using the HTTP and HTTPS protocols." webscarab "true" "Pentest"

##################################
# jmeter 2.4
##################################

# install
if [ -z "$(ls /usr/share/infond/bin | grep jmeter)" ]; then
  rm -r /tmp/jmeter*
  wget "http://apache.crihan.fr/dist/jakarta/jmeter/binaries/jakarta-jmeter-2.4.tgz" -nc -P /tmp
  tar xzf /tmp/jakarta-jmeter-2.4.tgz -C /tmp
  rm /tmp/*jmeter*.tgz
  mkdir /usr/share/infond/bin/jmeter
  mv /tmp/*jmeter* /usr/share/infond/bin/jmeter/
  log "+" "jmeter downloaded"
else
  log "I" "jmeter already in /usr/share/infond/bin. Not downloaded."
fi

# download icon
downloadicon jmeter http://jakarta.apache.org/jmeter/images/logo.jpg 

# create webscarab.sh and add webscarab.sh shortcut in /usr/bin
addBinEntry jmeter "java -jar /usr/share/infond/bin/jmeter/jakarta-jmeter-2.4/bin/ApacheJMeter.jar"

# add entry in Gnome menu
addmenu jmeter "Apache JMeter may be used to test performance both on static and dynamic resources (files, Servlets, Perl scripts, Java Objects, Data Bases and Queries, FTP Servers and more). It can be used to simulate a heavy load on a server, network or object to test its strength or to analyze overall performance under different load types. You can use it to make a graphical analysis of performance or to test your server/script/object behavior under heavy concurrent load." jmeter "true" "Pentest"


##################################
# truecrypt-7.0-linux-x86
##################################

#install
if [ -z "$(ls /usr/share/infond/bin | grep truecrypt)"  ];then
  wget http://www.truecrypt.org/download/truecrypt-7.0-linux-x86.tar.gz -nc -P /tmp
  log "+" "truecrypt-7.0 downloaded"
  tar xzf /tmp/truecrypt-7.0-linux-x86.tar.gz -C /usr/share/infond/bin/
  rm /tmp/truecrypt-7.0-linux-x86.tar.gz
  /usr/share/infond/bin/truecrypt-7.0-setup-x86
  log "+" "truecrypt-7.0 installed"
else
  log "I" "truecrypt-7.0 already downloaded. Not updated."
fi

# add category to gnome menu
addcategory truecrypt Accessories


##################################
# virtualbox 3.2
##################################

# add non-free repository to apt
if [ -z "$(cat /etc/apt/sources.list | grep virtualbox)" ]; then
  echo "" >> /etc/apt/sources.list
  echo "## virtualbox" >> /etc/apt/sources.list
  echo "deb http://download.virtualbox.org/virtualbox/debian lucid non-free" >> /etc/apt/sources.list
  wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | apt-key add -
  apt-get update
  log "+" "virtualbox added to apt sources list"
else
  log "I" "virtualbox already in apt sources list. Not added"
fi

# apt install
aptinstall virtualbox-3.2

# add virtualbox to gnome infond menu
addcategory virtualbox Accessories


##################################
# - paros 3.2.13
##################################

# install
if [ -z "$(ls /usr/share/infond/bin | grep paros)" ]; then
  rm -r /tmp/paros*
  wget "http://downloads.sourceforge.net/project/paros/Paros/Version%203.2.13/paros-3.2.13-unix.zip" -nc -P /tmp
  unzip /tmp/paros*.zip -d /tmp
  rm /tmp/paros*.zip
  mv /tmp/paros* /usr/share/infond/bin/paros/
  log "+" "paros downloaded"
else
  log "I" "paros already in /usr/share/infond/bin. Not downloaded."
fi

# download icon
downloadicon paros http://securitytnt.com/wp-content/uploads/2007/03/paros.png 

# create paros.sh and paros.sh shortcut in /usr/bin
addBinEntry paros "cd /usr/share/infond/bin/paros;java -jar paros.jar"

# add entry in Gnome menu
addmenu paros "A Java based HTTP/HTTPS proxy for assessing web application vulnerability. It supports editing/viewing HTTP messages on-the-fly. Other featuers include spiders, client certificate, proxy-chaining, intelligent scanning for XSS and SQL injections etc. " paros "true" "Pentest"


##################################
# - metasploit framework 3.4.1-linux-i386
##################################

# install
if [ -z "$(ls /usr/share/infond/bin | grep framework-3.4.1)"  ];then
  wget http://www.metasploit.com/releases/framework-3.4.1-linux-i686.run -nc -P /usr/share/infond/bin/
  log "+" "metasploit framework 3.4.1 downloaded"
  bash /usr/share/infond/bin/framework-3.4.1-linux-i686.run 
  log "+" "metasploit framework 3.4.1 installed"
else
  log "I" "metasploit framework 3.4.1 already downloaded. Not updated."
fi

# download icon
downloadicon msfconsole http://www.metasploit.com/images/hax_small.jpg

# add msfconsole entry in Gnome menu
addmenu msfconsole "The Metasploit Framework is both a penetration testing system and a development platform for creating security tools and exploits." "bash -c 'echo msfconsole;msfconsole -v;msfconsole'" "true" "Pentest" 

###########################
# wipe
###########################

# apt install
aptinstall wipe

# download icon
downloadicon wipe http://i26.tinypic.com/141o2nt.jpg

# add entry in Gnome menu
addmenu wipe "securely erase files from magnetic media." "bash -c 'cd /tmp;wipe -h;bash'" "true" "Accessories"

###########################
# socat
###########################

# apt install
aptinstall socat

# download icon
downloadicon socat http://2.bp.blogspot.com/_Jna6k5HsSu4/TFaaYRZYx1I/AAAAAAAAAH0/mwnHBGIMP0U/s1600/socat.png

# add entry in Gnome menu
addmenu socat "Multipurpose relay (SOcket CAT)." "bash -c 'cd /tmp;socat -h;echo ex: socat tcp4-listen:2121,reuseaddr,fork tcp-connect:www.google.com:80;bash'" "true" "Accessories"

###########################
# ascii
###########################

# apt install
aptinstall ascii

# download icon
downloadicon ascii http://ascii-table.com/img/table.gif

# add entry in Gnome menu
addmenu ascii "table ascii." "bash -c 'ascii -h;bash'" "true" "Accessories"


###########################
# aircrack-ng
###########################

# apt install
aptinstall aircrack-ng

# download icon
downloadicon aircrack http://www.hebertphp.net/wordpress/wp-content/uploads/2009/07/wifi.jpg 

# add entry in Gnome menu
addmenu aircrack "Aircrack-ng is an 802.11 WEP and WPA-PSK keys cracking program that can recover keys once enough data packets have been captured. It implements the standard FMS attack along with some optimizations like KoreK attacks, as well as the all-new PTW attack, thus making the attack much faster compared to other WEP cracking tools. In fact, Aircrack-ng is a set of tools for auditing wireless networks." "bash -c 'cd /tmp;aircrack-ng --help;bash'" "true" "Pentest"

###########################
# httrack
###########################

# apt install
aptinstall httrack

# download icon
downloadicon httrack http://thumbs1-fr.logicielsfr.com/199-httrack/box/box.jpg

# add entry in Gnome menu
addmenu httrack "httrack - offline browser : copy websites to a local directory." "bash -c 'cd /tmp;httrack -h;bash'" "true" "Accessories"


###########################
# firefox extensions
###########################

# close firefox
[ ! -z $(pidof firefox-bin) ] && kill -9 $(pidof firefox-bin)

# download and install firefox extensions
firefoxadd firebug 1843
firefoxadd livehttpheaders 3829
firefoxadd noscript 722
firefoxadd flashblock 433
firefoxadd flashgot 220
firefoxadd foxyproxy 2464
firefoxadd useragentswitcher 59

# tamper_data-11.0.1-fx
# does not use "latest" address. Must download specific version.
if [ -z "$(ls -R /usr/lib/firefox-addons/extensions | grep tamperdata)" ]; then 
  wget https://addons.mozilla.org/fr/firefox/downloads/file/79565/tamper_data-11.0.1-fx.xpi -nc -P /usr/lib/firefox-addons/extensions
  log "+" "tamper_data ready to install."
else
 log "I" "tamper_data already installed. .xpi not downloaded."
fi

# install firefox addons
firefox -silent -offline

###########################
# conclusion
###########################

# chmod other every files in infond
chown root:root /usr/share/infond -R
chmod -R 775 /usr/share/infond

# EOF
