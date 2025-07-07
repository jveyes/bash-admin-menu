#!/bin/bash
if command -v cal >/dev/null 2>&1; then
  cal
else
  echo "The 'cal' command is not installed on this system."
fi 