#!/bin/bash
# This script enables checking if any active tasks are running on the TrueNAS instance
# The script also counts the number of SSH sessions, as this could be indicative of a replication task
# If there are no ssh connections or running tasks, exit code is 0, otherwise exit code is 1
# Note that running tasks would include the CRON task itself running, so the number must be GT 1
# The script also examines the smb file locks which would indicate that a file or folder is being accessed, file lock list is compared against the list of smb shares

SSH_CONS=$(ps x | grep 'sshd:' | grep -v -e 'grep' -e 'listener' | wc -l)
RUNNING_TASKS=$(midclt call core.get_jobs "[[\"state\",\"=\",\"RUNNING\"]]" | jq length)
SMB_LOCKS=$(grep -vxFf <( midclt call sharing.smb.query | jq --raw-output '.[]."path_local" | . += "/."' ) <( sudo smbstatus --locks -j | jq --raw-output '."open_files" | to_entries | .[].key' ) | wc -l)

if [ "$SSH_CONS" -gt 0 ] || [ "$RUNNING_TASKS" -gt 1 ] || [ "$SMB_LOCKS" -gt 0 ]
then
    exit 1
else
    exit 0
fi

