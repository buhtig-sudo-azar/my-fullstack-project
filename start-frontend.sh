#!/bin/bash

CONTAINER_NAME="my-frontend"
PORT=1234

open_browser() {
  local url=$1
  echo "Попытка открыть браузер с URL: $url"

  if command -v wsl >/dev/null 2>&1 && grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    if command -v wslview >/dev/null 2>&1; then
      echo "Пытаюсь открыть через wslview..."
      if wslview "$url"; then return; fi
    fi
    if command -v powershell.exe >/dev/null 2>&1; then
      echo "Пытаюсь открыть через PowerShell..."
      powershell.exe /c start "$url" && return
    fi
    echo "Пытаюсь открыть через explorer.exe..."
    explorer.exe "$(wslpath -w "$url")" && return

    echo "Не удалось открыть браузер автоматически, откройте вручную: $url"

  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Открываю браузер macOS..."
    open "$url"

  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if ! command -v xdg-open >/dev/null 2>&1; then
      echo "xdg-open не найден, пытаюсь установить xdg-utils (Ubuntu/Debian)..."
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y xdg-utils
        if ! command -v xdg-open >/dev/null 2>&1; then
          echo "Ошибка установки xdg-utils. Откройте браузер вручную: $url"
          return
        fi
      else
        echo "Пакетный менеджер apt-get не найден. Откройте браузер вручную: $url"
        return
      fi
    fi
    echo "Открываю браузер Linux..."
    xdg-open "$url"

  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "Открываю браузер Windows (gitbash/cygwin)..."
    cmd.exe /c start "" "$url"

  else
    echo "Неизвестная ОС, откройте ссылку вручную: $url"
  fi
}

echo "=== Список доступных образов Podman ==="
podman images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
echo

echo "=== Текущие контейнеры (запущенные и остановленные) ==="
podman ps -a --format "table {{.Names}}\t{{.Status}}"
echo

read -p "Введите имя контейнера для запуска (по умолчанию \"$CONTAINER_NAME\"): " input_name
if [ -n "$input_name" ]; then
  CONTAINER_NAME=$input_name
fi

if podman ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
  STATUS=$(podman inspect --format '{{.State.Status}}' $CONTAINER_NAME)
  if [ "$STATUS" == "running" ]; then
    echo "Контейнер $CONTAINER_NAME уже запущен."
  else
    echo "Запускаю контейнер $CONTAINER_NAME..."
    podman start $CONTAINER_NAME
  fi
else
  echo "Создаю и запускаю контейнер $CONTAINER_NAME..."
  podman run -d --name $CONTAINER_NAME -p $PORT:$PORT -v $(pwd)/frontend:/app -w /app node:18-alpine sh -c "npm install && npm start"
fi
echo

URL="http://localhost:$PORT"
if command -v wsl >/dev/null 2>&1 && grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
  WIN_IP=$(wsl hostname -I | awk '{print $1}')
  if [[ -z "$WIN_IP" ]]; then
    echo "Не удалось получить IP из WSL, использую localhost."
    WIN_IP="localhost"
  fi
  URL="http://${WIN_IP}:$PORT"
fi

echo "Фронтенд доступен по адресу: $URL"

read -p "Открыть браузер автоматически? (y/n) [n]: " open_resp
open_resp=${open_resp:-n}

if [[ $open_resp =~ ^[Yy]$ ]]; then
  open_browser "$URL"
else
  echo "Открытие браузера пропущено. Откройте ссылку вручную."
fi

echo
echo "Для остановки контейнера:"
echo "  podman stop $CONTAINER_NAME"
echo "Для удаления контейнера:"
echo "  podman rm $CONTAINER_NAME"
echo "Для просмотра логов контейнера:"
echo "  podman logs -f $CONTAINER_NAME"
echo

podman logs -f $CONTAINER_NAME
