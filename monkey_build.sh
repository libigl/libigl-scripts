#!/bin/bash
#

# If there's no arg print help
if [ $# -eq 0 ]
  then
    echo "Usage: monkey_build.sh <path_to_libigl>"
    exit 1
fi

# First arg
LIBIGL=$1
echo -e "`ls -1 $LIBIGL/include/igl/*.h | sed -e "s/.*igl\/\(.*\)/#include <igl\/\1>/" | perl -MList::Util=shuffle -wne 'print shuffle <>;'`\\n  int main(){ }" | clang++ -xc++ - -I$LIBIGL/include -I $LIBIGL/build/_deps/eigen-src/ -std=c++11
