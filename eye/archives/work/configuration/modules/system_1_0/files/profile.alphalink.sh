case "$TERM" in
        xterm-color)
        	PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}"; echo -ne "\007"'
        	if [ 0 -eq `id -u` ];
        	then
          		PS1='\[\e[0;31m\]\u@\h\[\e[m\] \[\e[1;34m\]\w\[\e[m\] # \[\e[m\]'
        	else
          		PS1='\[\e[0;32m\]\u@\h\[\e[m\] \[\e[1;34m\]\w\[\e[m\] $ \[\e[m\]'
        	fi
        ;;
	xterm)
        	PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}"; echo -ne "\007"'
	;;
    *)
        PS1="\u@\h - \w # "
    ;;
esac

export PATH="/opt/local/bin:/opt/local/sbin:$PATH:/var/lib/gems/1.8/bin"
alias ll='ls -l'

if [ "$-" != "$(echo $- | tr -d i)" ] && [ $(id -u) -eq 0 ]
then
  echo "----------"
  [ -e /etc/issue ] && cat /etc/issue
  /bin/echo -e "----------\nEth status: $(/opt/local/bin/check-eth-status -v)"
fi

export EDITOR="vi"
