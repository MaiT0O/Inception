# Makefile (à la racine du projet)

LOGIN    = ebansse
DATA_DIR = /home/$(LOGIN)/data

all: setup up

# Créer les dossiers de données sur l'hôte avant de lancer
setup:
	mkdir -p $(DATA_DIR)/wordpress
	mkdir -p $(DATA_DIR)/mariadb

up: setup
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

stop:
	docker compose -f srcs/docker-compose.yml stop

clean: down
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	rm -rf $(DATA_DIR)/wordpress/* $(DATA_DIR)/mariadb/*

fclean: clean
	docker system prune -af

re: fclean all

.PHONY: all setup up down stop clean fclean re