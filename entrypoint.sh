#!/usr/bin/env bash

if [[ $1 = 'bash' ]]; then
    exec bash
else
    exec score-post-notifier "$@"
fi
