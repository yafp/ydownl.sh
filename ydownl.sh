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
SCRIPT_VERSION="1.5.0"
SCRIPT_NAME_VERSION="$SCRIPT_NAME""-v""$SCRIPT_VERSION"
SCRIPT_GITHUB_URL="https://github.com/yafp/ydownl.sh"
SCRIPT_LATEST="https://github.com/yafp/ydownl.sh/releases/latest"
SCRIPT_USERAGENT="ydownl.sh"
#
#SCRIPT_DEMO_URL="https://www.youtube.com/watch?v=Y52M28WQu2s"

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

CONFIG_INFODIALOG_TIMEOUT=5

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
	#bold=$(tput bold)
	normal=$(tput sgr0)
	##blink=$(tput blink)
	##reverse=$(tput smso)
	##underline=$(tput smul)

	# colors
	##black=$(tput setaf 0)
	red=$(tput setaf 1)
	#green=$(tput setaf 2)
	#yellow=$(tput setaf 3)
	#lime_yellow=$(tput setaf 190)
	#powder_blue=$(tput setaf 153)
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
	checkIfExecutableExists "dialog" # for terminal UI & dialogs
	checkIfExecutableExists "curl" # for update-check
	checkIfExecutableExists "sed" # for update-check
	checkIfExecutableExists "youtube-dl" # main-component
}


#######################################
# Compares 2 strings - usrf gpt update check
# Arguments:
#   none
# Outputs:
#	none
#######################################
function version { 
	echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; 
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


    # local version == latest public release
    if [ $(version $SCRIPT_LATEST_VERSION) -eq $(version "$SCRIPT_VERSION") ]; then
    	if [ -z "$1" ]; then # output only in default mode - if $1 is not set
	    	dialog \
				--hline "$SCRIPT_GITHUB_URL" \
				--title "Update check: Up-to-date" \
	    		--backtitle "ydownl.sh" \
	    		--msgbox "You are running the latest version of $SCRIPT_NAME (as in: $SCRIPT_LATEST_VERSION)" 10 80
	    fi
	fi

	# local version < latest public release -> inform about update
    if [ $(version $SCRIPT_LATEST_VERSION) -gt $(version "$SCRIPT_VERSION") ]; then
    	dialog \
    		--hline "$SCRIPT_GITHUB_URL" \
    		--title "Update check: Outdated" \
    		--backtitle "ydownl.sh" \
    		--msgbox "You are running the outdated version $SCRIPT_VERSION of $SCRIPT_NAME.\n\nLatest official version is $SCRIPT_LATEST_VERSION and is available under:\n$SCRIPT_LATEST" 10 80
	fi

	# local version > latest public release
    if [ $(version $SCRIPT_LATEST_VERSION) -lt $(version "$SCRIPT_VERSION") ]; then
    	if [ -z "$1" ]; then # output only in default mode - if $1 is not set
    		showInfoDialog "Seems like you are running a development version"
    	fi
	fi

	showMainMenu
}

#######################################
# Triggers the download using youtube-dl
# Arguments:
#   URL
# Outputs:
#	none
#######################################
function startDownload () {

	printAsciiArt

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

	showInfoDialog "Finished downloading $1"
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
		--hline "$SCRIPT_GITHUB_URL" \
		--backtitle "ydownl.sh" \
		--title "Main menu" \
		--ok-label "Choose" \
		--no-cancel \
		--menu "Please choose:" 12 80 5 \
			1 "New Audio Download" \
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
		--hline "$SCRIPT_GITHUB_URL" \
		--title "New Audio Download" \
		--backtitle $SCRIPT_NAME_VERSION \
		--ok-label "Start" \
		--cancel-label "Exit" \
		--no-cancel \
		--inputbox "Please paste the URL here" 10 80 \
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

		# Check if input looks like a link
		regex='(https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
		if [[ $1 =~ $regex ]]
		then 
    		#printf "Link valid"
    		# check if it is reachable
			if curl --output /dev/null --silent --head --fail "$1"; then
				startDownload $1
			else
				showErrorDialog "The link $1 is not reachable"
				showMainMenu
			fi

		else
    		#printf "Link not valid"
    		showErrorDialog "'$1' is not a valid link"
			showMainMenu
		fi
	else
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
		--hline "$SCRIPT_GITHUB_URL" \
		--title "Error" \
		--backtitle "ydownl.sh" \
		--msgbox "$1" 10 80
}

#######################################
# Shows the dialog-based info dialog
# Arguments:
#   $1 = info message
# Outputs:
#	none
#######################################
function showInfoDialog () {
	dialog \
		--hline "$SCRIPT_GITHUB_URL" \
		--title "Info" \
		--backtitle "ydownl.sh" \
		--timeout "$CONFIG_INFODIALOG_TIMEOUT" \
		--msgbox "$1" 10 80
}


#######################################
# Call youtube-dl and tell it to run self update
# Arguments:
#   none
# Outputs:
#	none
#######################################
function youtubeDLUpdate() {
	#reset
	printAsciiArt
	youtube-dl --update
	printf "\n"
	read -p "Press enter to continue"
	showMainMenu
}


function printAsciiArt() {
	reset
	printf '           _                     _       _     \n'
	printf '          | |                   | |     | |    \n'
	printf ' _   _  __| | _____      ___ __ | |  ___| |__  \n'
	printf '| | | |/ _` |/ _ \ \ /\ / / \ _ | | / __|  _ \ \n'
	printf '| |_| | (_| | (_) \ V  V /| | | | |_\__ \ | | |\n'
	printf ' \__, |\__,_|\___/ \_/\_/ |_| |_|_(_)___/_| |_|\n'
	printf '  __/ |                                        \n'
	printf '  |___/\n\n' 	
}


# ------------------------------------------------------------------------------
# SCRIPT
# ------------------------------------------------------------------------------
initColors
checkDependencies
checkScriptVersion "silent"
showUrlInputDialog
