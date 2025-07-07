#!/bin/bash
# Cross-platform memory display using main menu helper
declare -f show_mem >/dev/null 2>&1 && show_mem || echo "Memory display not supported on this OS." 