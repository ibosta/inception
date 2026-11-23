COMPOSE	= docker compose -f srcs/docker-compose.yml
DATA	= /home/itaskira/data

SECRETS	= secrets/db_root_password.txt secrets/db_password.txt \
	  secrets/wp_admin_password.txt secrets/wp_user_password.txt

all: check
	mkdir -p $(DATA)/mariadb $(DATA)/wordpress
	$(COMPOSE) up -d --build

check:
	@test -f srcs/.env || { echo "srcs/.env missing: cp srcs/.env.example srcs/.env"; exit 1; }
	@for f in $(SECRETS); do test -s $$f || { echo "$$f missing or empty (see DEV_DOC.md)"; exit 1; }; done

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down --rmi all

fclean:
	$(COMPOSE) down --rmi all -v
	sudo rm -rf $(DATA)

re: fclean all

.PHONY: all check down clean fclean re
