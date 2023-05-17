#!/bin/bash

history_file="history.json"
php_script_url_open="https://api.telegram.org/bot<BOT_TOKEN>/sendMessage?chat_id=<USER_ID>&text=Двері відчинено"
php_script_url_openA="https://api.telegram.org/bot<BOT_TOKEN>/sendMessage?chat_id=<USER_ID>&text=Двері відчинено"
php_script_url_close="https://api.telegram.org/bot<BOT_TOKEN>/sendMessage?chat_id=<USER_ID>&text=Двері зачинено"
php_script_url_closeA="https://api.telegram.org/bot<BOT_TOKEN>/sendMessage?chat_id=<USER_ID>&text=Двері зачинено"

# Сброс состояний пинов
gpio reset
# Подтяжка пина на землю
gpio mode 7 down
# Проверка наличия файла history.json
if [ ! -f "$history_file" ]; then
    echo "[]" > "$history_file"
fi

last_output=$(jq -r '.[-1].output' "$history_file")
# Задержка для устранения дребезга контактов
debounce_delay=0.01
while true; do
    output=$(gpio read 7)

    if [ "$output" != "$last_output" ]; then
        if [ "$output" -eq "1" ]; then
            curl  "$php_script_url_open" > /dev/null
            curl "$php_script_url_openA" > /dev/null
        else
            curl  "$php_script_url_close" > /dev/null
            curl "$php_script_url_closeA" > /dev/null
        fi
    fi

    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    result="{\"date\":\"$timestamp\",\"output\":\"$output\"}"

    # Добавление результата в файл history.json
    if [ "$output" != "$last_output" ]; then
        jq --argjson new_result "$result" '. + [$new_result]' "$history_file" > "$history_file.tmp" && mv "$history_file.tmp" "$history_file"
        last_output="$output"
    fi

    sleep 1.0
done
