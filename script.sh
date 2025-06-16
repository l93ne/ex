#!/bin/bash
log_error() {
    local message="$1"
    local log_file="$2"
    echo "$message" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $message" >> "$log_file"
}

# Функция выполнения вычислений
calculate() {
    local op="$1"
    shift
    local numbers=("$@")
    local result

    case "$op" in
        sum)
            result=0
            for n in "${numbers[@]}"; do
                result=$(echo "$result + $n" | bc -l)
            done
            ;;
        sub)
            result="${numbers[0]}"
            for ((i=1; i<${#numbers[@]}; i++)); do
                result=$(echo "$result - ${numbers[$i]}" | bc -l)
            done
            ;;
        mul)
            result=1
            for n in "${numbers[@]}"; do
                result=$(echo "$result * $n" | bc -l)
            done
            ;;
        div)
            result="${numbers[0]}"
            for ((i=1; i<${#numbers[@]}; i++)); do
                if [ $(echo "${numbers[$i]} == 0" | bc -l) -eq 1 ]; then
                    log_error "Деление на ноль недопустимо" "$log_file"
                    exit 1
                fi
                result=$(echo "$result / ${numbers[$i]}" | bc -l)
            done
            ;;
        pow)
            result="${numbers[0]}"
            if [ ${#numbers[@]} -gt 1 ]; then
                log_error "Для операции pow требуется одно число" "$log_file"
                exit 1
            fi
            result=$(echo "$result ^ 2" | bc -l)
            ;;
        *)
            log_error "Неверная операция: $op" "$log_file"
            exit 1
            ;;
    esac
    echo "Результат: $result"
}

# Парсинг аргументов
while getopts "o:n:l:" opt; do
    case $opt in
        o) operation="$OPTARG" ;;
        n) numbers="$OPTARG" ;;
        l) log_file="$OPTARG" ;;
        *) echo "Неверный аргумент"; exit 1 ;;
    esac
done

# Проверка аргументов
if [ -z "$operation" ]  [ -z "$numbers" ]  [ -z "$log_file" ]; then
    log_error "Не указаны все обязательные аргументы (-o, -n, -l)" "$log_file"
    exit 1
fi

# Проверка корректности операции
valid_ops=("sum" "sub" "mul" "div" "pow")
if ! [[ " ${valid_ops[@]} " =~ " $operation " ]]; then
    log_error "Неверная операция: $operation" "$log_file"
    exit 1
fi

# Преобразование строки чисел в массив
read -r -a num_array <<< "$numbers"

# Проверка количества чисел
if [ ${#num_array[@]} -lt 2 ] && [ "$operation" != "pow" ]; then
    log_error "Для операции $operation требуется минимум два числа" "$log_file"
    exit 1
elif [ ${#num_array[@]} -lt 1 ]; then
    log_error "Требуется хотя бы одно число" "$log_file"
    exit 1
fi

# Проверка, что все элементы являются числами
for n in "${num_array[@]}"; do
    if ! [[ "$n" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        log_error "Некорректное число: $n" "$log_file"
        exit 1
    fi
done

# Выполнение вычислений
calculate "$operation" "${num_array[@]}"
