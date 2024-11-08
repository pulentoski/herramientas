#!/bin/bash

# Definir colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}========== Resumen de Enumeración ==========${RESET}"
echo

# Filtrar usuarios relevantes
echo -e "${GREEN}========== Usuarios Importantes ==========${RESET}"
echo -e "${BLUE}Usuarios en el sistema (filtrados):${RESET}"
awk -F: '($3 >= 1000) { print $1 }' /etc/passwd

echo
echo -e "${GREEN}========== Comprobando permisos sudo ==========${RESET}"
# Verificar si el usuario tiene permisos sudo
if sudo -l &>/dev/null; then
    echo -e "${BLUE}Usuarios con permisos sudo sin contraseña:${RESET}"
    sudo -l 2>/dev/null | grep -i "NOPASSWD" | awk '{print $1}' | sort -u || echo -e "${RED}No se encontraron usuarios con permisos sudo sin contraseña.${RESET}"

    echo
    echo -e "${BLUE}========== Comandos Sudo sin Contraseña ==========${RESET}"
    # Listar comandos sudo que pueden ejecutarse sin contraseña
    echo -e "${YELLOW}Usuarios y comandos permitidos sin contraseña:${RESET}"
    sudo -l 2>/dev/null | grep -i "NOPASSWD" | awk -F 'NOPASSWD:' '{ print "Usuario: " $1 ", Comando: " $2 }' | sort -u || echo -e "${RED}No se encontraron comandos sudo sin contraseña.${RESET}"
else
    echo -e "${RED}El usuario no tiene permisos para ejecutar 'sudo -l'.${RESET}"
fi

echo
echo -e "${GREEN}========== Archivos SUID/SGID ==========${RESET}"
# Buscar archivos con permisos SUID y SGID
echo -e "${YELLOW}Archivos con permisos SUID relevantes:${RESET}"
find / -perm -4000 -type f \( -name "passwd" -o -name "sudo" -o -name "su" -o -name "chsh" -o -name "mount" -o -name "umount" -o -name "ssh-keysign" -o -name "newgrp" \) 2>/dev/null

echo
echo -e "${YELLOW}Archivos con permisos SGID relevantes:${RESET}"
find / -perm -2000 -type f \( -name "chage" -o -name "expiry" -o -name "ssh-agent" \) 2>/dev/null

echo
echo -e "${GREEN}========== Conexiones de Red ==========${RESET}"
# Puertos abiertos y servicios en escucha
echo -e "${BLUE}Puertos abiertos y servicios en escucha:${RESET}"
netstat -tuln 2>/dev/null | awk '{ if ($6 == "LISTEN") print $0 }' || ss -tuln 2>/dev/null | awk '{ if ($1 == "LISTEN") print $0 }' || echo -e "${RED}No se encontraron puertos abiertos.${RESET}"

echo
echo -e "${BLUE}Conexiones activas:${RESET}"
netstat -anp 2>/dev/null || ss -anp 2>/dev/null || echo -e "${RED}No se encontraron conexiones activas.${RESET}"

echo
echo -e "${GREEN}========== Enumeración de Procesos ==========${RESET}"
# Enumerar los procesos en ejecución
echo -e "${YELLOW}Procesos relevantes en ejecución:${RESET}"
ps aux | grep -E 'apache2|sshd|php|sleep|grep' | sort

echo
echo -e "${CYAN}========== Fin del Resumen ==========${RESET}"
