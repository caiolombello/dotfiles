#!/usr/bin/env bash
set -euo pipefail

# 1) Detectar gerenciador de pacotes
if   command -v apt    &>/dev/null; then PM="apt"    ; INSTALL="sudo apt update && sudo apt install -y"
elif command -v dnf    &>/dev/null; then PM="dnf"    ; INSTALL="sudo dnf install -y"
elif command -v pacman &>/dev/null; then PM="pacman" ; INSTALL="sudo pacman -Sy --noconfirm"
else echo "ERRO: gerenciador de pacotes não suportado."; exit 1; fi

echo "[+] Distro detectada: $PM"

# 2) Instalar ferramentas necessárias
case "$PM" in
  apt)    $INSTALL zram-tools earlyoom ksm-tools ;;
  dnf)    $INSTALL systemd-zram-generator earlyoom ksm-tools ;;
  pacman) $INSTALL zramd earlyoom ksm ;;
esac

# 3) Configurar zram (75% da RAM como swap comprimido)
cat <<EOF | sudo tee /etc/systemd/zram-generator.conf >/dev/null
[zram0]
zram-size = ram * 0.75
compression-algorithm = zstd
swap-priority = 100
EOF
echo "[+] Configuração zram aplicada"

sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service || true

# 4) Habilitar zswap (compressão + fallback SSD)
cat <<EOF | sudo tee /etc/modprobe.d/zswap.conf >/dev/null
options zswap enabled=1 max_pool_percent=20 compressor=lz4
EOF
echo "[+] zswap ativado (check /sys/module/zswap/parameters/enabled)"
sudo update-initramfs -u 2>/dev/null || sudo dracut --force >/dev/null

# 5) Ativar KSM (Kernel Samepage Merging)
sudo modprobe ksm
cat <<EOF | sudo tee /etc/systemd/system/ksm.service >/dev/null
[Unit]
Description=Kernel Samepage Merging
After=network.target

[Service]
ExecStart=/usr/bin/ksm
Type=simple

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now ksm.service
echo "[+] KSM habilitado"

# 6) Limitar consumo de journald
sudo sed -i '/^#SystemMaxUse=/c\SystemMaxUse=50M' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
echo "[+] journald limitado a 50M"

# 7) Habilitar EarlyOOM para prevenção de OOM crítico
sudo $INSTALL earlyoom
sudo systemctl enable --now earlyoom
echo "[+] EarlyOOM ativo"

# 8) Ajustes de sysctl (swappiness, cache pressure, I/O sujo, reserva livre)
cat <<EOF | sudo tee /etc/sysctl.d/99-memory-opt.conf >/dev/null
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.min_free_kbytes = 65536
EOF
sudo sysctl --system
echo "[+] sysctl tuning aplicado"

# 9) Montar tmpfs em /tmp e /var/log
if ! grep -q "^tmpfs /tmp" /etc/fstab; then
  echo "tmpfs /tmp tmpfs defaults,noatime,mode=1777,size=50% 0 0" | sudo tee -a /etc/fstab
  sudo mount -o remount /tmp
fi
if ! grep -q "^tmpfs /var/log" /etc/fstab; then
  echo "tmpfs /var/log tmpfs defaults,noatime,mode=0755,size=200M 0 0" | sudo tee -a /etc/fstab
  sudo mount /var/log
fi
echo "[+] /tmp e /var/log em tmpfs"

# 10) Drop caches imediato (efeito único)
echo 3 | sudo tee /proc/sys/vm/drop_caches
echo "[+] Caches de página limpos"

echo "[+] Otimização completa de memória aplicada."
echo "    • Confira: swapon --show ; free -h ; cat /sys/module/zswap/parameters/enabled"
