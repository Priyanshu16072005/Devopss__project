# site.pp - the main manifest. Each agent gets the classes listed for its name.

# Web servers: web1 has a green page, web2 a blue one,
# so you can see the load balancer switching between them.
node 'web1.foodforall.local' {
  include foodforall
  class { 'webserver': site_color => '#2e7d32' }
}

node 'web2.foodforall.local' {
  include foodforall
  class { 'webserver': site_color => '#1565c0' }
}

# The load balancer in front of the web servers
node 'lb.foodforall.local' {
  include foodforall
  include loadbalancer
}

# Any other node only gets the common setup
node default {
  include foodforall
}
