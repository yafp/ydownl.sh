#!/bin/bash
#
# ydownl - a simple youtube-dl download script
#
# USAGE:
# 	./ydownl.sh URL
#
# REFERENCE
# 	youtube-dl -f bestaudio --extract-audio --audio-format mp3 --audio-quality 0 -o "%(playlist_index)s %(playlist)s - %(title)s.%(ext)s" https://www.youtube.com/watch?v=Y52M28WQu2s
#
# HISTORY:
# 	20210322 - Version 1.0.0	Initial
#								core implementation
# 								including support for notification (zenity)
#								basic support for user configs

# ------------------------------------------------------------------------------
# TODO:
# ------------------------------------------------------------------------------
# * if no url provided - use notification/dialog to ask for url

# ------------------------------------------------------------------------------
# DEBUG
# ------------------------------------------------------------------------------
# Debugging: This will report the usage of uninitialized variables
#set -u

# ------------------------------------------------------------------------------
# DEFINE CONSTANTS - DON'T TOUCH
# ------------------------------------------------------------------------------
SCRIPTNAME="ydownl.sh"
SCRIPTVERSION="1.0.0"
SCRIPTDEMOURL="https://www.youtube.com/watch?v=Y52M28WQu2s"

# ------------------------------------------------------------------------------
# USER CONFIG
# ------------------------------------------------------------------------------
#
# CONFIG_YTDL_AUDIOFORMAT: Specify audio format: 
# "best", 
# "aac",
# "flac", 
# "mp3", 
# "m4a", 
# "opus", 
# "vorbis", or
# "wav"; 
# "best" by default; No effect
CONFIG_YTDL_AUDIOFORMAT="mp3" # default: "mp3"

# CONFIG_YTDL_AUDIOQUALITY: Specify ffmpeg/avconv audio quality,insert a value between 0 (better) and 9
# (worse) for VBR or a specific bitrate like 128K (default 5)
CONFIG_YTDL_AUDIOQUALITY=0

# CONFIG_ZENITY_TIMEOUT: Defines the timeout for the zenity notification dialog after download finished
CONFIG_ZENITY_TIMEOUT=15 # default 5

# ------------------------------------------------------------------------------
# FUNCTIONS
# ------------------------------------------------------------------------------
function initColors() {
	# format
	bold=$(tput bold)
	normal=$(tput sgr0)
	blink=$(tput blink)
	reverse=$(tput smso)
	underline=$(tput smul)

	# colors
	black=$(tput setaf 0)
	red=$(tput setaf 1)
	green=$(tput setaf 2)
	yellow=$(tput setaf 3)
	lime_yellow=$(tput setaf 190)
	powder_blue=$(tput setaf 153)
	blue=$(tput setaf 4)
	magenta=$(tput setaf 5)
	cyan=$(tput setaf 6)
	white=$(tput setaf 7)
}

function reset() {
	tput reset
}

function showHeader() {
	printf " ${bold}${lime_yellow}%s${normal} - ${bold}%s ${normal}\n" "$SCRIPTNAME" "$SCRIPTVERSION"
	printf " ${bold}----------------------------------------------------------${normal}\n"
}

function showNotification() {
	if ! hash notify-send 2>/dev/null
	then
		printf "Notifications using notify-send is not supported - skipping ...\n"
	else
		#notify-send -u low -t 0 "$SCRIPTNAME" "$1"
		zenity --info --text="$1" --title="$SCRIPTNAME" --width="500" --height="150" --timeout="$CONFIG_ZENITY_TIMEOUT"
	fi
}

function checkIfExists() {
	if ! hash "$1" 2>/dev/null
	then
		# does not exist
		printf "${red}[ Error ]${normal} $1 not found\n"
		exit 1
	else
		# exists
		printf "${green}[  OK   ]${normal} $1 detected\n"
	fi
}

# ------------------------------------------------------------------------------
# SCRIPT
# ------------------------------------------------------------------------------
reset # clear the screen
initColors # initialize the color and font formating variables
showHeader # show the script header
checkIfExists "youtube-dl"
checkIfExists "zenity"

# Check if a parameter was supplied - if not stop execution
if [ -z "$1" ]
then
	printf "${red}[ Error ]${normal} no URL detected. Usage: ./%s %s\n\n" "$SCRIPTNAME" "$SCRIPTDEMOURL"
	exit 1
else
	printf "${green}[  OK   ]${normal} URL detected\n"
	URL=$1 # save url in variable
fi

# check if the url is valid
if curl --output /dev/null --silent --head --fail "$URL"; then
	printf "${green}[  OK   ]${normal} URL is valid\n"
	printf "\nStart processing the following url:\n\t${bold}%s${normal}\n\n" "$URL"

	# start downloading (alt: youtube-dlc)
	youtube-dl -f bestaudio --extract-audio --audio-format "$CONFIG_YTDL_AUDIOFORMAT" --audio-quality $CONFIG_YTDL_AUDIOQUALITY -o "%(playlist_index)s %(playlist)s - %(title)s.%(ext)s" $URL
	showNotification "Finished downloading\n\t<a href='$URL'>$URL</a>"
else
	printf "${red}[ Error ]${normal} URL is not reachable. Aborting..\n\n"
  	exit 1
fi
