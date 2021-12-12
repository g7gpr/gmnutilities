#!/bin/bash
if ping -c1 $1 &> /dev/null ; then
echo $1 " is up"    | mail -s $1" is up" g7gpr@outlook.com
else
echo $1 " is down " | mail -s $1" is down" g7gpr@outlook.com, davidrollinson@hotmail.com
fi


