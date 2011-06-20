### dates

# Ymd only for appending filenames
function Ymd() { date +"%Y%m%d"; }
# long date for log file
function _ldate() { date +"%Y/%M/%d-%H:%M:%S"; }
# long date for prepending filename (Ymd.HMS.filename)
function _fdate() { date +"%Y%m%d.%H%M%S"; }

### echo

# long date, a separator, a message: Y/m/d-H:M:S sep msg
function _echod() { echo "$(_ldate) $1$2" ; }
# display a separator and a message both in stdout and in a log file, with an extra line if $4 non-empty
function _echolog() { _echod "$1" "$2" | tee -a "$3"; if [[ $4 != "" ]]; then echo $4 >> "$3"; fi; }
# for simple message or commands, '~' as separator, no extra line
function echolog() { _echolog "~ " "$1" log ""; }
# for complex command, '~~~' + extra separator, a message (both stdout and log), a log file, an extra line (only in log)
function _echologcmd() { _echolog "~~~ $1" "$2" "logs/$3" "~~~~~~~~~~~~~~~~~~~"; }

### logs

# log in logs, with a 'l' linked to last log in progress
function _log() { f=$2; rm -f logs/l; ln -s $f logs/l; _echologcmd "" "$1" $f ; $( $1 >> logs/$f 2>&1 ) ; }
# regular log
function log() { f=$(_fdate).$2 ; _log "$1" $f ; }
# stdout, log and logs/
function loge() { f=$(_fdate).$2 ; echo "(see logs/$f)" >> log; _log "$1" $f ; _echologcmd "DONE ~~~ " "$1" $f; }

### utils

# most recent filename in a directory
function mrf() { ls -t1 $1 | head -n1 ; }
