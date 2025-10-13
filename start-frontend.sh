#!/bin/bash

CONTAINER_NAME="my-frontend"
PORT=1234

# Определяем доступный контейнерный движок
detect_container_engine() {
    if command -v podman >/dev/null 2>&1; then
        echo "podman"
    elif command -v docker >/dev/null 2>&1; then
        echo "docker"
    else
        echo "none"
    fi
}

CONTAINER_ENGINE=$(detect_container_engine)

if [ "$CONTAINER_ENGINE" = "none" ]; then
    echo "❌ Ошибка: Не найден ни Podman, ни Docker. Установите один из них."
    echo "📖 Ссылки для установки:"
    echo "   Podman: https://podman.io/"
    echo "   Docker: https://docs.docker.com/engine/install/"
    exit 1
fi

echo "✅ Используется контейнерный движок: $CONTAINER_ENGINE"

# Функция для открытия браузера в разных ОС
open_browser() {
    local url=$1
    echo "🌐 Попытка открыть браузер с URL: $url"

    # Проверка на WSL (Windows Subsystem for Linux)
    if command -v wsl >/dev/null 2>&1 && grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        echo "🪟 Обнаружена WSL (Windows Subsystem for Linux)"
        
        if command -v wslview >/dev/null 2>&1; then
            echo "   Пытаюсь открыть через wslview..."
            if wslview "$url"; then return; fi
        fi
        
        if command -v powershell.exe >/dev/null 2>&1; then
            echo "   Пытаюсь открыть через PowerShell..."
            powershell.exe /c start "$url" && return
        fi
        
        echo "   Пытаюсь открыть через explorer.exe..."
        explorer.exe "$(wslpath -w "$url")" && return

        echo "❌ Не удалось открыть браузер автоматически"
        echo "🔗 Откройте вручную: $url"

    # Проверка на macOS
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🍎 Открываю браузер в macOS..."
        open "$url"

    # Проверка на Linux
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "🐧 Открываю браузер в Linux..."
        
        if ! command -v xdg-open >/dev/null 2>&1; then
            echo "📦 xdg-open не найден, пытаюсь установить xdg-utils..."
            
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y xdg-utils
                if ! command -v xdg-open >/dev/null 2>&1; then
                    echo "❌ Ошибка установки xdg-utils"
                    echo "🔗 Откройте браузер вручную: $url"
                    return
                fi
            else
                echo "❌ Пакетный менеджер apt-get не найден"
                echo "🔗 Откройте браузер вручную: $url"
                return
            fi
        fi
        
        xdg-open "$url"

    # Проверка на Windows (Git Bash/Cygwin)
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "🪟 Открываю браузер в Windows (gitbash/cygwin)..."
        cmd.exe /c start "" "$url"

    else
        echo "❓ Неизвестная ОС"
        echo "🔗 Откройте ссылку вручную: $url"
    fi
}

echo ""
echo "📦 === Список доступных образов ==="
$CONTAINER_ENGINE images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
echo ""

echo "🐳 === Текущие контейнеры (запущенные и остановленные) ==="
$CONTAINER_ENGINE ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Запрос имени контейнера
read -p "📝 Введите имя контейнера для запуска (по умолчанию \"$CONTAINER_NAME\"): " input_name
if [ -n "$input_name" ]; then
    CONTAINER_NAME=$input_name
fi

# Проверка существования контейнера и управление им
if $CONTAINER_ENGINE ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    STATUS=$($CONTAINER_ENGINE inspect --format '{{.State.Status}}' $CONTAINER_NAME 2>/dev/null)
    
    if [ "$STATUS" = "running" ]; then
        echo "✅ Контейнер $CONTAINER_NAME уже запущен."
    else
        echo "🚀 Запускаю контейнер $CONTAINER_NAME..."
        $CONTAINER_ENGINE start $CONTAINER_NAME
    fi
else
    echo "🛠️ Создаю и запускаю контейнер $CONTAINER_NAME..."
    $CONTAINER_ENGINE run -d \
        --name $CONTAINER_NAME \
        -p $PORT:$PORT \
        -v "$(pwd)/frontend:/app" \
        -w /app \
        node:18-alpine \
        sh -c "npm install && npm start"
fi

echo ""

# Определение URL для доступа
URL="http://localhost:$PORT"

# Особый случай для WSL - используем IP WSL для доступа с Windows
if command -v wsl >/dev/null 2>&1 && grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    WIN_IP=$(wsl hostname -I | awk '{print $1}')
    if [[ -n "$WIN_IP" ]]; then
        URL="http://${WIN_IP}:$PORT"
        echo "🌐 WSL обнаружен, используем IP: $WIN_IP"
    else
        echo "⚠️ Не удалось получить IP WSL, используем localhost"
    fi
fi

echo "🔗 Фронтенд доступен по адресу: $URL"
echo ""

# Предложение открыть браузер
read -p "🌐 Открыть браузер автоматически? (y/n) [n]: " open_resp
open_resp=${open_resp:-n}

if [[ $open_resp =~ ^[Yy]$ ]]; then
    open_browser "$URL"
else
    echo "⏭️ Открытие браузера пропущено."
fi

echo ""
echo "📋 Команды для управления контейнером:"
echo "   ⏹️  Остановка:    $CONTAINER_ENGINE stop $CONTAINER_NAME"
echo "   🗑️  Удаление:     $CONTAINER_ENGINE rm $CONTAINER_NAME"
echo "   📜 Логи:         $CONTAINER_ENGINE logs -f $CONTAINER_NAME"
echo "   🔄 Перезапуск:   $CONTAINER_ENGINE restart $CONTAINER_NAME"
echo ""

echo "📢 Запускаю просмотр логов контейнера (для выхода: Ctrl+C)..."
echo ""

# Просмотр логов
$CONTAINER_ENGINE logs -f $CONTAINER_NAME