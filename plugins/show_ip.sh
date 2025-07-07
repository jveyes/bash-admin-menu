#!/bin/bash
# Cross-platform IP display using main menu helper
declare -f show_ip >/dev/null 2>&1 && show_ip || echo "IP display not supported on this OS." 