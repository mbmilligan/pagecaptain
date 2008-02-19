#!/bin/bash

function spaces {
  local i
  for ((i=0; $i<$1; i++))
  do echo -n " "
  done
}

green=$(tput setf 2)
red=$(tput setf 4)
orig=$(tput op)
files=$(find -type f | xargs -l basename)

maxlen=0
for f in $files
  do len=$((${#f} + 1))
  if [ $len -gt $maxlen ]
    then maxlen=$len
  fi
done

for f in $files
  do count=$(grep -r $f * | wc -l)
  echo -ne "${green}$f${orig}:"
  len=$((${#f} + 1))
  spaces $(( 3 + $maxlen - $len ))
  if [ $count == 0 ]
    then count="${red}$count${orig}"
  fi
  echo " $count matches"
done
