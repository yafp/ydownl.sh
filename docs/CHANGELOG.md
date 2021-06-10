# changelog

## Version 1.5.0 (20210610)
### Added
* Added silent update check on script start (info onlx if update available)
* Adding ascii-art to 
  * youtube-dl update check
  * download start

### Changes
* Improved version check to handle all 3 cases (up-to-date VS outdated VS dev version)
* Download UI: changed button label
* dialogs all show the project url using the --hline parameter
* dialogs are now using the same width
* Improve url input validation (now checks if it is a link & if so if its reachable)

### Removed
* Removed zenity dependency



## Version 1.4.1 (20210530)
### Changes
* Simplify dialogs 

### Fixes
* Adding back support for zenity notifications
* Fix ydownl.sh update script (if version is up to date)



## Version 1.4.0 (20210527)
* Switched to ncruses like mode based on 'dialog'
* Added variable for download target folder
* Youtube-DL: Removing --newline
* Youtube-DL: Adding update check before execution
* Youtube-DL: Adding --no-mtime



## Version 1.3.0 (20210402)
* Youtube-DL: Adding --add-metadata
* Youtube-DL: Adding --write-info-json
* Youtube-DL: Adding --write-annotations
* Youtube-DL: Adding --write-thumbnail
* Youtube-DL: Adding --embed-thumbnail
* Youtube-DL: Adding --user-agent
* Youtube-DL: Adding --output-na-placeholder
* Improved output by missing dependency


## Version 1.2.0 (20210330)
* Added check for updates - see #1
* Added dependecy check for ffmpeg

## Version 1.1.0 (20210327)
* Added output after processing finished
* Minor changes to status output
* Adding zenity input dialog if started without providing an URL
* Youtube-DL: Adding --restrict-filenames
* Youtube-DL: Adding --write-description
* Youtube-DL: Adding --newline
* Youtube-DL: Adding --console-title

## Version 1.0.0 (20210322)
* Initial version
* core implementation
* including support for notification (zenity)
* basic support for user configs