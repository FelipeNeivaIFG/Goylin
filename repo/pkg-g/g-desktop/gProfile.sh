#
### Goylin ###
#

# Update $HOME
rsync -rlu /etc/skel/. $HOME

[ -d "${HOME}/Área de trabalho" ] && rm -r "${HOME}/Área de trabalho"
xdg-user-dirs-update

# Fix Config File User Names
lUser="$(whoami)"
uName="${lUser#IFG0+}"

# Ensure .desktop files execution
chmod +x ${HOME}/Desktop/*.desktop
chmod +x ${HOME}/.config/autostart/*.desktop

# Guest umask for public access
[ "$uName" == "guest" ] && umask 000

# Source gProfiles
if [ -d /etc/profile.g/ ]; then
	for p in /etc/profile.g/*; do
		[ -f "$p" ] && [ -r "$p" ] && . "$p"
	done
fi