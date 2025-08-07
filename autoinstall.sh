#!/bin/bash

# Проверка прав администратора
if [ "$EUID" -ne 0 ]
  then echo "Запустите скрипт с правами root: sudo ./install_packages.sh"
  exit
fi

# Обновление индексов пакетов
echo -e "\e[34mОбновление списка пакетов...\e[0m"
apt-get update -qq

# Список пакетов для установки
packages=(
  # Системные утилиты
  openssh-server ufw git curl wget neovim python3 rustup lm-sensors hwinfo 
  smartmontools sysstat inxi dmidecode gddrescue memtester htop iotop nmon 
  stress build-essential
  
  # Сетевое ПО
  openvpn easy-rsa
  
  # Веб-сервер и БД
  apache2 mysql-server php libapache2-mod-php php-mysql phpmyadmin
  
  # FTP и файловые операции
  vsftpd filezilla
  
  # Графика и VNC
  tigervnc-standalone-server tigervnc-common
  
  # Оборудование и периферия
  zbar-tools qtqr libsane sane-utils cups cups-bsd printer-driver-gutenprint 
  libusb-dev libhidapi-dev libfprint-dev libpam-fprint
  
  # Дополнительные инструменты
  expect
)

# Функция для отображения прогресса
progress_bar() {
    local duration=${1}
    local columns=$(tput cols)
    local space=$(( columns - 16 ))
    for (( i=0; i<=duration; i++ )); do
        perc=$((i*100/duration))
        bar=$((i*space/duration))
        printf "\r\e[32mУстановка... [%-${space}s] %d%%\e[0m" $(printf "#%.0s" $(seq 1 $bar)) $perc
        sleep 1
    done
    printf "\n"
}

# Установка пакетов
echo -e "\e[34mНачало установки ${#packages[@]} пакетов...\e[0m"

# Запись логов в файл
log_file="package_install.log"
echo "Лог установки пакетов" > $log_file
echo "Дата: $(date)" >> $log_file
echo "==================================" >> $log_file

# Основной цикл установки
for package in "${packages[@]}"; do
    echo -e "\n\e[33mУстанавливается: $package\e[0m"
    echo "Установка $package" >> $log_file
    
    # Проверка доступности пакета
    if apt-cache show $package &>> $log_file; then
        # Установка с подавлением стандартного вывода
        if apt-get install -y -qq $package &>> $log_file; then
            echo -e "\e[32mУспешно: $package установлен\e[0m"
            echo "Статус: Успешно" >> $log_file
        else
            echo -e "\e[31mОшибка: Не удалось установить $package\e[0m"
            echo "Статус: Ошибка" >> $log_file
            failed_packages+=("$package")
        fi
    else
        echo -e "\e[31mОшибка: Пакет $package недоступен в репозиториях\e[0m"
        echo "Статус: Недоступен" >> $log_file
        failed_packages+=("$package")
    fi
    
    echo "----------------------------------" >> $log_file
done

# Отчет об установке
echo -e "\n\e[34m===== Результаты установки =====\e[0m"
echo "Всего пакетов: ${#packages[@]}"
echo "Успешно установлено: $((${#packages[@]} - ${#failed_packages[@]}))"

if [ ${#failed_packages[@]} -ne 0 ]; then
    echo -e "\e[31mНе установлено: ${#failed_packages[@]}\e[0m"
    echo "Список проблемных пакетов:"
    for pkg in "${failed_packages[@]}"; do
        echo " - $pkg"
    done
    echo -e "\e[33mПроверьте лог-файл для деталей: $log_file\e[0m"
else
    echo -e "\e[32mВсе пакеты успешно установлены!\e[0m"
fi

# Автоудаление ненужных зависимостей
echo -e "\n\e[34mОчистка ненужных пакетов...\e[0m"
apt-get autoremove -y -qq
apt-get clean -qq

echo -e "\n\e[32mУстановка завершена в $(date +"%T")\e[0m"