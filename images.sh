#!/bin/bash

# Requirements:
# * Your REPLICATE_API_TOKEN needs to be sourceable from ~/.bashrc. If it's not, change that line in the script
# * ffmpeg, imagemagick, and the Replicate CLI (https://github.com/replicate/cli) all need to be installed

# Usage:
# 1. Open Automator.app
# 2. Click "New Document"
# 3. Choose "Quick Action" as the type for your document
# 4. Change "Workflow receives current" to "image files"
# 5. Select "Run Shell Script" as the action type
# 6. In the "Run Shell Script" window, change "Pass input:" to "as arguments"
# 7. Paste the contents of this file into the text editor in the "Run Shell Script" window
# 8. Cmd-S to save
# 9. Give it a name (e.g. "Convert image with AI" and hit Save)
# 10. Right-click on an image file in Finder and under Quick Actions, select your new action

# Source .bashrc to get the API key
source ~/.bashrc

# Prompt user for input
osascript -e 'display dialog "Enter image transformation prompt:" default answer "" buttons {"Cancel", "OK"} default button 2' -e 'text returned of result' > /tmp/user_prompt
USER_PROMPT=$(cat /tmp/user_prompt)
rm /tmp/user_prompt

# Process each input file
for file in "$@"; do
    FILEPATH="$file"
    DIRECTORY=$(dirname "$FILEPATH")
    FILENAME=$(basename "$FILEPATH")
    BASENAME="${FILENAME%.*}"

    # Construct the full prompt
    FULL_PROMPT="Make an imagemagick convert or ffmpeg script that does the following: ${USER_PROMPT}. Use '${FILEPATH}' as the input file and make up an output filename that makes sense, in the format '${DIRECTORY}/${BASENAME}.<short-description-of-what-you-did-without-spaces>.<extension>'. Only return the convert or ffmpeg command, with no backticks, comments, or explanations, as I intend to eval the output in a script."

    # Get the command
    COMMAND=$(replicate run meta/meta-llama-3.1-405b-instruct prompt="$FULL_PROMPT")

    syslog -s -l i "Command: $COMMAND"

    # Execute the command
    syslog -s -l i "Output: $(eval "$COMMAND" 2>&1)"
done
