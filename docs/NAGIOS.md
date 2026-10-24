# Nagios in the Food For All project

`dc` below means `docker compose -f docker-compose.yml -f docker-compose.devops.yml`.

## What Nagios does here

Nagios checks every part of the project once a minute and shows the result on a web dashboard: green for OK, red for a problem.

Open http://localhost:8081/nagios and log in as `nagiosadmin` with the password from `.env`.

| Host | What is checked |
| --- | --- |
| web1, web2 | `/health` answers OK |
| lb | the site works through the load balancer |
| client | the frontend answers on `/healthz` |
| server | the API answers on `/api/health` |
| mongo | port 27017 is open |
| puppet | port 8140 is open |

## How it is built

`nagios/Dockerfile` installs Nagios Core and its plugins on Ubuntu and sets up Apache for the web dashboard. Our own config lives in `nagios/etc/objects/foodforall/`:

```
hosts.cfg      the servers to watch
services.cfg   what to check on each server
commands.cfg   the check commands (HTTP and TCP)
templates.cfg  shared settings: check every minute
```

## Try it

```bash
dc stop web2      # within a few minutes web2 turns red in the dashboard
dc start web2     # and goes back to green
```
