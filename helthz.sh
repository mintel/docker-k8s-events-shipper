#!/bin/sh

if [ "x$OUTPUT_MODE" == "xstdout" ]; then
  /usr/bin/pgrep curl
  RETURN=$?  
elif [ "x$OUTPUT_MODE" == "xnetcat" ]; then
  /usr/bin/pgrep curl && /usr/bin/pgrep nc
  RETURN=$?  
else
  echo "Unsupported mode $OUTPUT_MODE" >&2
  RETURN=3
fi

exit $RETURN

