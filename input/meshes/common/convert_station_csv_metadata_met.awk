BEGIN { FS="," } 
NR>2 && $19 ~ /met/ { print $10" "$9" ! "$3" ! "$6" ! "$4" ! "$14 }
