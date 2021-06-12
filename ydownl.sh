#!/bin/bash
#
# ydownl - a simple youtube-dl download script
# 	https://github.com/yafp/ydownl.sh
#
# Youtube-dl parameters:
# 	https://github.com/ytdl-org/youtube-dl/blob/master/README.md
#
# USAGE:
# 	./ydownl.sh
#


# ------------------------------------------------------------------------------
# DEBUG
# ------------------------------------------------------------------------------
# Debugging: This will report the usage of uninitialized variables
#set -u


# ------------------------------------------------------------------------------
# USER CONFIG
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# USER CONFIG - GENERAL
# ------------------------------------------------------------------------------

# set path to custom style-definition - sample is part of this project repo
# add # to next line to revert back to default colors of DIALOG
export DIALOGRC=$HOME/Downloads/ydownlrc_style_yebla

# CONFIG_DOWNLOAD_FOLDER: Define the output folder
CONFIG_DOWNLOAD_FOLDER="$HOME/Downloads"

# TIMEOUT VALUE FOR INFO DIALOGS (used as notification at end of download)
CONFIG_INFODIALOG_TIMEOUT=5


# ------------------------------------------------------------------------------
# USER CONFIG - AUDIO
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


# ------------------------------------------------------------------------------
# USER CONFIG - VIDEO
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# CONSTANTS - DON'T TOUCH
# ------------------------------------------------------------------------------
SCRIPT_NAME="ydownl.sh"
SCRIPT_VERSION="1.6.0"
SCRIPT_GITHUB_URL="https://github.com/yafp/ydownl.sh"
SCRIPT_LATEST="https://github.com/yafp/ydownl.sh/releases/latest"
SCRIPT_USERAGENT="ydownl.sh"
#
#DEMO_URL
#  https://www.youtube.com/watch?v=Y52M28WQu2s


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
	normal=$(tput sgr0)
	# colors
	red=$(tput setaf 1)
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
	checkIfExecutableExists "awk" # for comparing version strings
	checkIfExecutableExists "curl" # for update-check
	checkIfExecutableExists "dialog" # for terminal UI & dialogs
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
	    		--backtitle "$SCRIPT_NAME" \
	    		--msgbox "You are running the latest version of $SCRIPT_NAME (as in: $SCRIPT_LATEST_VERSION)" 10 80
	    fi
	fi

	# local version < latest public release -> inform about update
    if [ $(version $SCRIPT_LATEST_VERSION) -gt $(version "$SCRIPT_VERSION") ]; then
    	dialog \
    		--hline "$SCRIPT_GITHUB_URL" \
    		--title "Update check: Outdated" \
    		--backtitle "$SCRIPT_NAME" \
    		--msgbox "You are running the outdated version $SCRIPT_VERSION of $SCRIPT_NAME.\n\nLatest official version is $SCRIPT_LATEST_VERSION and is available under:\n$SCRIPT_LATEST" 10 80
	fi

	# local version > latest public release
    if [ $(version $SCRIPT_LATEST_VERSION) -lt $(version "$SCRIPT_VERSION") ]; then
    	if [ -z "$1" ]; then # output only in default mode - if $1 is not set
    		showInfoDialog "Seems like you are running the development version $SCRIPT_VERSION of $SCRIPT_NAME, while $SCRIPT_LATEST_VERSION is the latest official version."
    	fi
	fi

	# go back to main menu
	showMainMenu
}

#######################################
# Triggers the download using youtube-dl
# Arguments:
#   URL
# Outputs:
#	none
#######################################
function startAudioDownload () {
	printAsciiArt

	# start the youtube-dl download task
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

	showInfoDialog "Finished downloading audio:\n\n$1"
	showMainMenu
}

#######################################
# Triggers the download using youtube-dl
# Arguments:
#   URL
# Outputs:
#	none
#######################################
function startVideoDownload () {
	printAsciiArt

	# start the youtube-dl download task
	youtube-dl \
		--format bestvideo \
		--restrict-filenames \
		--write-description \
		--console-title \
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

	showInfoDialog "Finished downloading video: $1"
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
		--backtitle "$SCRIPT_NAME" \
		--title "Main menu" \
		--ok-label "Choose" \
		--no-cancel \
		--menu "Please choose:" 12 80 5 \
			1 "New Audio Download" \
			2 "New Video Download" \
			3 "Misc" \
			9 "Exit" \
		--output-fd 1)

	case $USERSELECTION in
		1)
    		showAudioUrlInputDialog
    		;;

  		2)
    		showVideoUrlInputDialog
    		;;

    	3)
    		showMiscMenu
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
# Shows the dialog-based misc menu
# Arguments:
#   none
# Outputs:
#	none
#######################################
function showMiscMenu () {
	USERSELECTION=$(dialog \
		--hline "$SCRIPT_GITHUB_URL" \
		--backtitle "$SCRIPT_NAME" \
		--title "Misc menu" \
		--ok-label "Choose" \
		--no-cancel \
		--menu "Please choose:" 12 80 5 \
			1 "About" \
			2 "Software Update (ydownl.sh)" \
			3 "Software Update (Youtube-dl)" \
			9 "Back" \
		--output-fd 1)

	case $USERSELECTION in
		1)
    		showAboutInfo
    		;;

		2)
			checkScriptVersion
    		;;

  		3)
    		checkYoutubeDLVersion
    		;;

  		9)
    		showMainMenu
    		;;

  		*)
    		reset
    		;;
	esac
}


#######################################
# Shows the about dialog
# Arguments:
#   none
# Outputs:
#	none
#######################################
function showAboutInfo () {
	dialog \
		--hline "$SCRIPT_GITHUB_URL" \
		--title "About $SCRIPT_NAME" \
		--backtitle "$SCRIPT_NAME" \
		--msgbox "This is $SCRIPT_NAME \nVersion: $SCRIPT_VERSION\n" 10 80

	# go back to main menu
	showMainMenu
}


#######################################
# Shows the dialog-based url input dialog
# Arguments:
#   none
# Outputs:
#	none
#######################################
function showAudioUrlInputDialog () {
	USERURL=$(dialog \
		--hline "$SCRIPT_GITHUB_URL" \
		--title "New Audio Download" \
		--backtitle $SCRIPT_NAME \
		--ok-label "Start" \
		--cancel-label "Exit" \
		--no-cancel \
		--inputbox "Please paste the URL here" 10 80 \
		--output-fd 1)

	checkUserInput $USERURL
	startAudioDownload $USERURL
}


#######################################
# Shows the dialog-based url input dialog
# Arguments:
#   none
# Outputs:
#	none
#######################################
function showVideoUrlInputDialog () {
	USERURL=$(dialog \
		--hline "$SCRIPT_GITHUB_URL" \
		--title "New Video Download" \
		--backtitle $SCRIPT_NAME \
		--ok-label "Start" \
		--cancel-label "Exit" \
		--no-cancel \
		--inputbox "Please paste the URL here" 10 80 \
		--output-fd 1)

	checkUserInput $USERURL
	startVideoDownload $USERURL
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
    		# check if it is reachable
			if curl --output /dev/null --silent --head --fail "$1"; then
				return
			else
				showErrorDialog "The link $1 is not reachable"
				showMainMenu
			fi

		else
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
		--backtitle "$SCRIPT_NAME" \
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
		--backtitle "$SCRIPT_NAME" \
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
function checkYoutubeDLVersion() {
	printAsciiArt
	youtube-dl --update
	printf "\n"
	read -p "Press enter to continue"
	showMainMenu
}


#######################################
# Show ascii art
# Arguments:
#   none
# Outputs:
#	none
#######################################
function printAsciiArt() {
	reset
	printf '            _                     _       _     \n'
	printf '           | |                   | |     | |    \n'
	printf '  _   _  __| | _____      ___ __ | |  ___| |__  \n'
	printf ' | | | |/ _` |/ _ \ \ /\ / / \ _ | | / __|  _ \ \n'
	printf ' | |_| | (_| | (_) \ V  V /| | | | |_\__ \ | | |\n'
	printf '  \__, |\__,_|\___/ \_/\_/ |_| |_|_(_)___/_| |_|\n'
	printf '   __/ |                                        \n'
	printf '   |___/\n\n' 	
}


# ------------------------------------------------------------------------------
# SCRIPT
# ------------------------------------------------------------------------------
reset
printAsciiArt
initColors
checkDependencies
checkScriptVersion "silent"
