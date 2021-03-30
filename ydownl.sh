#!/bin/bash
#
# ydownl - a simple youtube-dl download script
#
# USAGE:
# 	./ydownl.sh URL
#

# ------------------------------------------------------------------------------
# DEBUG
# ------------------------------------------------------------------------------
# Debugging: This will report the usage of uninitialized variables
#set -u


# ------------------------------------------------------------------------------
# DEFINE CONSTANTS - DON'T TOUCH
# ------------------------------------------------------------------------------
SCRIPT_NAME="ydownl.sh"
SCRIPT_VERSION="1.2.0"
SCRIPT_LATEST="https://github.com/yafp/ydownl.sh/releases/latest"
SCRIPT_DEMO_URL="https://www.youtube.com/watch?v=Y52M28WQu2s"



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
CONFIG_ZENITY_TIMEOUT=15 # default 15

# CONFIG_ZENITY_DIALOG_WIDTH: define dialog width
CONFIG_ZENITY_WIDTH=500 # default 500

# CONFIG_ZENITY_DIALOG_HEIGHT: define dialog height
CONFIG_ZENITY_HEIGHT=150 # default 150


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
	printf " ${bold}${lime_yellow}%s${normal} - ${bold}%s ${normal}\n" "$SCRIPT_NAME" "$SCRIPT_VERSION"
	printf " ${bold}----------------------------------------------------------${normal}\n"
}

function showNotification() {
	if ! hash notify-send 2>/dev/null
	then
		printf "Notifications using notify-send is not supported - skipping ...\n"
	else
		#notify-send -u low -t 0 "$SCRIPT_NAME" "$1"
		zenity --info --text="$1" --title="$SCRIPT_NAME" --width="$CONFIG_ZENITY_WIDTH" --height="$CONFIG_ZENITY_HEIGHT" --timeout="$CONFIG_ZENITY_TIMEOUT"
	fi
}

function checkIfExists() {
	if ! hash "$1" 2>/dev/null
	then
		# does not exist
		printf "${red}[ FAIL ]${normal} $1 not found\n"
		exit 1
	else
		# exists
		printf "${green}[  OK  ]${normal} $1 detected\n"
	fi
}

function checkVersion() {
  SCRIPT_LATEST_VERSION=`curl --silent "https://api.github.com/repos/yafp/ydownl.sh/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/' `                                  # Pluck JSON value


  #printf "Your version: $SCRIPT_VERSION\n"
  #printf "Latest version: $SCRIPT_LATEST_VERSION\n"


	if [ "$SCRIPT_LATEST_VERSION" == "$SCRIPT_VERSION" ]
	then
        printf "${green}[  OK  ]${normal} Your current version $SCRIPT_VERSION is up-to-date\n"
    else
    	printf "${powder_blue}[ INFO ]${normal} Your version is outdated. $SCRIPT_LATEST_VERSION is available under: $SCRIPT_LATEST\n"
	fi
}


# ------------------------------------------------------------------------------
# SCRIPT
# ------------------------------------------------------------------------------
reset # clear the screen
initColors # initialize the color and font formating variables
showHeader # show the script header
checkIfExists "youtube-dl"
checkIfExists "ffmpeg"
checkIfExists "zenity"
checkIfExists "curl"
checkIfExists "sed"
checkVersion

# Check if a parameter was supplied - if not stop execution
if [ -z "$1" ]
then
	printf "${yellow}[ WARN ]${normal} no URL detected. Starting input dialog\n"

	# start input dialog to handle the missing url
	URL=$(zenity --entry --width="$CONFIG_ZENITY_WIDTH" --height="$CONFIG_ZENITY_HEIGHT" --title="$SCRIPT_NAME" --text="Please insert an URL:")
	if [ -z "$URL" ]
	then
    	printf "${red}[ FAIL ]${normal} no URL provided. Usage: ./%s %s\n\n" "$SCRIPT_NAME" "$SCRIPT_DEMO_URL"
    	exit 1
	fi
else
	printf "${green}[  OK  ]${normal} URL detected\n"
	URL=$1 # save url in variable
fi

# check if the url is valid
if curl --output /dev/null --silent --head --fail "$URL"; then
	printf "${green}[  OK  ]${normal} URL is valid\n"
	printf "\nStart processing the following url:\n\t${bold}%s${normal}\n\n" "$URL"

	# start downloading (alt: youtube-dlc)
	youtube-dl -f bestaudio --extract-audio --restrict-filenames --write-description --newline --console-title --audio-format "$CONFIG_YTDL_AUDIOFORMAT" --audio-quality $CONFIG_YTDL_AUDIOQUALITY -o "%(playlist_index)s-%(playlist)s---%(title)s.%(ext)s" $URL
	printf "\n${green}[  OK  ]${normal} Finished processing the URL: $URL\n\n"
	showNotification "Finished downloading\n\t<a href='$URL'>$URL</a>"
else
	printf "${red}[ FAIL ]${normal} URL is not reachable. Aborting..\n\n"
  	exit 1
fi
