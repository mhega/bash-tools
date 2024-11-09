
Usage()
{
 echo
 echo 'Usage: day [NumberOfPrecedingDays] [-d "DayString"] [-h]'
 echo
}
Options()
{
 echo "Options:"
 echo 'NumberOfPrecedingDays	Number of days preceding the date specified in DayString with files to be listed'
 echo 'd        		Day String - e.g "1 day ago".'
 echo "h        		Print this Help."
 echo
}
Help()
{
 echo
 echo "Lists all files in the current directory for a given day (DayString) and an optional number of preceding days."
 echo "Default DayString is today."
 echo "Enclose any space containing DayString in quotes."
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
    if eval 'date -d "$1"' 1>/dev/null 2>&1; then
      d=$1
    else
      echo Invalid DateString "$d"!
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
  d="today"
fi

if echo $prec | grep -qx 0; then
  endstr=''
else
  endstr=' and '$prec' preceding day'
  if echo $prec | grep -qxv 1; then
    endstr=$endstr's'
  fi
fi

echo Listing files dated: $(date -d "$d" +%Y-%m-%d)$endstr..

outp=''

for ((i=0;i<=$prec;i++)) 
do
  daylst=$(eval "ls -lt --full-time | grep $(date -d "$d - $i day" +%Y-%m-%d) | tr '\n' ','")
  outp=$outp$daylst
done

echo $outp | tr ',' '\n' | more -n 10
