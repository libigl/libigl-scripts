#!/bin/bash

for i in {1..60}
do
  make clean &>/dev/null
  printf "$i  "
  t=`(time make -j$i igl&>/dev/null) 2>&1 | grep real | sed -e "s/real[^0-9]*//g"`
  echo "$t"
done
