#!/bin/bash

mbsync -a >/dev/null 2>&1

UNREAD=$(find ~/files/mail -type f -name '*:2,*' ! -name '*S*' | wc -l)

if [ "$UNREAD" -gt 0 ]; then
  echo "   $UNREAD"
else
  echo " "
fi
