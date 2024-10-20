#! /bin/bash
dir="All"
base=/Users/mhega/csdir.d/Cases
Usage()
{
 echo
 echo "Usage: csdir [-s [Site [-i]]] [-c] [Case] [-h]"
 echo
}
Options()
{
 echo "Options"
 echo "-------"
 echo
 echo "s        Site.              * A site cannot start with Hyphen"
 echo "c        Case.              * A case cannot start with Hyphen"
 echo "h        Print this Help."
 echo
 echo "Examples"
 echo "--------"
 echo
 echo "csdir                           List most recent 10 cases"   
 echo "csdir .                         List the case ID and site that is registered with the current case (this will fail if we are not in a csdir subshell)"
 echo "csdir -c                        List all cases"
 echo "csdir -s                        List all registered sites"
 echo "csdir -s .                      List the case ID and site that is registered with the current case (this will fail if we are not in a csdir subshell)"
 echo "csdir -c -s                     List all registered sites and linked cases"
 echo "csdir -s -c                     List all registered sites and linked cases"
 echo "csdir 123456                    Go to or create case 123456"
 echo "csdir -c 123456                 Go to or create case 123456"
 echo "csdir -s testsite               List all cases that are linked to testsite"    
 echo "csdir -s testsite -i            Input site description for testsite"
 echo "csdir -s testsite 123456        Go to or create case 123456, and link with testsite if not linked (Create testsite if it does not exist)"
 echo "csdir 123456 -s testsite        Go to or create case 123456, and link with testsite if not linked (Create testsite if it does not exist)"
 echo "csdir -s testsite -c 123456     Go to or create case 123456, and link with testsite if not linked (Create testsite if it does not exist)"
 echo "csdir -c 123456 -s testsite     Go to or create case 123456, and link with testsite if not linked (Create testsite if it does not exist)"
 echo
 echo "Examples with invalid usage"
 echo "---------------------------"
 echo
 echo "csdir 123456 -s                 Omit -s option or specify a site name if the intent is to create a new case directory"
 echo "csdir -s -c 123456              Omit -s option or specify a site name if the intent is to create a new case directory"
 echo "csdir -c -s testsite            Omit -c option or specify a case ID if the intent is to create a new case directory"
 echo "csdir -s testsite -i -c         Omit -c option if the intent is to input site description"
 echo
 echo "Created by Mohamed Hegazi"
 echo
}
Help()
{
 echo
 echo "Create a site (account) link and/or case directory if either or both do not exist and navigate to the created / specified case directory in a child bash process."
 echo "Modify the script to change the base directory as needed."
 echo "Currently specified base direcory is $base"
 Usage
 Options
}

# The following functions which are triple indented are not getting called from within the script, but are rather sourced in the user subshell for the user execution

   home()
   {
     echo "Going to $(basename $SCRWKDIR).."
     cd $SCRWKDIR
   }

   descr()
   {
     if [[ -z $SCRWKDIR ]]; then echo No case directory detected; return; fi
     read -p "Input a single-line case description and/or hit NewLine to skip: " descr
     if [ -n "$descr" ]; then
       caseid=$(md5 <(basename $SCRWKDIR) | rev | cut -c 1-32 | rev)
       descrvarname=DESCR_$caseid
       declare $descrvarname="$descr"
       echo $descrvarname:${!descrvarname} | sed 's/^\(\([^:]*\):\(.*\)\)$/\2:\3/g' >> $(dirname "$SCRWKDIR")/../case_meta.dat
     fi
   }

INPUTSITE()
{
 site=$(echo $1  | tr '[:lower:]' '[:upper:]')
 if ! ls $base/sites/$1/ 1> /dev/null 2>&1; then
  echo "No available site with name: $site"
  exit 1 
 fi
 read -p "Input a single-line site description and/or hit NewLine to skip: " sitedescr
 if [ -n "$sitedescr" ]; then
  siteid=$(md5 <(echo $site) | rev | cut -c 1-32 | rev)
  descrvarname=DESCR_$siteid
  declare $descrvarname="$(echo $sitedescr | openssl aes-256-cbc -a -salt -pass pass:$site$(ls -di ~ | cut -d "/" -f1))"
  echo $descrvarname:"${!descrvarname//$'\n'/$descrvarname}" | sed 's/^\(\([^:]*\):\(.*\)\)$/\2:\3/g' >> $base/site_meta.dat 
 fi
}

OUTPUTSITE()
{
 site=$(echo $1  | tr '[:lower:]' '[:upper:]')
 if ! ls $base/sites/$1/ 1> /dev/null 2>&1; then
  echo "No available site with name: $site"
  exit 1
 fi
 siteid=$(md5 <(echo $site) | rev | cut -c 1-32 | rev)
 descrvarname=DESCR_$siteid
 siterecord=$(grep $descrvarname $base/site_meta.dat | tail -1 | sed 's/^\(\([^:]*\):\(.*\)\)$/\3/g')
 if [[ -n $siterecord ]]; then
  #echo site=$site::descrvarname=$descrvarname::siterecord=$siterecord     ## For debugging
  echo $siterecord | sed "s/$descrvarname/\n/g" | openssl aes-256-cbc -d -a -pass pass:$site$(ls -di ~ | cut -d "/" -f1)
 fi
}

DISPLAYALLSITES()
{
 if [[ -z $routine_level ]]; then
  routine_level=1
  DISPLAYALLSITES | column -t -s $'\t'
 else
  files=($base/sites/*)
  #spacer="                               "
  echo -e "Name\tDescription\n----\t-----------"
  for f in ${files[@]}; do
   echo -e "$(basename $f)\t$(OUTPUTSITE $(basename $f))"
  done
  #echo -e "Tes\tTest site"  
 fi
}

DISPLAYSITE()
{
 site=$1
 sitedescr=$(OUTPUTSITE $site)
 if [[ -n $sitedescr ]]; then
  echo
  echo "Site Description: "$(OUTPUTSITE $site) 
 fi
 echo
 echo "List Of All Cases For Site $site"
 echo  ---------------------------"$site" | sed 's/./-/g' 
 echo
 metafile=$base/case_meta.dat
 ls $base/sites/$1/ 2> /dev/null | tr \\t \\n \
 |  awk \
        -v metafile=$metafile \
        -v base=$base \
        -v site=$site \
        -v q=\' -v qq=\" \
        'BEGIN{ORS=""
              print "\tCase ID\tDate Created\tDescription\n"
              print "\t-------\t------------\t-----------\n"}
         {
         cmddate="stat -l -t '%FT%T' '\''" base "/sites/" site "/" $1"'\'' | awk '\'' {print $6}'\'' | cut -d '\''T'\'' -f 1";
         cmddescr="[ -f "metafile" ] && id=DESCR_$(echo "$1" | md5 | rev | cut -c 1-32 | rev) && declare $id="qq"$(grep $id "metafile" | tail -1 | sed '\''s/^\\([^:]*\\):\\(.*\\)$/\\2/g'\'')"qq" && echo ${!id}"
         print "\t"
         print $1
         print "\t"
         if( (cmddate|getline x) > 0) { print x; close(cmddate) } else exit 1
         print "\t"
         if( (cmddescr|getline x) > 0) { print x; close(cmddescr) }
         print "\n"}
         END{if (NR==0) {exit 1}}' \
| column -t  -s$'\t'
 if [ ${PIPESTATUS[2]} != 0 ] ; then
   exit 1
 fi
 echo
}

DISPLAYALLSITECASES()
{
 echo
 echo "List Of All Cases by Site Name"
 echo "------------------------------"
 echo
 metafile=$base/case_meta.dat
 ls -d $base/sites/*/* 2> /dev/null | tr \\t \\n \
 |  awk \
        -v metafile=$metafile \
        -v base=$base \
        -v site=$site \
        -v q=\' -v qq=\" \
        'BEGIN{ORS=""
              print "\tSite\tCase ID\tDate Created\tDescription\n"
              print "\t----\t-------\t------------\t-----------\n"}
         {
         cmds="echo "$1" | rev | cut -d "q"/"q" -f 2 | rev"
         cmdsite="basename $(dirname $(ls -d "base"/sites/*/$(basename "$1")))"
         cmddate="stat -l -t '%FT%T' "$1" | awk '\'' {print $6}'\'' | cut -d '\''T'\'' -f 1";
         cmd2="basename "$1
         cmddescr="[ -f "metafile" ] && id=DESCR_$(basename "$1" | md5 | rev | cut -c 1-32 | rev) && declare $id="qq"$(grep $id "metafile" | tail -1 | sed '\''s/^\\([^:]*\\):\\(.*\\)$/\\2/g'\'')"qq" && echo ${!id}"
         print "\t"
         if( (cmds|getline x) > 0) { print x; close(cmds) }
         print "\t"
         if( (cmd2|getline x) > 0) { print x; close(cmd2) } else exit 1
         print "\t"
         if( (cmddate|getline x) > 0) { print x; close(cmddate) } else exit 1
         print "\t"
         if( (cmddescr|getline x) > 0) { print x; close(cmddescr) }
         print "\n"}
         END{if (NR==0) {exit 1}}' \
| column -t  -s$'\t'
 if [ ${PIPESTATUS[2]} != 0 ] ; then
   exit 1
 fi
 echo
}

DISPLAYALLCASES()
{

 echo

 if [[ -z $1 ]]; then
   echo "List Of All Cases"
   echo "-----------------"
   echo
 elif [[ $1 = "-s" ]]; then
   shift 1
   if [[ -z $1 ]]; then
     echo "Bad Internal Function Call!"
     exit 1
   else
     sitename=$1
   fi
 elif [[ $1 = "-n" ]]; then
   shift 1
   if [[ -z $1 ]]; then
     echo "Bad Internal Function Call!"
     exit 1
   else
     re='^[0-9]*$'
     if [[ $1 =~ $re ]]; then
       numrecords=$1
       echo "List Of Recent 10 Cases"
       echo "-----------------------"
       echo
     else
       echo "Bad Internal Function Call!"
       exit 1
     fi
   fi
 fi

 metafile=$base/case_meta.dat
ls -t $base/$dir 2> /dev/null | tr \\t \\n | ([[ -n $sitename ]] && grep -w $sitename || grep '$')  | ([[ -n $numrecords ]] && head -$numrecords || grep '$') |  awk         -v metafile=$metafile         -v base=$base         -v dir=$dir         -v site=$site         -v q=\' -v qq=\"         'BEGIN{ORS=""
              print "\tCase ID\tSite\tDate Last Visited\tDescription\n"
              print "\t-------\t----\t-----------------\t-----------\n"}
         {
         cmds="files=("base"/sites/*/"$1"); [ -d "qq"${files[0]}"qq" ] && (ls -d "base"/sites/*/"$1" | grep -Eo /sites/.*/ | cut -d "q"/"q" -f 3 | paste -s -d, /dev/stdin) || echo "qq" "qq
         cmddate="stat -l -t '%FT%T' " base "/" dir "/" $1 " | awk '\'' {print $6}'\'' | cut -d '\''T'\'' -f 1";
         #cmd2="basename "$1
         cmddescr="[ -f "metafile" ] && id=DESCR_$(echo "$1" | md5 | rev | cut -c 1-32 | rev) && declare $id="qq"$(grep $id "metafile" | tail -1 | sed '\''s/^\\([^:]*\\):\\(.*\\)$/\\2/g'\'')"qq" && echo ${!id}"
         print "\t"
         print $1
         print "\t"
         if( (cmds|getline x) > 0) { print x; close(cmds) }
         print "\t"
         if( (cmddate|getline x) > 0) { print x; close(cmddate) } else exit 1
         print "\t"
         if( (cmddescr|getline x) > 0) { print x; close(cmddescr) }
         print "\n"}
         END{if (NR==0) {exit 1}}' | column -t  -s$'\t'
 if [ ${PIPESTATUS[2]} != 0 ] ; then
   exit 1
 fi
 echo
}




error="f"
allsites="f"
allcases="f"
siteinput="f"
while [ True ]; do
  if [ -z "$1" ]; then
    break
  elif [ $1 = "-h" ]; then
    Help
    exit 0
  elif [ $1 = "-c" -o $1 = "--case" ]; then
    if [[ -n $case || $allcases = "t" ]]; then
      error="t"
      break
    fi
    shift 1
    if [[ -z $1 || $1 = "-s" || $1 = "--site" ]]; then
      if [ -z $site ]; then
        allcases="t"
      else
        error="t"
      fi
    elif [[ $allcases = "t" || $allsites = "t" ]]; then
      error="t"
      break
    else
      case=$1
      shift 1
    fi
  elif [ $1 = "-s" -o $1 = "--site" ]; then
    if [[ -n $site || $allsites = "t" ]]; then
      error="t"
      break
    fi
    shift 1
    if [[ -z $1 || $1 = "-c" || $1 = "--case" ]]; then
      if [ -z $case ]; then
        allsites="t"
      else
        error="t"
      fi
    elif [[ $allcases = "t" || $allsites = "t" ]]; then
      error="t"
      break
    else
      site=$1
      shift 1
      if [[ $1 = "-i" ]]; then
        siteinput="t"
        shift 1
      fi
    fi
  elif [ -z $case ]; then
    case=$1
    shift 1
  else
    error="t"
    break
  fi
done

re='^-.*'
if [[ $error = "t" || $case =~ $re || $site =~ $re ]]; then
  echo "Invalid command usage!"
  Usage
  exit 1
fi

if [[ -z $case && -z $site && $allsites = "f" && $allcases = "f" ]]; then
  #allcases="t"
  DISPLAYALLCASES -n 10
  exit 0
fi

if [[ $allsites = "t" && $allcases = "t" ]]; then
  DISPLAYALLSITECASES | more -n 20 -E
  #ls -ltF $base/sites/* | more -n 20 -E
  exit 0
elif [[ $allsites = "f" && $allcases = "t" ]]; then
  DISPLAYALLCASES | more -n 20 -E
  #ls -ltd $base/$(echo $dir | tr '[:lower:]' '[:upper:]')/* | more -n 10 -E
  exit 0
elif [[ $allsites = "t" && $allcases = "f" ]]; then
  #ls -ltd $base/sites/* | more -n 20 -E
  DISPLAYALLSITES
  exit 0
elif [[ -z $case && -n $site ]]; then
  if [[ $site = '.' ]]; then
    #ls -lt $base/sites/*/$(pwd | sed 's/^\/.*\/\(.*\)$/\1/g')
    if [[ -n $SCRWKDIR ]]; then
      DISPLAYALLCASES -s $(basename $SCRWKDIR)
      #$0 | grep -E "^(Case|----|$SCRWKDIR)"
    else
      echo "Invalid command usage"
      Usage
      exit 1
    fi
    exit 0
  elif [[ $siteinput = "t" ]]; then
    INPUTSITE $site
    exit 0 
  else
    DISPLAYSITE $site
    #ls -lt $base/sites/$(echo $site | tr '[:lower:]' '[:upper:]')/* | more -n 10 -E
    exit 0
  fi
elif [[ -z $site && $case = '.' && -n $SCRWKDIR ]]; then
  DISPLAYALLCASES -s $(basename $SCRWKDIR)
  exit 0
fi

re='^(\.)?[A-Za-z0-9]*$'
if ! [[ $case =~ $re && $site =~ $re ]]; then
  echo "Invalid command usage"
  Usage
  exit 1
fi

fullpath=$base/$(echo $dir | tr '[:lower:]' '[:upper:]')/$(echo $case | tr '[:lower:]' '[:upper:]')
if [[ -n "$site" ]]; then
  sitelink=$base/sites/$(echo $site | tr '[:lower:]' '[:upper:]')/
  mkdir -p "$sitelink"
fi

sfx=$(date +%s)
createhomefunc()
{
  awk '/ home\(\)/,/\ }/' $0 | grep -v awk > ./csdirutils_$sfx 
  awk '/ descr\(\)/,/\ }/' $0 | grep -v awk >> ./csdirutils_$sfx
  echo Changing to $fullpath in a subshell.
  echo
  echo Hit [Ctrl]+[D] or type "exit" to exit this child shell.
  echo
  echo A function named \"home\" with the following definition will be sourced so it can be used to quickly change to the current directory \($(basename $fullpath)\).
  echo To get back here, just type home.
  echo
  cat ./csdirutils_$sfx
  echo
}

	(ls $fullpath 1> /dev/null 2>&1 || echo Creating $fullpath) && mkdir -p $fullpath && ([[ -z $sitelink ]] || (ln -s "$fullpath" "$sitelink" 2>/dev/null && echo "$sitelink linked to case" || true)) && wkdir=$(pwd) && cd $fullpath && createhomefunc && exec env PARENTWKDIR="$wkdir" env SCRWKDIR="$fullpath" env CASE="$case" env PROMPT_COMMAND='DEFAULT=${DEFAULT:-$PS1}; export PS1="($CASE) $DEFAULT"' bash --init-file <(echo "source ./csdirutils_$sfx && rm ./csdirutils_$sfx")
