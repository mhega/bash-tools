#!/bin/bash

BACKUPPATH="/home/mhega/bkp.d"


USAGE()
{
  echo
  echo "Manage backup/restore of current directory."
  echo  
  echo "Usage: bkp [-l | -c | -r | -m] [--FORCE] [-R] [-i]"
  echo
  OPTIONS
  echo "Backup Target Directory: "
  echo $BACKUPPATH"$PWD" | sed "s/\(\/\s*\"*\s*\)\./\1/g"
  echo
  exit 0
}
OPTIONS()
{
  echo "Options:"
  echo "l               List all backup files of the current directory including their timestamps and checksums."
  echo "c               Compare contents of select backup with the current directory."
  echo "r               Restore contents of select backup into a subdirectory within the current directory."
  echo "m               Move old backup files (5 day-old or older) to a sub-directory (old_files)."
  echo "--FORCE         Force backing up of the current directory irrespective of the disk usage."
  echo "R               Recursively archive all subdirectories."
  echo "i               Incremental (differential) archive." 
  echo
  echo "                Run bkp command with only one of "-l", "-c", "-r", "-m" options at a time."
  echo "                Running bkp command without any option, or with options "-R" and/or "--FORCE" will take a new backup."
  echo
}
BACKUPOPT=$((2#000))
FORCEOPT=$((2#001))
RECURSIVEOPT=$((2#010))
INCREMENTALOPT=$((2#100))

while [ True ]; do
  if [[ -z "$1" ]]; then
    break
  elif [[ -z "$COMMANDOPT" && "$1" = "-l" ]]; then
        COMMANDOPT="list"
        shift 1
  elif [[ -z "$COMMANDOPT" && "$1" = "-c" ]]; then
        COMMANDOPT="compare"
        shift 1
  elif [[ -z "$COMMANDOPT" && "$1" = "-r" ]]; then
        COMMANDOPT="restore"
        shift 1
  elif [[ -z "$COMMANDOPT" && "$1" = "-m" ]]; then
        COMMANDOPT="move"
        shift 1
  elif [[ ( -z "$COMMANDOPT" || "$COMMANDOPT" = "backup" ) && ( "$1" = "--FORCE" || "$1" = "-R" || "$1" = "-i" ) ]]; then
        COMMANDOPT="backup"
        if [[ $1 = "--FORCE" ]]; then
              if [[ $(($BACKUPOPT & $FORCEOPT)) != 0 ]]; then
                  USAGE
                  exit 1
              fi
              BACKUPOPT=$(($BACKUPOPT | $FORCEOPT))
        fi
        if [[ $1 = "-R" ]]; then
              if [[ $(($BACKUPOPT & $RECURSIVEOPT)) != 0 ]]; then
                   USAGE
                   exit 1
              fi
              BACKUPOPT=$(($BACKUPOPT | $RECURSIVEOPT))
        fi
        if [[ $1 = "-i" ]]; then
              if [[ $(($BACKUPOPT & $INCREMENTALOPT)) != 0 ]]; then
                   USAGE
                   exit 1
              fi
              BACKUPOPT=$(($BACKUPOPT | $INCREMENTALOPT))
        fi
	shift 1
  else
    USAGE
  fi
done


suffix=$(date +"%Y-%m-%d_%H.%M.%S")
BKP_TARGET_PATH=$(echo $BACKUPPATH"${PWD// /_}"/"$(basename ${PWD// /_})"_$suffix | sed "s/\(\/\s*\"*\s*\)\./\1/g")
echo "$BKP_TARGET_PATH" | grep -qE "\s" && echo "Directories Containing Space Characters Are Not Supported.." && exit 1
BKP_DIR_NAME=$(basename ${PWD// /_} | sed "s/^\(\.\)*\(.*\)$/\2/g")

DISPLAY()
{
 echo
 echo "Backup List Display"
 echo "-------------------"
 echo
 metafile=$(dirname "$BKP_TARGET_PATH")/meta.dat
 ls $(dirname $BKP_TARGET_PATH)/*zip 2> /dev/null | tr \\t \\n \
 |  awk -v dirwc="$(basename $BKP_DIR_NAME | awk '{printf $1}' | wc -c | awk '{printf $1}')" \
        -v metafile=$metafile \
        -v q=\' -v qq=\" \
        'BEGIN{ORS=""
              print "$Backup ID$Timestamp$Checksum$Description\n"
              print "$---------$---------$--------$-----------\n"}
         {cmd0="date -d "qq"$(basename '\''"$1"'\'' | sed '\''s/^.\\{"dirwc"\\}_\\(.*\\)\\.zip$/\\1/g;s/_/ /g;s/\\./:/g'\'')"qq" +"qq"%s"qq
         cmd1="ls -l --full-time '\''"$1"'\'' | awk '\'' {print $6"qq" "qq"$7}'\'' | cut -d . -f1";
         cmd2="cksum '\''"$1"'\'' | awk '\''{print $1}'\''"
         cmd3="[ -f "metafile" ] && id=DESCR_$("cmd0") && grep $id "metafile" | sed '\''s/^\\([^:]*\\):\\(.*\\)$/\\2/g'\''" 
         print "$"
         if( (cmd0|getline x) > 0) { print x; close(cmd0) } else exit 1
         print "$"
         if( (cmd1|getline x) > 0) { print x; close(cmd1) } else exit 1
         print "$"
         if( (cmd2|getline x) > 0) { print x; close(cmd2) } else exit 1
         print "$"
         if( (cmd3|getline x) > 0) { print x; close(cmd3) }
         print "\n"}
         END{if (NR==0) {exit 1}}' \
| column -t  -s$'$'
 if [ ${PIPESTATUS[2]} != 0 ] ; then
   exit 1
 fi
}


DISPLAYL()
{
 echo
 echo "Backup List Display"
 echo "-------------------"
 echo

 ls $(dirname $BKP_TARGET_PATH)/*zip 2> /dev/null | tr \\t \\n \
 |  awk -v qq=\"  'BEGIN{ORS=""
              print "$Path$Timestamp$Checksum\n"
              print "$----$---------$--------\n"}
         {cmd1="ls -l --full-time "$1" | awk '\'' {print $6"qq" "qq"$7}'\'' | cut -d . -f1";
         cmd2="cksum "$1" | awk '\''{print $1}'\''"
         print "$"
         print $1
         print "$"
         cmd1|getline x; print x
         print "$"
         cmd2|getline x; print x
         print "\n"}' \
 | column -t -s$'$'
 echo
 exit 0
}

if [ "$COMMANDOPT"  = "compare" ]; then

 DISPLAY

 echo
 while [ True ]; do
   read -p "Type the ID of the desired backup to compare or Q to quit: " id
   re='^[0-9]+$'
   if [ "$id" = 'Q' -o "$id" = 'q' ]; then
     exit 0
   elif ! [[ $id =~ $re ]]; then
     continue
   else
     filename=$(dirname $BKP_TARGET_PATH)/$(basename $BKP_DIR_NAME | awk '{printf $1}')_$(date +'%Y-%m-%d_%H.%M.%S' -d @$id).zip

     if ls $filename > /dev/null 2>&1; then
       echo
       echo "$(basename $filename) will be compared with the current path.."
       echo "Unless Backup is Recursive, Sub-directories may not undergo deep comparison."
       echo



       (unzip -l "$filename" | sed 's/^\(.*\)\/$/\1/g' \
       | sed 1,3d \
       | awk '(NF > 3){$1="";$3=$3"\t";print}' \
       | sed -e 's/^[[:space:]]*//' \
       | sed 's/\(\t\)[ ]*/\1/g' \
       | awk -v q=\' -v qq=\" \
                   'BEGIN{
                    print "$File Name$Timestamp (Current)$Timestamp (Archive)$"
                    print "$---------$-------------------$-------------------$"}
                    {cmd="ls -ld --full-time "qq $3 qq" 2>/dev/null | awk '\''{print $6"qq" "qq"$7}'\'' | cut -d : -f1-2"
                     if ((cmd|getline x) > 0) {print "$"$3"$"x"$"$1" "$2} else {print "$"$3"$ $"$1" "$2}
                    }' | awk -F"$" '{if($3 != $4 && NR > 2){$0=$0"$*"}; print}';
       ls | grep -vxf <(unzip -l "$filename" | sed 1,3d | awk '(NF>3){$1="";$2="";$3="";print $0}' | sed -e 's/^[[:space:]]*//' | sed 's/^\(.*\)\/$/\1/g') \
       | awk -v qq=\" '{cmd1="ls -ld --full-time "qq $0 qq" | awk '\'' {print $6"qq" "qq"$7} '\'' | cut -d : -f1-2"; if((cmd1|getline x) > 0){print "$"$0"$"x"$ $*"}}' \
       ) | column -t -s$'$'



     else
       echo The specified ID does not map to an existing backup file.
       continue
     fi
     break
   fi
 done
 echo
 exit 0

elif [ "$COMMANDOPT" = "list" ]; then

 DISPLAYL

elif [ "$COMMANDOPT" = "restore" ]; then
 
 DISPLAY

 echo
 while [ True ]; do
   read -p "Type the ID of the desired backup to restore or Q to quit: " id
   re='^[0-9]+$'
   if [ "$id" = 'Q' -o "$id" = 'q' ]; then
     exit 0
   elif ! [[ $id =~ $re ]]; then
     continue
   else
     filename=$(dirname $BKP_TARGET_PATH)/$(basename $BKP_DIR_NAME | awk '{printf $1}')_$(date +'%Y-%m-%d_%H.%M.%S' -d @$id).zip

     if ls $filename > /dev/null 2>&1; then
       echo "$(basename $filename) will be decompressed."
       while [ True ]; do
         read -p "Type Y to continue or Q to exit: " conf
         re='^[QqYy]$'
         if [ "$conf" = 'Q' -o "$conf" = 'q' ]; then
           exit 0
         elif ! [[ $conf =~ $re ]]; then
           continue
         elif [ "$conf" = 'Y' -o "$conf" = 'y' ]; then
           targetdirname="$(basename $filename | sed 's/\(.*\)\.zip$/\1/g')"
           mkdir "./$targetdirname" || (echo "Failed to create $targetdirname" && exit 1)
           echo Extracting $(basename "$filename")..
           failures=0
           trap 'failures=$((failures+1))' ERR
           set -x
           unzip "$filename" -d ./"$targetdirname"
           { set +x; } 2>/dev/null
           if [ $failures != 0 ] ; then
             echo "Failed to decompress archive" && exit 1
           fi
           echo "Restore completed."
           exit 0
         else
           echo "Unhandled condition. Exiting!"
           exit 1
         fi
       done
     else
       echo The specified ID does not map to an existing backup file.
       continue
     fi
     break
   fi
 done
 exit 0

elif [ "$COMMANDOPT" = "move" ]; then
daythresh=5
timethresh=$(date --date=$daythresh' days ago' +"%s")
 if [ -d $(dirname "$BKP_TARGET_PATH") ]; then
  oldfilesdir=old_files
  mkdir -p "$(dirname "$BKP_TARGET_PATH")/$oldfilesdir"
  unset $mvscr 
  mvscr=$(ls "$(dirname "$BKP_TARGET_PATH")/"$BKP_DIR_NAME_*zip"" 2>/dev/null \
          | awk -v dirwc="$(basename $BKP_DIR_NAME | awk '{printf $1}' | wc -c | awk '{printf $1}')" \
                -v timethresh=$timethresh \
                -v dirname=$oldfilesdir \
                -v qq=\" \
                'BEGIN{ORS="\\n"}
                 {cmd0="date -d "qq"$(basename '\''"$1"'\'' | sed '\''s/^.\\{"dirwc"\\}_\\(.*\\)\\.zip$/\\1/g;s/_/ /g;s/\\./:/g'\'')"qq" +"qq"%s"qq 
                  cmd1="dirname "$1
                 if ((cmd0|getline x) > 0 && (cmd1|getline y) > 0 && x<timethresh) {print "mv "qq $1 qq" " y"/"dirname"/ && echo Success.."}
                 }' )
  
  if [ $(echo -e $mvscr | sed '/^\s*$/d' | wc -l) -gt 0 ]; then 
   while [ True ]; do
     read -p "$(echo -e $mvscr | sed '/^\s*$/d' | wc -l) file(s) are more than $daythresh day old and will be moved to $oldfilesdir. Type Y to continue or Q to quit:" prompt
     re='^[yYqQ]+$'
     if [ "$prompt" = 'Q' -o "$prompt" = 'q' ]; then
       exit 0
     elif ! [[ $prompt =~ $re ]]; then
       continue
     elif [ "$prompt" = 'Y' -o "$prompt" = 'y' ]; then
       while read l; do
        echo $l
        eval $l
       done < <(echo -e $mvscr)
       exit 0
     fi
   done
  else
   echo "No files to move ($daythresh day old)"
  fi
 fi
 exit
fi

##
## DO NOT EDIT THIS CODE
##
BKP_CURRENT_SIZE="."
BKP_CURRENT_SIZE=$(du -s | awk '{print $1}') || exit 1
re='^[0-9]+$'
if ! [[ $BKP_CURRENT_SIZE =~ $re ]]; then
    echo Something is wrong! Exiting..
    exit 1
fi

echo
echo "** TOTAL SIZE: "$BKP_CURRENT_SIZE" BYTES **"
echo

if [[ $BKP_CURRENT_SIZE -gt 2000 ]]; then
    if [ $(($BACKUPOPT & $FORCEOPT)) = $FORCEOPT ]; then
        echo "** FORCE OPTION IS SPECIFIED TO OVERRIDE SIZE LIMIT RESTRICTION **"
        echo
        while [ True ]; do
            read -p "Type Y to confirm or Q to quit: " cnfm
            if [ "$cnfm" = 'Y' -o "$cnfm" = 'y' ]; then
                break
            elif [ "$cnfm" = 'Q' -o "$cnfm" = 'q' ]; then
                echo
                echo "Exiting .."
                exit 0
            fi
        done
    else
        echo "Too much size to safely backup ( $BKP_CURRENT_SIZE )!"
        echo "Use --FORCE flag at your risk if you wish to override the hard threshold."
        echo
        echo "Exiting .."
        exit 1
    fi
fi


echo "Current Directory: $PWD"
mkdir -p "$BACKUPPATH"
mkdir -p "$(dirname "$BKP_TARGET_PATH")"

read -p "Input a single-line backup description and/or hit NewLine to continue (CTRL-C to abort and exit): " descr
if [ $(($BACKUPOPT & $RECURSIVEOPT)) = $RECURSIVEOPT ]; then
   descr="$descr"'    '[RECURSIVE]
fi
if [ $(($BACKUPOPT & $INCREMENTALOPT)) = $INCREMENTALOPT ]; then
   descr="$descr"'    '[INCREMENTAL]
fi
if [ -n "$descr" ]; then
 dirwc=$(basename $BKP_DIR_NAME | awk '{printf $1}' | wc -c | awk '{printf $1}')
 bkpid=$(date -d "$(basename "$BKP_TARGET_PATH" | sed "s/^.\{$dirwc\}_\(.*\)$/\\1/g;s/_/ /g;s/\./:/g")" +"%s")
 descrvarname=DESCR_$bkpid
 declare $descrvarname="$descr"
 echo $descrvarname:${!descrvarname} | sed 's/^\(\([^:]*\):\(.*\)\)$/\2:\3/g' >> $(dirname "$BKP_TARGET_PATH")/meta.dat
fi

CHECKSUMSTORE()
{
  if [[ $1 = "-p" ]]; then
    archivedfiles=$(unzip -l "$BKP_TARGET_PATH".zip | sed 1,3d | awk '{print $4}' | grep -Ev "^\s*$")
    for lin in $archivedfiles ; do echo "cksum $(cksum $lin)"; done >> "$BKP_TARGET_PATH".log 2>/dev/null
    zip -gj "$BKP_TARGET_PATH".zip "$BKP_TARGET_PATH".log
  elif [[ $1 = "-g" ]]; then
    for lin in "$(dirname $BKP_TARGET_PATH)"/*zip; do unzip -p $lin $(basename $lin | sed 's/zip$/log/g'); done | grep -h cksum | sed 's/cksum //g' | grep -Ev "$\s*^"
  fi
}

zipopt=""
if [ $(($BACKUPOPT & $RECURSIVEOPT)) = $RECURSIVEOPT ]; then
   if [ $(($BACKUPOPT & $INCREMENTALOPT)) = $INCREMENTALOPT ]; then
      files=$(find . -exec cksum {} + 2>/dev/null | sed 's/ [.]\// /g' | grep -vxf <(CHECKSUMSTORE -g) | awk 'ORS=" " {print $3}')
      [[ -n "${files// /}" ]] || { echo "No Files To Archive"; exit 0; }
   else
      files=*
   fi
   zipopt="-r"
else
   if [ $(($BACKUPOPT & $INCREMENTALOPT)) = $INCREMENTALOPT ]; then
      files=$(cksum * 2>/dev/null | grep -vxf <(CHECKSUMSTORE -g) | awk 'ORS=" " {print $3}')
      [[ -n "${files// /}" ]] || { echo "No Files To Archive"; exit 0; }
   else
      files=./*
   fi
fi
set -x
zip $zipopt "$BKP_TARGET_PATH".zip $files  | tee "$BKP_TARGET_PATH".log
{ set +x; } 2>/dev/null;
CHECKSUMSTORE -p
echo "Command output directed to:"
echo "$BKP_TARGET_PATH".log
