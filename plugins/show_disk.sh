#!/bin/bash
# Cross-platform disk display using main menu helper
declare -f show_disk >/dev/null 2>&1 && show_disk || echo "Disk display not supported on this OS." 