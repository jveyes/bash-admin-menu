#!/bin/bash
if command -v fortune >/dev/null 2>&1; then
  fortune
else
  echo "No fortune available."
fi 