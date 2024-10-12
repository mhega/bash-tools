#! /bin/bash

BACKUPPATH="/Users/mhega/bkp.d"


USAGE()
{
  echo
  echo "Manage backup/restore of current directory."
  echo  
  echo "Usage: bkp [-l | -c | -v | -r | -m | --FORCE]"
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
  echo "v               Perform Verbose compare of the contents of select backup with the current directory."
  echo "r               Restore contents of select backup into a subdirectory within the current directory."
  echo "m               Move old backup files (5 day-old or older) to a sub-directory (old_files)."
  echo "--FORCE         Force backing up of the current directory irrespective of the disk usage."
  echo
  echo "                Run bkp command with only one option at a time."
  echo "                Running bkp command without any option will take a new backup."
  echo
}

while [ True ]; do
  if [[ -z "$1" ]]; then
    break
  elif [[ -z "$COMMANDOPT" && "$1" = "-l" ]]; then
        COMMANDOPT="list"
        shift 1
  elif [[ -z "$COMMANDOPT" && "$1" = "-c" ]]; then
        COMMANDOPT="compare"
        shift 1
  elif [[ -z "$COMMANDOPT" && "$1" = "-v" ]]; then
        COMMANDOPT="verbose"
        shift 1
  elif [[ -z "$COMMANDOPT" && "$1" = "-r" ]]; then
        COMMANDOPT="restore"
        shift 1
  elif [[ -z "$COMMANDOPT" && "$1" = "-m" ]]; then
        COMMANDOPT="move"
        shift 1
  elif [[ -z "$COMMANDOPT" && "$1" = "--FORCE" ]]; then
        COMMANDOPT="force"
        shift 1
  else
    USAGE
  fi
done


suffix=$(date +"%Y-%m-%d_%H.%M.%S")
BKP_TARGET_PATH=$(echo $BACKUPPATH"$PWD"/"$(basename $PWD)"_$suffix | sed "s/\(\/\s*\"*\s*\)\./\1/g")
echo "$BKP_TARGET_PATH" | grep -qE "\s" && echo "Directories Containing Space Characters Are Not Supported.." && exit 1
BKP_DIR_NAME=$(basename $PWD | sed "s/^\(\.\)*\(.*\)$/\2/g")

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
              print "\tBackup ID\tTimestamp\tChecksum\tDescription\n"
              print "\t---------\t---------\t--------\t-----------\n"}
         {cmd0="date -jf '\''%Y-%m-%d_%H.%M.%S'\'' $(basename '\''"$1"'\'' | sed '\''s/^.\\{"dirwc"\\}_\\(.*\\)\\.zip$/\\1/g'\'') +%s"
         cmd1="stat -l -t '%FT%T' '\''"$1"'\'' | awk '\'' {print $6}'\''";
         cmd2="cksum '\''"$1"'\'' | awk '\''{print $1}'\''"
         cmd3="[ -f "metafile" ] && id=DESCR_$("cmd0") && declare $id="qq"$(grep $id "metafile" | sed '\''s/^\\([^:]*\\):\\(.*\\)$/\\2/g'\'')"qq" && echo ${!id}"
         print "\t"
         if( (cmd0|getline x) > 0) { print x; close(cmd0) } else exit 1
         print "\t"
         if( (cmd1|getline x) > 0) { print x; close(cmd1) } else exit 1
         print "\t"
         if( (cmd2|getline x) > 0) { print x; close(cmd2) } else exit 1
         print "\t"
         if( (cmd3|getline x) > 0) { print x; close(cmd3) }
         print "\n"}
         END{if (NR==0) {exit 1}}' \
| column -t  -s$'\t'
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
 |  awk 'BEGIN{ORS=""
              print "\tPath\tTimestamp\tChecksum\n"
              print "\t----\t---------\t--------\n"}
         {cmd1="stat -l -t '%FT%T' "$1" | awk '\'' {print $6}'\''";
         cmd2="cksum "$1" | awk '\''{print $1}'\''"
         print "\t"
         print $1
         print "\t"
         cmd1|getline x; print x
         print "\t"
         cmd2|getline x; print x
         print "\n"}' \
 | column -t
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
     filename=$(dirname $BKP_TARGET_PATH)/$(basename $BKP_DIR_NAME | awk '{printf $1}')_$(date -jf %s $id +%Y-%m-%d_%H.%M.%S).zip

     if ls $filename > /dev/null 2>&1; then
       echo
       echo "$(basename $filename) will be compared with the current path.."
       echo "Sub-directories will not undergo recursive comparison."
       echo



       (unzip -l "$filename" | sed 's/^\(.*\)\/$/\1/g' \
       | sed 1,3d \
       | awk '(NF > 3){$1="";$3=$3"\t";print}' \
       | sed -e 's/^[[:space:]]*//' \
       | sed 's/\(\t\)[ ]*/\1/g' \
       | awk -F\t -v q=\' -v qq=\" \
                   'BEGIN{
                    print "\tFile Name\tTimestamp (Current)\tTimestamp (Archive)\n"
                    print "\t---------\t-------------------\t-------------------\n"}
                    {cmd="ls -lT -dD "q"%m-%d-%Y %H:%M"q" "qq $2 qq" 2>/dev/null | awk "q"(NF>6){print $6"qq" "qq"$7}"q
                     if ((cmd|getline x) > 0) {print $2"\t"x"\t"$1} else {print $2"\t \t"$1}
                    }' | awk -F\t '{if($2 != $3 && NR > 3){$0=$0"\t*"}; print}';
       ls | grep -vxf <(unzip -l "$filename" | sed 1,3d | awk '(NF>3){$1="";$2="";$3="";print $0}' | sed -e 's/^[[:space:]]*//' | sed 's/^\(.*\)\/$/\1/g') \
       | awk -v qq=\" '{cmd1="ls -lT -dD '\''%m-%d-%Y %H:%M'\'' "qq $0 qq" | awk '\'' {print $6"qq" "qq"$7} '\''"; if((cmd1|getline x) > 0){print $0"\t"x"\t \t*"}}' \
       ) | column -t -s$'\t'



     else
       echo The specified ID does not map to an existing backup file.
       continue
     fi
     break
   fi
 done
 echo
 exit 0


elif [ "$COMMANDOPT"  = "verbose" ]; then

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
     filename=$(dirname $BKP_TARGET_PATH)/$(basename $BKP_DIR_NAME | awk '{printf $1}')_$(date -jf %s $id +%Y-%m-%d_%H.%M.%S).zip

     if ls $filename > /dev/null 2>&1; then
       echo
       echo "$(basename $filename) will be compared with the current path in verbose mode.."
       echo "Sub-directories will not undergo recursive comparison."
       echo


       ( unzip -v "$filename" | sed '1,3d' \
       | sed 's/^\(.*\)\/$/\1/g' \
       | awk '(NF > 7){$1="";$2="";$3="";$4=""; $6=$6"\t";$7=$7"\t"; print}' \
       | awk -F\t -v q=\' -v qq=\" \
                   'BEGIN{
                    print "File Name\tTimestamp (Current)\tCRC32 (Current)\tTimestamp (Archive)\tCRC32 (Archive)\n"
                    print "---------\t-------------------\t---------------\t-------------------\t---------------\n"}
               (NF == 3){cmd="ls -lT -dD "q"%m-%d-%Y %H:%M"q" "qq"$(echo "$3" | xargs)"qq" 2>/dev/null | awk "q"{$1="qq""qq";$2="qq""qq";$3="qq""qq";$4="qq""qq";$5="qq""qq";$6=$6"qq""qq";$7=$7"qq"\\t"qq";print}"q" | awk -F\\t "q"{cmdcrc="qq"crc32 \\"qq"$(echo "qq"$2"qq" | xargs)\\"qq" 2> /dev/null && echo 00000000"qq";if( (cmdcrc|getline x) > 0) { print $2"qq"\\t"qq"$1"qq"\\t"qq"x"qq"\\n"qq"; close(cmdcrc) } }"q
                         $3=$3;if( (cmd|getline y) > 0) {print y"\t"$1"\t"$2; close(cmd) } else print $3"\t.\t.\t"$1"\t"$2 }' | sed -e 's/^[[:space:]]*//' \
       | sed 's/\(\t\)[ ]*/\1/g'  | awk -F\t '{if((($3 != $5)  || ($3 == "00000000" && $2 != $4)) && NR > 4){$0=$0"\t*"}; print}'; \
       ls | grep -vxf <(unzip -l "$filename" | sed 1,3d | awk '(NF>3){$1="";$2="";$3="";print $0}' | sed -e 's/^[[:space:]]*//' | sed 's/^\(.*\)\/$/\1/g') \
       | awk -v qq=\" '{cmd1="ls -lT -dD '\''%m-%d-%Y %H:%M'\'' "qq $0 qq" | awk '\'' {print $6"qq" "qq"$7} '\''"; cmd2="crc32 "qq $0 qq" 2> /dev/null && echo 00000000"; if((cmd1|getline x) > 0 && (cmd2|getline y) > 0){print $0"\t"x"\t"y"\t.\t.\t*"}}' \
       #| sed -e 's/^\(.*\)\/$//';
       ) | column -t -s$'\t'

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
     filename=$(dirname $BKP_TARGET_PATH)/$(basename $BKP_DIR_NAME | awk '{printf $1}')_$(date -jf %s $id +%Y-%m-%d_%H.%M.%S).zip

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
 timethresh=$(date -jf '%Y-%m-%d_%H.%M.%S' $(date -v -"$daythresh"d +"%Y-%m-%d_%H.%M.%S") +%s)
 if [ -d $(dirname "$BKP_TARGET_PATH") ]; then
  oldfilesdir=old_files
  mkdir -p "$(dirname "$BKP_TARGET_PATH")/$oldfilesdir"
  unset $mvscr 
  mvscr=$(ls "$(dirname "$BKP_TARGET_PATH")/"$BKP_DIR_NAME_*zip"" \
          | awk -v dirwc="$(basename $BKP_DIR_NAME | awk '{printf $1}' | wc -c | awk '{printf $1}')" \
                -v timethresh=$timethresh \
                -v dirname=$oldfilesdir \
                -v qq=\" \
                'BEGIN{ORS="\\n"}
                 {cmd0="date -jf '\''%Y-%m-%d_%H.%M.%S'\'' $(basename '\''"$1"'\'' | sed '\''s/^.\\{"dirwc"\\}_\\(.*\\)\\.zip$/\\1/g'\'') +%s"
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
    if [ "$COMMANDOPT" = "force" ]; then
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
if [ -n "$descr" ]; then
 dirwc=$(basename $BKP_DIR_NAME | awk '{printf $1}' | wc -c | awk '{printf $1}')
 bkpid=$(date -jf '%Y-%m-%d_%H.%M.%S' $(basename "$BKP_TARGET_PATH" | sed "s/^.\{$dirwc\}_\(.*\)$/\\1/g") +%s)
 descrvarname=DESCR_$bkpid
 declare $descrvarname="$descr"
 echo $descrvarname:${!descrvarname} | sed 's/^\(\([^:]*\):\(.*\)\)$/\2:\3/g' >> $(dirname "$BKP_TARGET_PATH")/meta.dat
fi
set -x
zip  "$BKP_TARGET_PATH".zip ./*  | tee "$BKP_TARGET_PATH".log
{ set +x; } 2>/dev/null; echo "Command output directed to:"
echo "$BKP_TARGET_PATH".log

