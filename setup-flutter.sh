#!/usr/bin/env bash
set -euo pipefail

ANDROID_API="${ANDROID_API:-34}"
BUILD_TOOLS="${BUILD_TOOLS:-34.0.0}"
EMU_ABI="${EMU_ABI:-x86_64}"
SYSTEM_IMAGE="system-images;android-${ANDROID_API};google_apis;${EMU_ABI}"
AVD_NAME="${AVD_NAME:-Pixel_API_${ANDROID_API}}"
ANDROID_HOME_DEFAULT="${ANDROID_HOME:-$HOME/Android/Sdk}"

msg() { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[!]\033[0m %s\n" "$*"; }

pick_shell_rc() {
  case "${SHELL##*/}" in
    zsh) echo "$HOME/.zshrc" ;;
    *) echo "$HOME/.bashrc" ;;
  esac
}

append_if_missing() {
  local file="$1"
  local line="$2"
  grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

install_yay() {
  if need_cmd yay; then
    return
  fi
  msg "Ставлю yay"
  sudo pacman -S --needed git base-devel
  local tmpdir
  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  pushd "$tmpdir/yay" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf "$tmpdir"
}

if ! need_cmd pacman; then
  echo "Этот скрипт для Arch/CachyOS."
  exit 1
fi

SHELL_RC="$(pick_shell_rc)"
touch "$SHELL_RC"

msg "Ставлю базовые пакеты"
sudo pacman -Syu --needed \
  git unzip curl wget zip tar \
  jdk17-openjdk \
  android-tools \
  qemu-desktop libvirt dnsmasq vde2 openbsd-netcat edk2-ovmf \
  cmake ninja base-devel

install_yay

msg "Ставлю Flutter из AUR"
yay -S --needed --noconfirm flutter

msg "Настраиваю KVM"
sudo modprobe kvm || true
if grep -qi intel /proc/cpuinfo; then sudo modprobe kvm_intel || true; fi
if grep -qi amd /proc/cpuinfo; then sudo modprobe kvm_amd || true; fi
sudo systemctl enable --now libvirtd || true
sudo usermod -aG kvm,libvirt "$USER" || true

msg "Прописываю env в $SHELL_RC"
append_if_missing "$SHELL_RC" 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk'
append_if_missing "$SHELL_RC" "export ANDROID_HOME=$ANDROID_HOME_DEFAULT"
append_if_missing "$SHELL_RC" "export ANDROID_SDK_ROOT=$ANDROID_HOME_DEFAULT"
append_if_missing "$SHELL_RC" 'export PATH=$PATH:$ANDROID_HOME/platform-tools'
append_if_missing "$SHELL_RC" 'export PATH=$PATH:$ANDROID_HOME/emulator'
append_if_missing "$SHELL_RC" 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin'

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export ANDROID_HOME="$ANDROID_HOME_DEFAULT"
export ANDROID_SDK_ROOT="$ANDROID_HOME_DEFAULT"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin"

mkdir -p "$ANDROID_HOME/cmdline-tools"

if ! need_cmd sdkmanager; then
  msg "Качаю Android command-line tools"
  tmpdir="$(mktemp -d)"
  pushd "$tmpdir" >/dev/null
  wget -O cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip -q cmdline-tools.zip
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  mv cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
  popd >/dev/null
  rm -rf "$tmpdir"
fi

msg "Принимаю лицензии"
yes | sdkmanager --licenses >/dev/null || true

msg "Ставлю Android SDK pieces"
sdkmanager \
  "platform-tools" \
  "platforms;android-${ANDROID_API}" \
  "build-tools;${BUILD_TOOLS}" \
  "emulator" \
  "${SYSTEM_IMAGE}"

msg "Настраиваю Flutter"
flutter config --android-sdk "$ANDROID_HOME" || true
flutter precache || true

if need_cmd avdmanager; then
  if ! avdmanager list avd | grep -q "Name: ${AVD_NAME}"; then
    msg "Создаю AVD ${AVD_NAME}"
    echo "no" | avdmanager create avd \
      -n "${AVD_NAME}" \
      -k "${SYSTEM_IMAGE}" \
      -d pixel || true
  fi
fi

msg "Проверяю Flutter"
flutter doctor || true

cat <<EOF

Готово.

1) Перелогинься (важно для групп kvm/libvirt)
   или минимум:
   source "$SHELL_RC"

2) Проверка:
   flutter doctor
   adb devices
   emulator -list-avds

3) Запуск эмулятора на Hyprland лучше так:
   QT_QPA_PLATFORM=xcb emulator -avd ${AVD_NAME}

   Если с графикой беда:
   QT_QPA_PLATFORM=xcb emulator -avd ${AVD_NAME} -gpu swiftshader_indirect

4) Тестовый проект:
   flutter create my_app
   cd my_app
   flutter run

5) Если подключишь телефон:
   adb devices
   flutter run

EOF
