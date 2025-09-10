#
# ~/.bashrc
#

#
#
# Esse arquivo pode ser substituido em um Update,
# configurações pessoais devem ser inseridas em:
# $HOME/Documentos/.mybashrc
#
#

PS1='[\u@\h \W]\$ '

# Avoid duplicate commands in history
export HISTCONTROL=ignoredups:erasedups

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# PATH
[ -d "$HOME/.bin" ] && export PATH="$HOME/.bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

#ignore upper and lowercase when TAB completion
bind "set completion-ignore-case on"

### FUNCTIONS ###

# Automatically list directory contents when changing directories
# cd() {
#     builtin cd "$@" && ls
# }

### ALIASES ###
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

alias df='df -h'
alias free="free -mt"

alias wget="wget -c"

alias ls='ls --color=auto'
alias la='ls -a'
alias ll='ls -alFh'
alias l='ls'
alias l.="ls -A | egrep '^\.'"
alias ldir="ls -d */ > list"

alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"

#check vulnerabilities microcode
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'
#get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"
#systeminfo
alias sysfailed="systemctl list-units --failed"

### EXTRACTOR ###
# # usage: ex <file>
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *.deb)       ar x $1      ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   tar xf $1    ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# gapp-cli
[[ -f ${HOME}/.clirc ]] && . ${HOME}/.clirc

# Import user bashrc
[[ -f ${HOME}/Documentos/.mybashrc ]] && . ${HOME}/Documentos/.mybashrc