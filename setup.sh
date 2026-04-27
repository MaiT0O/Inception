#!/bin/bash

set -e

# Couleurs pour l'output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Inception Setup ===${NC}\n"

# Créer le dossier secrets s'il n'existe pas
if [ ! -d "secrets" ]; then
    echo -e "${YELLOW}Creating secrets directory...${NC}"
    mkdir -p secrets
fi

# Générer db_password.txt s'il n'existe pas
if [ ! -f "secrets/db_password.txt" ]; then
    echo -e "${YELLOW}Generating db_password.txt...${NC}"
    openssl rand -base64 32 > secrets/db_password.txt
    chmod 600 secrets/db_password.txt
    echo -e "${GREEN}✓ db_password.txt created${NC}"
else
    echo -e "${GREEN}✓ db_password.txt already exists${NC}"
fi

# Générer db_root_password.txt s'il n'existe pas
if [ ! -f "secrets/db_root_password.txt" ]; then
    echo -e "${YELLOW}Generating db_root_password.txt...${NC}"
    openssl rand -base64 32 > secrets/db_root_password.txt
    chmod 600 secrets/db_root_password.txt
    echo -e "${GREEN}✓ db_root_password.txt created${NC}"
else
    echo -e "${GREEN}✓ db_root_password.txt already exists${NC}"
fi

# Générer credentials.txt s'il n'existe pas
if [ ! -f "secrets/credentials.txt" ]; then
    echo -e "${YELLOW}Generating credentials.txt...${NC}"
    cat > secrets/credentials.txt <<EOF
WP_ADMIN_PASSWORD=$(openssl rand -base64 12)
WP_USER_PASSWORD=$(openssl rand -base64 12)
EOF
    chmod 600 secrets/credentials.txt
    echo -e "${GREEN}✓ credentials.txt created${NC}"
else
    echo -e "${GREEN}✓ credentials.txt already exists${NC}"
fi

# Générer .env.example s'il n'existe pas
if [ ! -f "srcs/.env" ]; then
    echo -e "${YELLOW}Creating .env with .env.example${NC}"
    cp srcs/.env.example srcs/.env
    echo -e "${GREEN}✓ .env created${NC}"
fi

echo -e "\n${GREEN}=== Setup Complete ===${NC}\n"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review and customize srcs/.env if needed"
echo "2. Run: docker-compose -f srcs/docker-compose.yml up -d"
echo ""
