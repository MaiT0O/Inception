# Makefile (à la racine du projet)

all: up

up:
	docker-compose -f srcs/docker-compose.yml up -d --build

down:
	docker-compose -f srcs/docker-compose.yml down

stop:
	docker-compose -f srcs/docker-compose.yml stop

clean: down
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true

fclean: clean
	docker system prune -af

re: fclean all

.PHONY: all up down stop clean fclean re