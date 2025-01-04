#!/usr/bin/env bash

set -euo pipefail

_dir=$(dirname -- "$( readlink -f -- "$0"; )")
sudo cp -R --preserve=mode,timestamps -- "$_dir" /opt/
