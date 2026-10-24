# Puppet in the Food For All project

`dc` below means `docker compose -f docker-compose.yml -f docker-compose.devops.yml`.

## What Puppet does here

Puppet is a configuration management tool: you describe how a server should look, in code, and Puppet makes it so. In this project Puppet turns three empty Ubuntu containers into a working web cluster:

| Server | What Puppet sets up |
| --- | --- |
| `web1`, `web2` | Nginx, the site config and a `/node/` page (green on web1, blue on web2) |
| `lb` | HAProxy, which shares traffic between web1 and web2 |
| all three | `curl`, `vim-tiny`, a `foodops` user and a login message (`/etc/motd`) |

## How it works

- **Puppet master** (`puppet` container) holds the code in `puppet/code/environments/production/`.
- **Puppet agents** (`web1`, `web2`, `lb`) ask the master for their setup every 60 seconds (pull model) and apply it.
- The first time, each agent gets a certificate from the master. Names ending in `.foodforall.local` are signed automatically (`puppet/server/autosign.conf`).

## The code

```
manifests/site.pp           which server gets which class
modules/foodforall/         common setup for every server
modules/webserver/          Nginx + templates
modules/loadbalancer/       HAProxy + template
```

Templates (`.epp` files) are filled in with facts about each server, such as its hostname and IP address.

## Try it

```bash
dc exec web1 puppet agent --test        # run Puppet now on web1
dc exec puppet puppetserver ca list --all   # signed certificates

# Puppet fixes manual changes:
dc exec web1 sh -c 'echo hacked > /etc/motd'
dc exec web1 puppet agent --test        # /etc/motd is restored
```
