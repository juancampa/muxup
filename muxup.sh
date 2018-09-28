#!/bin/bash

SESSION_NAME=ayva

tmux has-session -t $SESSION_NAME 
if [ "$?" != "0" ] ; then
  echo 'STARTING NEW SESSION'
  tmux new-session -d -s $SESSION_NAME
fi

WINDOWS=`tmux list-windows -t $SESSION_NAME -F "#W"`
PROJECTS='ayva-common ayva-util ayva-node ayva-web ayva-code ayva-broker ayva-toolkit ayva-api ayva-hooks programs'

for dirName in $PROJECTS; do
    project=`echo $dirName | cut -d"-" -f 2`
    exists=0
    for window in $WINDOWS; do
        if [ "$window" == "$project" ] ; then
            exists=1
            break;
        fi
    done

    if [ "$exists" != "0" ]; then
        echo "Exists $project"
        continue
    fi
    echo Creating $project

    dir="$HOME/git/$dirName"
    srcDir="$dir/src"
    if [ -d "$srcDir" ] ; then
        topCommand="npm run watch"
        midCommand="npm run dev"
    else
        topCommand="echo top"
        midCommand="echo mid"
    fi
    botCommand="cowsay $project"

    # Determine if there's a vim session for this project
    if [ -f "$HOME/.vim/sessions/${dirName}.vim" ] ; then
      mainCommand="vim -c \"OpenSession! $dirName\""
    else
      mainCommand="vim . -c \"SaveSession $dirName\""
    fi

    # Create the new window running the main mainCommand
    tmux new-window -d -n $project -c ${dir} "bash --rcfile <(echo '. ~/.bashrc ; $mainCommand')";

    # Side pane
    tmux split-window -h -p 30 -t "$SESSION_NAME:$project.0" -c $dir "bash --rcfile <(echo '. ~/.bashrc ; $topCommand')"

    # Side bot pane
    if [ "$botCommand" != "" ] ; then
        tmux split-window -v -p 70 -t "$SESSION_NAME:$project.1" -c $dir "bash --rcfile <(echo '. ~/.bashrc ; $botCommand')"
    fi

    # Side mid pane
    if [ "$midCommand" != "" ] ; then
        tmux split-window -v -p 50 -t "$SESSION_NAME:$project.1" -c $dir "bash --rcfile <(echo '. ~/.bashrc ; $midCommand')"
    fi
done

