#!/bin/bash
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
  echo "Internet: OK"
else
  echo "Internet: FAIL"
fi 