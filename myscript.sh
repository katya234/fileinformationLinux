#!/bin/bash

search_file() {
    local filename=$1
    echo "Ищем файл в системе..."
    
    # Ищем файл с помощью locate (быстро) или find (медленнее, но точнее)
    if command -v locate &>/dev/null; then
        results=($(locate -b "\/$filename" 2>/dev/null))
    else
        echo "Внимание: команда 'locate' не найдена, используем медленный поиск через 'find'..."
        results=($(find / -name "$filename" 2>/dev/null | head -10))
    fi

    if [ ${#results[@]} -eq 0 ]; then
        echo "Файл '$filename' не найден в системе."
        return 1
    elif [ ${#results[@]} -eq 1 ]; then
        echo "Найден файл: ${results[0]}"
        analyze_file "${results[0]}"
    else
        echo "Найдено несколько файлов:"
        for i in "${!results[@]}"; do
            echo "$((i+1)). ${results[$i]}"
        done
        
        read -p "Выберите номер нужного файла (1-${#results[@]}), или 0 для отмены: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#results[@]} ]; then
            analyze_file "${results[$choice-1]}"
        else
            echo "Поиск отменен."
        fi
    fi
}

analyze_file() {
    local filepath="$1"
    echo -e "\nИнформация о файле: $filepath"
    echo "--------------------------------"
    
    if [ -f "$filepath" ]; then
        echo "● Тип: Обычный файл"
    elif [ -d "$filepath" ]; then
        echo "● Тип: Директория"
    elif [ -L "$filepath" ]; then
        echo "● Тип: Символьная ссылка"
    else
        echo "● Тип: Специальный файл"
    fi
    
    echo "● Владелец: $(stat -c %U "$filepath" 2>/dev/null || echo "недоступно")"
    echo "● Права доступа: $(stat -c %A "$filepath" 2>/dev/null || echo "недоступно")"
    
    if [ -d "$filepath" ]; then
        echo "● Размер: $(du -sh "$filepath" | cut -f1) (директория)"
    else
        echo "● Размер: $(du -sh "$filepath" | cut -f1) (детально: $(wc -c < "$filepath" 2>/dev/null || echo 0) байт)"
    fi
    
    echo "● Дата изменения: $(stat -c %y "$filepath" 2>/dev/null || echo "недоступно")"
    echo -e "--------------------------------\n"
}

while true; do
    read -p "Введите имя файла для поиска (или 'exit' для выхода): " filename
    
    [ "$filename" == "exit" ] && break
    [ -z "$filename" ] && echo "Ошибка: Пустое имя!" && continue
    
    search_file "$filename"
done
