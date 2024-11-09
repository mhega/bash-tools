#! /bin/bash

Usage()
{
 echo
 echo 'Usage: day [NumberOfPrecedingDays] [-d "Relative Date"] [-h]'
 echo
}
Options()
{
 echo "Options:"
 echo 'NumberOfPrecedingDays	Number of days preceding the date specified in Relative Date with files to be listed'
 echo 'd        		Relative Date - e.g "1" for Yesterday, or "2" for "2 Days Ago".'
 echo "h        		Print this Help."
 echo
 echo "This command version is compatible with MacOS/OSX."
 echo
 echo "Created by Mohamed Hegazi"
 echo
}
Help()
{
 echo
 echo "Lists all files in the current directory for a given day (DayString) and an optional number of preceding days."
 echo "Default Relative Date is 0 (Today)."
 Usage
 Options
}
while [ True ]; do
  if [ -z "$1" ]; then
    break
  elif [ "$1" = "-h" ]; then
    Help
    exit 0
  elif [ "$1" = "-d" ]; then
    shift 1
    if eval 'date -v -"$1"d' 1>/dev/null 2>&1; then
      d=$1
    else
      echo Invalid relative date "$d"!
      Usage
      exit 1
    fi
    shift 1
  elif [ -z "$prec" ]; then
    re='^[0-9]+$'
    if ! [[ $1 =~ $re ]]; then
        echo Invalid parameter!
        Usage
        exit 1
    fi
    prec=$1
    shift 1
  else
    echo Invalid command usage!
    Usage
    exit 1 
  fi
done

if [ -z "$prec" ]; then
  prec=0
fi
if [ -z "$d" ]; then
  d=0
fi

if echo $prec | grep -qx 0; then
  endstr=''
else
  endstr=' and '$prec' preceding day'
  if echo $prec | grep -qxv 1; then
    endstr=$endstr's'
  fi
fi

echo Listing files dated: $(date -v -"$d"d '+%Y-%m-%d')$endstr..

outp=''

for ((i=0;i<=$prec;i++)) 
do
  daylst=$(eval "ls -lT -D '+%Y-%m-%d' | grep $(date -v -$(($d + $i))d +%Y-%m-%d) | tr '\n' ','")
  outp=$outp$daylst
done

echo $outp | tr ',' '\n' | more -n 10 -E