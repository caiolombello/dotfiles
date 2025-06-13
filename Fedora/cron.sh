# 1. Atualização automática de segurança e estabilidade (DNF)
0 4 * * * root dnf -y upgrade --refresh >/dev/null 2>&1

# 2. Limpeza de cache de pacotes (evita ocupação desnecessária)
0 5 * * 0 root dnf clean all >/dev/null 2>&1

# 3. Remoção de pacotes órfãos (fstransfer, pacman-*, oudnf autoremove)
0 5 * * 1 root dnf -y autoremove >/dev/null 2>&1

# 4. Atualização de Flatpaks (apps do Flathub)
0 2 * * 3 seu_usuario flatpak update -y >/dev/null 2>&1

# 5. Rotação extra de logs
0 0 * * * root journalctl --vacuum-time=7d >/dev/null 2>&1

# 6. Checagem de integridade de pacotes (opção avançada)
30 3 1 * * root rpm -Va --nofiles --nodigest >/var/log/rpm-verify.log
