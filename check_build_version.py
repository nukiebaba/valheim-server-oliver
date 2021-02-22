#!/usr/bin/env python3

import json
import re

import subprocess
cmd = subprocess.Popen(
    'sh /opt/steam/steamcmd/steamcmd.sh +login anonymous +app_info_print 896660 +exit', shell=True, stdout=subprocess.PIPE)

build_id = "0"
in_branches_section = False
in_public_branch_section = False
for line in cmd.stdout.read().decode('utf-8').splitlines():
    if "branches" in line:
        in_branches_section = True
    if in_branches_section:
        if "public" in line:
            in_public_branch_section = True
    if in_public_branch_section:
        if "buildid" in line:
            match = re.search(
                r'\W*\"buildid\"\W+\"([0-9]+)\"\W*', line.strip())
            if match:
                build_id = match.group(1)
                break
print(build_id)
