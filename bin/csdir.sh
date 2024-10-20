base=/home/.../tmp
Usage()
{
 echo
 echo "Usage: csdir -s SiteID -c CaseID [-h]"
 echo
}
Options()
{
 echo "Options:"
 echo "s        Site ID."
 echo "c        Case ID."
 echo "h        Print this Help."
 echo
}
Help()
{
 echo
 echo "Create a directory path with the specified site and case IDs."
 echo "Modify the script to change the base directory as needed."
 echo "Currently specified base direcory is $base"
 Usage
 Options
}

while [ True ]; do
  if [ -z "$1" ]; then
    break
  elif [ $1 = "-h" ]; then
    Help
    exit 0
  elif [ $1 = "-c" -o $1 = "--case" ]; then
    shift 1
    case=$1
    shift 1
  elif [ $1 = "-s" -o $1 = "--site" ]; then
    shift 1
    site=$1
    shift 1
  else
    break
  fi
done

if [ -z "$case" -o -z "$site" ]; then
  echo "Invalid command usage!"
  Usage
  exit 1
fi
fullpath=$base/$(echo $site | tr '[:lower:]' '[:upper:]')/$(echo $case | tr '[:lower:]' '[:upper:]')
(ls $fullpath 1> /dev/null 2>&1 || echo Creating $fullpath) && mkdir -p $fullpath && echo Changing to $fullpath in a subshell && echo -e '\nHit [Ctrl]+[D] or type "exit" to exit this child shell' && wkdir=$(pwd) && cd $fullpath && exec env PARENTWKDIR="$wkdir" env PROMPT_COMMAND='DEFAULT=${DEFAULT:-$PS1}; export PS1="(csdir) $DEFAULT"' bash
