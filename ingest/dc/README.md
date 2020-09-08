Domain Crawl
============

This [Docker Swarm Stack](https://docs.docker.com/engine/reference/commandline/stack/)
definition for our domain crawler, along with basic instructions on how to run it.

Crawl Server Checklist
-----------------------

Before using a service for crawls, we need:

- Docker Swarm installed, using a speedy Docker storage implementation?
- GlusterFS mounted as `/data/` on all Swarm nodes.
- An ethernet connection with access to the world wide web.
- A DNS service that can cope with very heavy usage (we usually use Google DNS servers).
- The `nofiles` limit set to be reasonably high (e.g. 10240 instead of the default 1024).
- Docker Swarm initialised.
- ...???...


Deploying the crawl services
----------------------------

First, set up the following environment variable, which defines the server
hostname that runs the containers that provide the dockerised services. As Docker Swarm is used here, dockerised services can be accessible from other servers, so this identifies the accessible name (as opposed to the hostnames internal to the dockerised services). 
E.g.

    export EXTERNAL_HOSTNAME=crawler04.n45.bl.uk

Then, you should be able to start the stack deployment:

    docker stack deploy -c docker-compose.yml dc

If you run `docker service ls` you should eventually see all services have started up
the requested number of replicas. If any are stuck, you can use:

    `docker service ps <service name> --no-trunc`

and this will list the recent attempts to start the service and any errors,
e.g. if the volume the script attempts to mount is not present.

If this looks good, you can also check some of the services directly with your web browser:

- The [Trifecta](https://github.com/ldaniels528/trifecta) Kafka UI on http://EXTERNAL_HOSTNAME:9000/
- The [OutbackCDX](https://github.com/nla/outbackcdx) service on http://EXTERNAL_HOSTNAME:9090/
- The [Heritrix metrics exporter](https://github.com/ukwa/ukwa-monitor/tree/master/heritrix3_exporter) on http://EXTERNAL_HOSTNAME:9118/metrics
- The [OpenWayback](https://github.com/ukwa/waybacks) service on http://EXTERNAL_HOSTNAME:8080/

You can also use `docker service logs` to inspect the logs of a given service.

TODO Add example, using the `-t` flag to make the output sortable.

### Hooking up Prometheus

Once the monitoring endpoint is up, it should be added to `dev-monitor`

    ssh dev-monitor
    cd github/ukwa-monitor/metrics
    vim prometheus/prometheus.yml

Now add the endpoint to the section that looks like this:

```
   # Crawl Metrics
  - job_name: 'crawl-h3'
    static_configs:
      - targets: ['crawler04.n45.bl.uk:9118']
```

e.g.

```
   # Crawl Metrics
  - job_name: 'crawl-h3'
    static_configs:
      - targets: ['crawler04.n45.bl.uk:9118']
```

(note that because our n45.bl.uk addresses are not in DNS, these aliases have to be added to the `ukwa-monitor` Docker configuration)

Now you can run:

    sh prometheus-reload-cfg.sh

to update the configuration and should see a `HTTP 200` response if the configuration is valid.

If you go to http://dev-monitor.n45.wa.bl.uk:9090/targets the new target
should be listed and should be validated after a short while. From now on
any activity on this crawler should show up in the main dashboard.

Run a test crawl
----------------

The `http://data.webarchive.org.uk/crawl-test-site/` can be used to run
a small crawl through the engine and verify things are working as expected.

You can see the options for the `launch` command, like this:

    docker run ukwa/ukwa-manage launch --help

For example you can run the test crawl by running this command:

    docker run ukwa/ukwa-manage launch -k ${EXTERNAL_HOSTNAME}:9094 uris.tocrawl.dc http://data.webarchive.org.uk/crawl-test-site/

Which means enqueue the crawl test site URL on the `uris.tocrawl.dc` Kafka queue. For the usual frequent crawl we'd have to mark the URL as a seed (using `-S`) so that the scope of the crawl is widened and the page gets rendered, but for the domain crawl the scope is already wide enough and there is no page rendering.

A stream of discovered URLs should show up in Kafka, and the logs and WARCs should start to grow. The page itself should also quickly become visible in the internal Wayback instance (unless the WARCs have been moved off).

Data will end up in `/data/dc/`

Launching the full crawl
------------------------

TODO We also need to revisit the full-domain seeding protocol
TODO Add part of setting up the full surts

Feed in all known hosts. Pre-filter to avoid lots of empty queues in H3? Run through web render separately?

TO ADD

- update crawl name
- constraints

