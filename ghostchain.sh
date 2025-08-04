#!/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configurações
PROXY_PORT="9050"
TORRC_PATH="$HOME/.torrc"
SERVICE_NAME="ghostchain_proxy"

# Verifica Termux
is_termux() {
    [ -d "/data/data/com.termux/files/usr" ]
}

# Instala dependências
install_deps() {
    echo -e "${YELLOW}[*] Instalando dependências...${NC}"
    if is_termux; then
        pkg update -y && pkg install -y tor proxychains-ng termux-services curl
    else
        echo -e "${RED}[!] Use no Termux para melhor experiência.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[+] Dependências instaladas!${NC}"
}

# Configura Tor persistente
setup_persistent_tor() {
    echo -e "${CYAN}[*] Configurando Tor persistente...${NC}"
    
    # Cria configuração personalizada
    echo "SocksPort $PROXY_PORT" > "$TORRC_PATH"
    echo "ControlPort 9051" >> "$TORRC_PATH"
    echo "RunAsDaemon 1" >> "$TORRC_PATH"
    
    # Configura serviço no Termux
    mkdir -p "$PREFIX/var/service/$SERVICE_NAME"
    echo '#!/bin/sh' > "$PREFIX/var/service/$SERVICE_NAME/run"
    echo "exec tor -f $TORRC_PATH" >> "$PREFIX/var/service/$SERVICE_NAME/run"
    chmod +x "$PREFIX/var/service/$SERVICE_NAME/run"
    
    # Inicia serviço
    sv-enable "$SERVICE_NAME"
    sv up "$SERVICE_NAME"
    
    echo -e "${GREEN}[+] Tor configurado como serviço! (Porta: $PROXY_PORT)${NC}"
}

# Testa anonimato
test_anonymity() {
    echo -e "${CYAN}[*] Testando anonimato...${NC}"
    real_ip=$(curl -s ifconfig.me)
    proxy_ip=$(proxychains -q curl -s ifconfig.me)
    
    echo -e "${YELLOW}[+] IP Real: $real_ip${NC}"
    echo -e "${YELLOW}[+] IP Proxy: $proxy_ip${NC}"
    
    if [ "$real_ip" != "$proxy_ip" ]; then
        echo -e "${GREEN}[✓] Anonimato ativo!${NC}"
    else
        echo -e "${RED}[!] Falha no proxy!${NC}"
    fi
}

# Rotacionar IP
rotate_ip() {
    echo -e "${CYAN}[*] Rotacionando IP...${NC}"
    pkill -HUP tor
    echo -e "${GREEN}[+] Novo circuito Tor criado!${NC}"
}

# Status do serviço
service_status() {
    if sv status "$SERVICE_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}[✓] Serviço ativo${NC}"
    else
        echo -e "${RED}[!] Serviço inativo${NC}"
    fi
}

# Atualizar ferramenta
update_tool() {
    echo -e "${YELLOW}[*] Verificando atualizações...${NC}"
    if [ -d ".git" ]; then
        git pull && echo -e "${GREEN}[+] Atualizado!${NC}"
    else
        echo -e "${RED}[!] Não é um repositório Git${NC}"
    fi
}

# Menu
show_menu() {
    clear
    echo -e "${PURPLE}"
    echo "   ____ _    _ ___  _   _ ____ _   _ "
    echo "  / ___| |  |_ _\ \/ /_ _/ ___| \ | |"
    echo " | |  _| |  | | \  / | | |   |  \| |"
    echo " | |_| | |__| | /  \ | | |___| |\  |"
    echo "  \____|_____|___/_/\_\___\____|_| \_|"
    echo -e "${NC}"
    echo -e "${BLUE}       PROXY ANÔNIMO PERSISTENTE${NC}"
    echo -e "${CYAN}===============================${NC}"
    service_status
    echo -e "${GREEN}[1]${NC} Iniciar Proxy Persistente"
    echo -e "${GREEN}[2]${NC} Testar Anonimato"
    echo -e "${GREEN}[3]${NC} Rotacionar IP"
    echo -e "${GREEN}[4]${NC} Status do Serviço"
    echo -e "${GREEN}[5]${NC} Atualizar GhostChain"
    echo -e "${GREEN}[0]${NC} Sair"
    echo -e "${CYAN}===============================${NC}"
}

# Main
if ! is_termux; then
    echo -e "${RED}[!] Execute no Termux para recursos completos.${NC}"
    exit 1
fi

install_deps
while true; do
    show_menu
    read -p "Opção: " opt
    
    case $opt in
        1) setup_persistent_tor ;;
        2) test_anonymity ;;
        3) rotate_ip ;;
        4) service_status ;;
        5) update_tool ;;
        0) echo -e "${RED}[*] Saindo...${NC}"; exit 0 ;;
        *) echo -e "${RED}[!] Opção inválida${NC}"; sleep 1 ;;
    esac
    
    echo -e "\n${YELLOW}Pressione ENTER...${NC}"
    read -n 1 -s
done