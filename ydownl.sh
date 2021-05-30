#!/bin/bash
#
# ydownl - a simple youtube-dl download script
# 	https://github.com/yafp/ydownl.sh
#
# Youtube-dl parameters:
# 	https://github.com/ytdl-org/youtube-dl/blob/master/README.md
#
# USAGE:
# 	./ydownl.sh URL
#

# ------------------------------------------------------------------------------
# IDEAS
# ------------------------------------------------------------------------------
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
SCRIPT_VERSION="1.4.1"
SCRIPT_NAME_VERSION="$SCRIPT_NAME""-v""$SCRIPT_VERSION"
SCRIPT_LATEST="https://github.com/yafp/ydownl.sh/releases/latest"
SCRIPT_DEMO_URL="https://www.youtube.com/watch?v=Y52M28WQu2s"
SCRIPT_USERAGENT="ydownl.sh"

# ------------------------------------------------------------------------------
# USER CONFIG
# ------------------------------------------------------------------------------
# CONFIG_DOWNLOAD_FOLDER: Defines the output folder
CONFIG_DOWNLOAD_FOLDER="$HOME/Downloads"

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
	##blink=$(tput blink)
	##reverse=$(tput smso)
	##underline=$(tput smul)

	# colors
	##black=$(tput setaf 0)
	red=$(tput setaf 1)
	green=$(tput setaf 2)
	yellow=$(tput setaf 3)
	lime_yellow=$(tput setaf 190)
	powder_blue=$(tput setaf 153)
	##blue=$(tput setaf 4)
	##magenta=$(tput setaf 5)
	##cyan=$(tput setaf 6)
	##white=$(tput setaf 7)
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
# Checks if a file/executable exists.
# Arguments:
#   Name of executable
# Outputs:
#	OK if it exists
#	Error if it doesnt exists
#######################################
function checkIfExecutableExists() {
	if ! hash "$1" 2>/dev/null
	then
		printf "${red}[ FAIL ]${normal} $1 not found on this system. Please install this dependency.\n" # does not exist
		exit 1
	fi
}

#######################################
# Executes the initial checks for dependencies
# Arguments:
#   none
# Outputs:
#	none
#######################################
function checkDependencies () {
	checkIfExecutableExists "dialog" # for dialogs
	checkIfExecutableExists "zenity" # for dialogs
	checkIfExecutableExists "curl" # for update-check
	checkIfExecutableExists "sed" # for update-check
	checkIfExecutableExists "youtube-dl" # main-component
}

#######################################
# Checks if a newer version of the script is available
# Arguments:
#   none
# Outputs:
#	OK if no update available
#	INFO if update is available
#######################################
function checkScriptVersion() {
	reset
    SCRIPT_LATEST_VERSION=$(curl --silent "https://api.github.com/repos/yafp/ydownl.sh/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/' )                                  # Pluck JSON value

	if [ "$SCRIPT_LATEST_VERSION" != "$SCRIPT_VERSION" ]
	then
    	dialog \
    		--backtitle "ydownl.sh" \
    		--msgbox "Your version of $SCRIPT_NAME is outdated.\n\nLatest official version is available under:\n$SCRIPT_LATEST" 10 80
	else
		dialog \
    		--backtitle "ydownl.sh" \
    		--msgbox "Your version of $SCRIPT_NAME is up to date" 10 80
	fi

	showMainMenu
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
# Triggers the download using youtube-dl
# Arguments:
#   URL
# Outputs:
#	none
#######################################
function startDownload () {
	# start the main task
	youtube-dl \
		--format bestaudio \
		--extract-audio \
		--restrict-filenames \
		--write-description \
		--console-title \
		--audio-format "$CONFIG_YTDL_AUDIOFORMAT" \
		--audio-quality $CONFIG_YTDL_AUDIOQUALITY \
		--output "$CONFIG_DOWNLOAD_FOLDER/%(playlist_index)s%(playlist)s%(title)s.%(ext)s" \
		--output-na-placeholder "" \
		--write-info-json \
		--write-annotations \
		--write-thumbnail \
		--embed-thumbnail \
		--add-metadata \
		--no-mtime \
		--user-agent "$SCRIPT_USERAGENT" \
		"$1"

	showGuiNotification "Finished downloading\n\t<a href='$1'>$1</a>"
	showMainMenu
}

#######################################
# Shows the dialog-based main menu
# Arguments:
#   none
# Outputs:
#	none
#######################################
function showMainMenu () {
	USERSELECTION=$(dialog \
		--backtitle "ydownl.sh" \
		--title "Main menu" \
		--ok-label "Choose" \
		--no-cancel \
		--menu "Please choose:" 15 55 5 \
			1 "New download" \
			2 "Check for youtube-dl updates" \
			3 "Check for ydownl.sh updates" \
			9 "Exit" \
		--output-fd 1)

	case $USERSELECTION in
		1)
    		showUrlInputDialog
    		;;

  		2)
    		youtubeDLUpdate
    		;;

    	3)
    		checkScriptVersion
    		;;

  		9)
    		reset
    		exit 0
    		;;

  		*)
    		reset
    		#showErrorDialog "Unexpected error"
    		;;
	esac
}

#######################################
# Shows the dialog-based url input dialog
# Arguments:
#   none
# Outputs:
#	none
#######################################
function showUrlInputDialog () {
	USERURL=$(dialog \
		--title "New Download" \
		--backtitle $SCRIPT_NAME_VERSION \
		--ok-label "OK" \
		--cancel-label "Exit" \
		--no-cancel \
		--inputbox "Please paste the URL here" 10 90 \
		--output-fd 1)

	checkUserInput $USERURL
}

#######################################
# Checks if the user input is a reachable url or not
# Arguments:
#   $1 = user input
# Outputs:
#	none
#######################################
function checkUserInput () {
	if [[ $1 ]]; then
		reset

		# check if the url is valid
		if curl --output /dev/null --silent --head --fail "$1"; then
			startDownload $1
		else
			showErrorDialog "This is not a valid and/or reachable url"
			showMainMenu
		fi
	else
		#showErrorDialog "Aborting..." # input was zero
		showMainMenu
	fi
}

#######################################
# Shows the dialog-based error dialog
# Arguments:
#   $1 = error message
# Outputs:
#	none
#######################################
function showErrorDialog () {
	dialog \
		--backtitle "ydownl.sh" \
		--msgbox "$1" 10 90
}

#######################################
# Call youtube-dl and tell it to run self update
# Arguments:
#   none
# Outputs:
#	none
#######################################
function youtubeDLUpdate() {
	reset
	youtube-dl --update
	printf "\n"
	read -p "Press enter to continue"
	showMainMenu
}

# ------------------------------------------------------------------------------
# SCRIPT
# ------------------------------------------------------------------------------
initColors
checkDependencies
showUrlInputDialog
