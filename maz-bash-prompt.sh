#!/usr/bin/env bash

# Mark A. Ziesemer, 2016-01-01, 2018-05-06

# Inspiration:
# - http://blog.superuser.com/2011/09/21/customizing-your-bash-command-prompt/

set -euo pipefail

if [ ! "$BASH" ]; then
	echo '# This script is only supported on bash.'
	exit 1
fi

PS1=''
includeUptimeStats=auto

while [ "${1:-}" != "" ]; do
	case "$1" in
		'--includeUptimeStats')
			if [ -n "${2:-}" ]; then
				includeUptimeStats="$2"
				shift
			else
				includeUptimeStats=true
			fi
			;;
	esac
	shift
done

if [ "$includeUptimeStats" == "auto" ]; then
	# Cygwin: "uptime" is available in procps-ng, but at least as of 2018-05-06,
	#   is at least 50x slower than in native implementations - so skip for now.
	#   (100 iterations on Cygwin = 23.153s, CentOS 7 VM = 0.333s.)
	case "$OSTYPE" in
		cygwin*)
			;;
		*)
			includeUptimeStats=true
			;;
	esac
fi

# If this is an xterm set the title to user@host:dir
case "$TERM" in
	xterm*|rxvt*)
		PS1+='\[\e]0;\u@\h: \w\a\]'
		;;
	*)
		;;
esac

## Show return code from last command if non-0.
# Own line, black text on yellow background.
PS1+='$(RET=$?; if [ $RET != 0 ] ; then echo -e "\n\[\e[43m\]\[\e[30m\]\$?: ${RET}\[\e[0m\]"; fi)'

## Show Date and Time on own line in blue:
PS1+='\n\[\e[34m\]$(date --rfc-3339=s)'

if [ "$includeUptimeStats" == "true" ]; then
	# ... followed by the uptime and number of users:
	#PS1+='  $(uptime | sed '\''s/^.* \(up \+.\+, \+[0-9]+ users\?\).*$/\1/'\'')'
	PS1+=$'  $(pat=\'^.* (up +.+, +[0-9]+ users?).*$\'; if [[ $(uptime) =~ $pat ]]; then echo "${BASH_REMATCH[1]}"; fi)'
	# ... followed by the load average:
	#PS1+=$'  $(cut -d \' \' -f 1-4 </proc/loadavg)'
	PS1+=$'  $(x=$(</proc/loadavg); echo ${x% *})'
fi

## Start the username/host/path line.
# Start the username coloring:
PS1+='\n\[\e['
if [ "$(id -u)" -eq 0 ]; then
	# root is red:
	PS1+='31m'
else
	# everyone else is green:
	PS1+='32m'
fi
PS1+='\]\u@\h\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]'

## Finally, allow a complete line (starting at column 3) for command entry.
# (Bash will automatically substitute a '#' for the '$' for the root user.)
PS1+='\n\$ '

# https://unix.stackexchange.com/questions/379181/escape-a-variable-for-use-as-content-of-another-script
q_mid=\'\\\'\'
PS1_esc="'${PS1//\'/$q_mid}'"

echo 'if [ "$PS1" ] && [ "$BASH" ]; then'
echo "	PS1=$PS1_esc"
echo 'fi'
echo
echo '# This script is written to be executed as: '
echo "#   . <($0)"
