Reading Room Wayback Service Stack
==================================

This [Docker Swarm Stack](https://docs.docker.com/engine/swarm/stack-deploy/) deploys the set of services required to provide reading-room and staff access to Non-Print Legal Deposit material.

This replaces the remote-desktop-based access system, using [UK Web Archive Python Wayback](https://github.com/ukwa/ukwa-pywb) (PyWB) to provide access to content directly to secure browsers in reading rooms. Our PyWB system also implements the Single-Concurrent Usage (SCU) locks, and provides a way for staff to manage those locks if needed.

To Do
-----

- [ ] Confirm required network location. Do we need to be on the Access VLAN?
- [ ] Ensure staff access can be separated out. May require separate IP address.
- [ ] Understand various redundancies/back services needed.
- [ ] Consider training options, e.g. [this](https://www.pluralsight.com/paths/managing-docker-in-production)
- [ ] @anjackson Add in known test cases for manual testing below.
- [ ] @anjackson Set up some tests, using [Robot Framework](https://github.com/ukwa/docker-robot-framework), sitting on the `access_rrwb_default` network.
- [ ] @anjackson Allow access to the multi-cluster WARC Server as `warc-server.api.wa.bl.uk`

Overview
--------

To ensure a smooth transition, this service maintains the same pattern of URLs for accessing content. e.g.

- https://blstaff.ldls.org.uk/welcome.html?ark:/81055/vdc_100090432161.0x000001
- https://bl.ldls.org.uk/welcome.html?10000101000000/http://www.downstairsatthekingshead.com
- http://bodleian.ldls.org.uk/ark:/81055/vdc_100090432161.0x000001

The ARK identifiers are handled by the PyWB `live` collection that proxies the request downstream to DLS, and the `TIMESTAMP/URL` identifiers are passed to a second `archive` collection that plays the archived web pages back using UKWA internal services. NGINX is used to perform these mappings from expected URLs to those supported by PyWB.

For example, if a BL Reading Room patron uses this Access URL to get an URL from the web archive:

- https://blstaff.ldls.org.uk/welcome.html?10000101000000/http://www.downstairsatthekingshead.com

Then the URL will get mapped to this URL:

- https://blstaff.ldls.org.uk/archive/10000101000000/http://www.downstairsatthekingshead.com

Alterlatively, if a BL Staff Access URL used to get an eBook from DLS:

- https://blstaff.ldls.org.uk/welcome.html?ark:/81055/vdc_100090432161.0x000001

Then the content will be served from this URL:

- https://blstaff.ldls.org.uk/live/20010101120000/http://staffaccess.dl.bl.uk/ark:/81055/vdc_100090432161.0x000001

In this case, a fixed timestamp is used for all ARKs and the `http://staffaccess.dl.bl.uk` prefix has been added, as PyWB needs both a timestamp and a URL to get the content and manage the SCU locks. Requests from reading rooms would be directed to `http://access.dl.bl.uk`, e.g. http://access.dl.bl.uk/ark:/81055/vdc_100022588767.0x000002

Therefore, this stack runs the following set of services:

- An NGINX service to provide URL management and mappings.
- Six PyWB services, one for each Legal Deposit Library (BL/NLW/NLS/Bod/CUL/TCDL)
- A Redis service, which stores the SCU locks for each PyWB service.

Note that the included NGINX setup expects that any failover redirection, SSL encrytion, authentication, token validation or user identification has all been handled upstream of this service. Each PyWB service also exposes a dedicated port, allowing upstream NGINX proxies to implement the necessary features rather than relying on the local one, if needed.

Each service supports two host names, the real `.ldls.org.uk` name and a `.beta.ldls.org.uk` version that could be used if it is necessary to test this system in parallel with the original system.  When accessed over the shared port, NGINX uses the `Host` in the request to determine which service is being called.


| Server Name           | Beta Server Name            | Shared NGINX Port | Dedicated NGINX Port | Direct PyWB Port (for debugging) |
|-----------------------|-----------------------------|-------------------|----------------------|----------------------------------|
| bl.ldls.org.uk        | bl.beta.ldls.org.uk         | 8100              | 8200                 | 8300                             |
| nls.ldls.org.uk	    | nls.beta.ldls.org.uk        | 8100              | 8201                 | 8301                             |
| llgc.ldls.org.uk      | llgc.beta.ldls.org.uk       | 8100              | 8202                 | 8302                             |
| cam.ldls.org.uk       | cam.beta.ldls.org.uk        | 8100              | 8203                 | 8303                             |
| bodleian.ldls.org.uk  | bodleian.beta.ldls.org.uk   | 8100              | 8204                 | 8304                             |
| tcdlibrary.ldls.org.uk| tcdlibrary.beta.ldls.org.uk | 8100              | 8205                 | 8305                             |
| blstaff.ldls.org.uk   | blstaff.beta.ldls.org.uk    | 8100              | 8209                 | 8309                             |

Pre-requisites
--------------

In each deployment location:

- One or more Linux servers with Docker installed and running in Swarm mode.
- Network access to:
    - The public web, if only temporarily, install these files and to download the Docker images during installation/deployment.
        - If this is not possible [offline Docker image installation can be used](https://serverfault.com/a/718470).
    - The DLS back-end systems where ARK-based resources can be downloaded (e.g. `access.dl.bl.uk`, `staffaccess.dl.bl.uk`).
    - The UKWA back-end systems: 
        - CDX index for URL lookups (`cdx.api.wa.bl.uk`).
        - WARC record retrieval (`warc-server.api.wa.bl.uk`).
        - GitLab where the URL block list is stored ([`git.wa.bl.uk`](http://git.wa.bl.uk/bl-services/wayback_excludes_update/-/tree/master/ldukwa/acl)).
        - If deployed on the Access VLAN, the existing UKWA service proxy can be used to reach these systems.

It is envisages that the same stack will be deployed in BSP and STP, and connected up using the existing failover mechanism(s).

Operations
----------

### Deploying and Updating the Stack

The Swarm deployment needs access to an host drive location where the list of blocked URLs is stored.  The `deploy-rrwb-dev.sh` script shows an example of how this is done for the UKWA DEV system.  A similar deployment script should be created for each deployment context, setting the `STORAGE_PATH_SHARED` environment variable before deploying the stack:

    docker stack deploy -c docker-compose.yml access_rrwb

Assuming the required Docker images can be downloaded (or have already been installed offline/manually), the services should start up and start to come online.


If the `docker-compose.yml` file is updated, the stack can be redeployed in order to update the Swarm configuration. However, note that most of the specific configuration is in files held on disk, e.g. the NGINX configuration files. If these are changed, the services can be restarted, forcing the configuration to be reloaded, e.g.

    docker service update --force access_rrwb_nginx

### Updating the Block List

The list of URLs that are blocked from access in the Reading Rooms needs to be installed when deploying the service, and will need to be updated periodically (when the web archive team receives take-down requests).

The blocks list is version controlled and held in: http://git.wa.bl.uk/bl-services/wayback_excludes_update/-/tree/master/ldukwa/acl

It needs to be downloaded from there on a regular basis. e.g. a daily cron job like:

    curl -o /shared-folder/blocks.aclj http://git.wa.bl.uk/bl-services/wayback_excludes_update/-/raw/master/ldukwa/acl/blocks.aclj


### Inspecting and Managing SCU locks

_...TBA..._

### Testing

_...TBA..._
