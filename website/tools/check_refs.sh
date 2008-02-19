#!/bin/bash

for f in $(find -type f | xargs -l basename)
 do count=$(grep -r $f * | wc -l)
 echo -ne "`tput setf 2`$f`tput op`:\t"
 len=$(echo "$f:" | wc -c)
 if [ $len -le 16 ]
   then echo -ne "\t"
 fi
 if [ $count == 0 ]
   then count="`tput setf 4`$count`tput op`"
 fi
 echo " $count matches"
done
