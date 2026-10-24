# Shortcuts for the Food For All stack. Run `make help` to list them.
# (On Windows without make, copy the command after each target.)

APP    = docker compose -f docker-compose.yml
DEVOPS = docker compose -f docker-compose.yml -f docker-compose.devops.yml

.PHONY: help up down devops devops-down status logs clean

help:            ## list targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-15s %s\n", $$1, $$2}'

up:              ## app only: mongo + server + client  (http://localhost:3000)
	$(APP) up -d --build

down:            ## stop the app
	$(APP) down

devops:          ## app + Puppet + web servers + load balancer + Nagios
	$(DEVOPS) up -d --build

devops-down:     ## stop everything (data is kept)
	$(DEVOPS) down

status:          ## list containers
	$(DEVOPS) ps

logs:            ## follow logs of every container
	$(DEVOPS) logs -f

clean:           ## stop everything AND delete volumes (database, certificates)
	$(DEVOPS) down -v
