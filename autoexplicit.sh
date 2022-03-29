#!/bin/bash

while getopts ":C:h" opt; do
  case $opt in
    C)
      CDIR="$OPTARG"
      if ! cd "$CDIR" 2>/dev/null
      then
        (>&2 echo "Failed to change directory to $OPTARG")
        exit 1
      fi
      ;;
    h)
      echo "
Usage:
  
    autoexplicit.sh [-C dir] \"
    Undefined symbols for architecture x86_64:
     \\\"...\\\" \"

Or 

    make -C [your_project] 2>&1 | autoexplicit.sh -C \$LIBIGL"
      exit 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

# Shift so that $# makes sense
shift $((OPTIND-1))


# process input line by line
while read line; do
  if ! echo "$line" | grep -q "^\".*\", referenced from:$"
  then 
    # undefined symbol line not found
    continue
  fi
  symbol=`echo "$line" | sed -e "s/^\"\(.*\)\", referenced from:$/\1/"`
  #echo "symbol = $symbol"
  filename=`echo "$symbol" | perl -pe "s#.*?igl::([A-z0-9_:]*).*$'$'#\1#"`
  filename=`echo "$filename" | sed -e "s/::/\//g"`
  #echo "filename = $filename"
  cpp="./include/igl/$filename.cpp"
  # append .cpp and check that file exists
  if [ ! -e "$cpp" ]
  then
    echo "Warning: $cpp does not exist, skipping ..."
    continue
  fi

  if ! grep -q "^\/\/ Explicit template instantiation*$" "$cpp"
  then
    echo "Warning: skipping $cpp because it does not match ^\/\/ Explicit template instantiation*$ "
    continue;
  fi

  before=`sed '/^\/\/ Explicit template instantiation$/q' "$cpp"`;
  #echo "before = $before"
  after=`sed '1,/^\/\/ Explicit template instantiation$/d' $cpp`;
  #echo "after = $after"
  explicit=`echo "template $symbol;" | sed -e "s/std::__1::/std::/g" | sed -e "s/__sFILE/FILE/g" | sed -e "s/CGAL::Lazy_exact_nt<__gmp_expr<__mpq_struct \\[1\\], __mpq_struct \\[1\\]> >/CGAL::Epeck::FT/g"`
  #echo "$explicit"
  if grep -F "$explicit" "$cpp"
  then
    echo "Error: $cpp already contains $explicit"
    echo "       Recompile igl static lib, recompile your project, and try again."
    continue
  fi
  echo "$before" > "$cpp"
  echo "// generated by autoexplicit.sh" >> "$cpp"
  echo "$explicit" >> "$cpp"
  echo "$after" >> "$cpp"

done
