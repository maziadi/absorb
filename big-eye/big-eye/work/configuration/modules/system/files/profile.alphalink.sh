# /etc/bashrc

case "$TERM" in
        xterm-color)
    		shopt -s checkwinsize
        	PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}"; echo -ne "\007"'
        	if [ 0 -eq `id -u` ];
        	then
          		PS1='\[\e[0;31m\]\u@\h\[\e[m\] \[\e[1;34m\]\w\[\e[m\] # \[\e[m\]'
        	else
          		PS1='\[\e[0;32m\]\u@\h\[\e[m\] \[\e[1;34m\]\w\[\e[m\] $ \[\e[m\]'
        	fi
        ;;
	xterm)
    		shopt -s checkwinsize
        	PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}"; echo -ne "\007"'
	;;
    *)
        PS1="\u@\h - \w # "
    ;;
esac
unset dernier_car

PATH="/opt/local/bin:/opt/local/sbin:$PATH:/var/lib/gems/1.8/bin"
alias ll='ls -l'

# vim:ts=4:sw=4
if [ $- != ${-/i/} ]
then
  echo "----------"
  [ -e /etc/issue ] && cat /etc/issue
  echo -e "----------\nEth status: $(/opt/local/bin/check-eth-status)"
fi

