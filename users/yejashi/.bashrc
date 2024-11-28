### EXPORT ###
export EDITOR='vim'
export VISUAL='vim'
export HISTCONTROL=ignoreboth:erasedups
#export PAGER='most'

#Ibus settings if you need them
#type ibus-setup in terminal to change settings and start the daemon
#delete the hashtags of the next lines and restart
#export GTK_IM_MODULE=ibus
#export XMODIFIERS=@im=dbus
#export QT_IM_MODULE=ibus

PS1='[\u@\h \W]\$ '

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [ -d "$HOME/.bin" ]; then
	PATH="$HOME/.bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
	PATH="$HOME/.local/bin:$PATH"
fi

#ignore upper and lowercase when TAB completion
bind "set completion-ignore-case on"

### ALIASES ###

#list
alias ls='ls --color=auto'
alias la='ls -a'
alias ll='ls -alFh'
alias l='ls'
alias l.="ls -A | egrep '^\.'"
alias listdir="ls -d */ > list"

## Colorize the grep command output for ease of use (good for log files)##
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'


alias v="nvim"
alias r="ranger"
alias enable-boost='sudo bash -c "echo 1 > /sys/devices/system/cpu/cpufreq/boost"'
alias disable-boost='sudo bash -c "echo 0 > /sys/devices/system/cpu/cpufreq/boost"'
alias perfmode='sudo cpupower frequency-set --governor performance'
alias consmode='sudo cpupower frequency-set --governor conservative'
alias set-governor='sudo cpupower frequency-set --governor '
alias boost='cat /sys/devices/system/cpu/cpufreq/boost'
alias governor='cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'
alias bashrc='nvim ~/.bashrc'
alias tellico-mnt='sshfs tellico:/home/bbogale ~/mount_point'
alias tellico-unmount='fusermount -uz ~/mount_point'

tellico-code() {
	sshfs tellico:/home/bbogale/"$1" ~/mount_point && code ~/mount_point && exit
}

get-uni() {
	echo -ne "\u"$1 | xclip -selection clipboard
}

vfzf() {
    vim $(fzf)
}

set -o vi
bind -m vi-command 'Control-l: clear-screen'
bind -m vi-insert 'Control-l: clear-screen'

# source ~/home_env/bin/activate  # commented out by conda initialize
#eval "$(starship init bash)"
if [[ "$TERM" == "xterm-kitty" ]]; then
	eval "$(starship init bash)"
fi
