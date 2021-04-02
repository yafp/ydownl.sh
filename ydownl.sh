#!/bin/bash
#
# ydownl - a simple youtube-dl download script
#
# USAGE:
# 	./ydownl.sh URL
#

# ------------------------------------------------------------------------------
# IDEAS
# ------------------------------------------------------------------------------
# - setting for target dir: 
#		example: CONFIG_TARGET_DIR="~/Downloads"
# - youtube-dl parameter:
# - youtube-dl: ffmpeg or avconv?
#		--prefer-avconv (default)
#		--prefer-ffmpeg
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
SCRIPT_VERSION="1.3.0"
SCRIPT_LATEST="https://github.com/yafp/ydownl.sh/releases/latest"
SCRIPT_DEMO_URL="https://www.youtube.com/watch?v=Y52M28WQu2s"
SCRIPT_USERAGENT="ydownl.sh"



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

#######################################
# Defines some text color & formating options
# Arguments:
#   none
# Outputs:
#	none
#######################################
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

#######################################
# Clears the terminal / screen
# Arguments:
#   none
# Outputs:
#	none
#######################################
function reset() {
	tput reset
}

#######################################
# Shows a simple header
# Arguments:
#   none
# Outputs:
#	none
#######################################
function showHeader() {
	printf " ${bold}${lime_yellow}%s${normal} - ${bold}%s ${normal}\n" "$SCRIPT_NAME" "$SCRIPT_VERSION"
	printf " ${bold}----------------------------------------------------------${normal}\n"
}

#######################################
# Displays a text notification using zenity
# Arguments:
#   notification text
# Outputs:
#	none
#######################################
function showGuiNotification() {
	zenity \
		--info \
		--text="$1" \
		--title="$SCRIPT_NAME" \
		--width="$CONFIG_ZENITY_WIDTH" \
		--height="$CONFIG_ZENITY_HEIGHT" \
		--timeout="$CONFIG_ZENITY_TIMEOUT"
}

#######################################
# Checks if a file/executable exists.
# Arguments:
#   Name of executable
# Outputs:
#	OK if it exists
#	Error if it doesnt exists
#######################################
function checkIfExists() {
	if ! hash "$1" 2>/dev/null
	then
		printf "${red}[ FAIL ]${normal} $1 not found on this system. Please install this dependency.\n" # does not exist
		exit 1
	else
		printf "${green}[  OK  ]${normal} $1 detected\n" # exists
	fi
}

#######################################
# Checks if a newer version of the script is available
# Arguments:
#   none
# Outputs:
#	OK if no update available
#	INFO if update is available
#######################################
function checkVersion() {
    SCRIPT_LATEST_VERSION=$(curl --silent "https://api.github.com/repos/yafp/ydownl.sh/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/' )                                  # Pluck JSON value

	if [ "$SCRIPT_LATEST_VERSION" == "$SCRIPT_VERSION" ]
	then
        printf "${green}[  OK  ]${normal} Your current version $SCRIPT_VERSION is up-to-date\n"
    else
    	printf "${powder_blue}[ INFO ]${normal} Your version is outdated. $SCRIPT_LATEST_VERSION is available under: $SCRIPT_LATEST\n"
	fi
}

#######################################
# Triggers the download using youtube-dl
# Arguments:
#   URL
# Outputs:
#	none
#######################################
function startDownload () {
	# start downloading (alt: youtube-dlc)
	youtube-dl \
		--format bestaudio \
		--extract-audio \
		--restrict-filenames \
		--write-description \
		--newline \
		--console-title \
		--audio-format "$CONFIG_YTDL_AUDIOFORMAT" \
		--audio-quality $CONFIG_YTDL_AUDIOQUALITY \
		--output "%(playlist_index)s%(playlist)s%(title)s.%(ext)s" \
		--output-na-placeholder "" \
		--write-info-json \
		--write-annotations \
		--write-thumbnail \
		--embed-thumbnail \
		--add-metadata \
		--user-agent "$SCRIPT_USERAGENT" \
		"$1"
}


# ------------------------------------------------------------------------------
# SCRIPT
# ------------------------------------------------------------------------------
reset # clear the screen
initColors # initialize the color and font formating variables
showHeader # show the script header

# check all dependencies / requirements
checkIfExists "youtube-dl" # main-component
checkIfExists "ffmpeg" # youtube-dl dependency
checkIfExists "zenity" # for dialogs
checkIfExists "curl" # for update-check
checkIfExists "sed" # for update-check

# check for available updates of this script
checkVersion 

# Check if a parameter/url was supplied
if [ -z "$1" ]
then
	printf "${yellow}[ WARN ]${normal} no URL detected. Starting input dialog\n"

	# start zenity input dialog to ask for the missing url
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

	startDownload "$URL"

	printf "\n${green}[  OK  ]${normal} Finished processing the URL: $URL\n\n"
	showGuiNotification "Finished downloading\n\t<a href='$URL'>$URL</a>"
else
	printf "${red}[ FAIL ]${normal} URL is not reachable. Aborting..\n\n"
  	exit 1
fi
