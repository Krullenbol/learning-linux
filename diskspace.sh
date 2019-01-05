#!/bin/bash

# variables
# script variables
VERSION='1.0.1'
# define log location
LOCATION_LOGFILES='/var/lib/diskspace'

# functions
function method_telegram {
    # input for variables
    TELEGRAM_CHAT_ID="-306261393"
    TELEGRAM_URL="https://api.telegram.org/bot602094817:AAHxbZtXbgpNLMRb0LfpZ2uZpOPrjX86cfc/sendMessage"

    # create payload for Telegram
    TELEGRAM_PAYLOAD="chat_id=${TELEGRAM_CHAT_ID}&text=${MESSAGE}&parse_mode=Markdown&disable_web_page_preview=true"

    # sent payload to Telegram API and exit
    curl -s --max-time 10 --retry 5 --retry-delay 2 --retry-max-time 10 -d "${TELEGRAM_PAYLOAD}" "${TELEGRAM_URL}" > /dev/null 2>&1 &
}

function method_cli {
    echo ${MESSAGE}
}

function rotate_logs {
    # rotate log files one day
    rm ${LOCATION_LOGFILES}/yesterday.txt
    mv ${LOCATION_LOGFILES}/today.txt ${LOCATION_LOGFILES}/yesterday.txt
}

function value_comparison {
    # put current values in variables
    PREVIOUS_VALUE="$(cat ${LOCATION_LOGFILES}/yesterday.txt)"
    CURRENT_VALUE="$(($(df / --output="used" | sed -n '2 p' | tr -dc '1234567890.')/1024))"
    echo "${CURRENT_VALUE}" >> "${LOCATION_LOGFILES}/today.txt"

    # compare old and new values for message
    if (( ${CURRENT_VALUE} > ${PREVIOUS_VALUE} )); then
        DIFFERENCE="$((${CURRENT_VALUE} - ${PREVIOUS_VALUE}))"
        DIFFERENCE_MESSAGE="De gebruikte schijfruimte is dus met ${DIFFERENCE} MB toegenomen."
    elif (( ${CURRENT_VALUE} < ${PREVIOUS_VALUE} )); then
        DIFFERENCE="$((${PREVIOUS_VALUE} - ${CURRENT_VALUE}))"
        DIFFERENCE_MESSAGE="De gebruikte schijfruimte is dus met ${DIFFERENCE} MB afgenomen."
    elif (( ${CURRENT_VALUE} == ${PREVIOUS_VALUE} )); then
        DIFFERENCE="0"
        DIFFERENCE_MESSAGE="De gebruikte schijfruimte is dus exact evenveel als de vorige keer."
    else
        DIFFERENCE_MESSAGE="Er is iets misgegaan (foutcode #01). Vraag uw systeembeheerder dit probleem op te lossen."
    fi

    # generate message for Telegram
    MESSAGE="De vorige keer was uw gebruikte schijfruimte: ${PREVIOUS_VALUE} MB.\\nNu is uw gebruikte schijfruimte: ${CURRENT_VALUE} MB.\\n${DIFFERENCE_MESSAGE}"
}

# catch arguments and run functions
case "$1" in
    # options
    --version)
        echo
        echo "Diskspace ${VERSION}"
        echo
        shift
        ;;

    --help|-help|help|--h|-h)
        echo
        echo "Usage:"
        echo " diskspace [option]..."
        echo
        echo "Options:"
        echo " -c, --cli               Output to CLI"
        echo " -t, --telegram          Output to Telegram"
        echo
        shift
        ;;

    --cli|-c)
        rotate_logs
        value_comparison
        method_cli
        exit 0
        shift
        ;;

    --telegram|-t)
        rotate_logs
        value_comparison
        method_telegram
        exit 0
        shift
        ;;
esac
