USER		= $(shell whoami)
DATA_DIR	= /home/$(USER)/data

all:	setup up

up:
	docker compose -f srcs/docker-compose.yml up -d --build

setup:
	@bash srcs/requirements/tools/setup.sh

down:
	docker compose -f srcs/docker-compose.yml down

stop:
	docker compose -f srcs/docker-compose.yml stop

clean:	down
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true

fclean: clean
	-docker run --rm --entrypoint sh -v $(DATA_DIR)/mariadb:/data mariadb \
		-c "find /data -mindepth 1 -delete"
	-docker run --rm --entrypoint sh -v $(DATA_DIR)/wordpress:/data wordpress \
		-c "find /data -mindepth 1 -delete"
	rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	docker system prune -af

re:	fclean all

.PHONY: all up down stop clean fclean re