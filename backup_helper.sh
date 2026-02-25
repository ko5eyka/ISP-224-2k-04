#!/bin/bash

# === backup_helper.sh ===

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# === Доп. задание 3 ===
if [[ "$1" == "-h" ]]; then
    echo "Использование: $0 [ИСТОЧНИК] [МЕСТО_СОХРАНЕНИЯ]"
    echo "Пример: $0 ./test_data ~/my_backups"
    exit 0
fi

# === Доп. задание 1 ===
SOURCE_DIR="$1"
BACKUP_DIR="${2:-$HOME/backups}" 
LOG_FILE="$BACKUP_DIR/backup.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

if [ $# -eq 0 ]; then
    echo -e "${RED}Ошибка: Укажите директорию для резервного копирования${NC}"
    echo "Пример: ./backup_helper.sh /path/to/directory"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Ошибка: Директория '$SOURCE_DIR' не существует${NC}"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "${GREEN}[LOG]${NC} $1"
}

log_message "=== Запуск резервного копирования ==="
log_message "Источник: $SOURCE_DIR"

# === Доп. задание 4 ===
BASENAME=$(basename "$SOURCE_DIR")
if find "$BACKUP_DIR" -name "${BASENAME}_backup_*" -mmin -60 | grep -q .; then
    echo -e "${YELLOW}Предупреждение: Бэкап уже создавался в последний час.${NC}"
    read -p "Продолжить создание? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_message "Отмена: Бэкап уже существует (создан менее часа назад)"
        exit 0
    fi
fi

MIN_SPACE_MB=100
AVAILABLE_SPACE=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
AVAILABLE_SPACE_MB=$((AVAILABLE_SPACE / 1024))

if [ "$AVAILABLE_SPACE_MB" -lt "$MIN_SPACE_MB" ]; then
    log_message "${YELLOW}Внимание: Мало свободного места ($AVAILABLE_SPACE_MB МБ)${NC}"
    read -p "Продолжить? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_message "Резервное копирование отменено пользователем"
        exit 1
    fi
fi

BACKUP_FILE="$BACKUP_DIR/${BASENAME}_backup_$TIMESTAMP.tar.gz"

log_message "Создание архива: $BACKUP_FILE"
tar -czf "$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log_message "Архив успешно создан: $BACKUP_FILE ($FILE_SIZE)"
else
    log_message "${RED}Ошибка при создании архива${NC}"
    exit 1
fi

log_message "Информация о архиве:"
echo "Размер: $(du -h "$BACKUP_FILE" | cut -f1)"
echo "Файлов в архиве: $(tar -tzf "$BACKUP_FILE" | wc -l)"
echo "Контрольная сумма (md5): $(md5sum "$BACKUP_FILE" | cut -d' ' -f1)"

# === Доп. задание 2 ===
log_message "Очистка старых архивов (старше 7 дней)..."
find "$BACKUP_DIR" -name "${BASENAME}_backup_*.tar.gz" -type f -mtime +7 -exec rm {} \; -print >> "$LOG_FILE"

echo "=== УВЕДОМЛЕНИЕ ===" > "$BACKUP_DIR/last_notification.txt"
echo "Резервная копия $BASENAME создана успешно" >> "$BACKUP_DIR/last_notification.txt"

log_message "Резервное копирование завершено успешно!"
log_message "Лог сохранен: $LOG_FILE"

echo -e "\n${YELLOW}Последние записи лога:${NC}"
tail -n 5 "$LOG_FILE"
