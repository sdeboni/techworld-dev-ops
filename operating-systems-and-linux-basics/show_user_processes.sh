#! /bin/bash
ps aux | head -n 1
ps aux | sed -n "/^$USER/p"
echo

read -p 'Sort by [cpu/MEM]: ' order
if [ -z $order ] || [ "$order" = "MEM" ] 
then
  order="mem"
elif [ "$order" != "cpu" ] && [ "$order" != "mem" ]
then
  echo 'invalid option'
  exit 1
fi
col=3
if [ "$order" = "mem" ]
then
  col=4
fi
read -p "lines to print: " lines
if [ -n lines ] 
then
  n=$(echo $lines | sed -n -E '/^[0-9]+/p')
  if [ -z $n ]
  then
    echo 'invalid number of lines to output'
    exit 1
  fi
else 
  n=0
fi

ps aux | head -n 1
ps aux | sed -n "/^$USER/p" | sort -k"$col,$col"n -k2,2n | head -n $n

