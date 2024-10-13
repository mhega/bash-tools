#!/bin/bash
user=mhega

Usage()
{
  echo
  echo "Usage: mkscr  [-h] | -n Name -a Addr -p Port [-u User]"
  echo
}
Options()
{
  echo "Options:"
  echo "n		Script name."
  echo "a		IP Address."
  echo "p		Port."
  echo "u               User." 
  echo
}
Help()
{
  # Display Help
  echo
  echo "Create a connection script wiith the specified attributes."
  Usage  
  Options
}
Errinvalid()
{
  echo Invalid command usage!
  Usage
  exit 1
}

while [ True ]; do
  if [ -z "$1" ]; then
    if [ -z "$name" -o -z "$addr" -o -z "$port" -o -z "$user"  ]; then
      Errinvalid
    else
      break
    fi
  elif [ "$1" = "-h" -o "$1" = "--h" ]; then
    Help
    exit 0
  elif [ "$1" = "-n" ]; then
    shift 1
    name=$1
    shift 1
  elif [ "$1" = "-a" ]; then
    shift 1
    addr=$1
    shift 1
  elif [ "$1" = "-p" ]; then
    shift 1
    port=$1
    shift 1
  elif [ "$1" = "-u" ]; then
    shift 1
    user=$1
    shift 1
  else
    Errinvalid
  fi
done

echo "Name       : " $name
echo "IP Address : "$addr
echo "Port       : "$port
echo "User       : "$user


sed "s/<<IPADDR>>/$addr/g;s/<<PORT>>/$port/g;s/<<USER>>/$user/g" ../lib/host.tmplt > ./$name || exit 1

chmod +x ./$name || echo "Failed to grant execute permission to $name"

echo
echo "$name created.."
echo
