Reading Room Wayback Service Stack
==================================

This [Docker Swarm Stack](https://docs.docker.com/engine/swarm/stack-deploy/) deploys the set of services required to provide reading-room and staff access to Non-Print Legal Deposit material.

This replaces the remote-desktop-based access system, using [UK Web Archive Python Wayback](https://github.com/ukwa/ukwa-pywb) (PyWB) to provide access to content directly to secure browsers in reading rooms. Our PyWB system also implements the Single-Concurrent Usage (SCU) locks, and provides a way for staff to manage those locks if needed.

To Do
-----

- [ ] Confirm required network location. Do we need to be on the Access VLAN?
- [ ] Ensure staff access can be separated out. May require separate IP address.
- [ ] Understand various redundancies/back services needed.
- [ ] @anjackson Port table, expected setup (hostname -> IP)
- [ ] @anjackson Tests using Robot Framework, sitting on the `access_rrwb_default` network.
- [ ] @anjackson Expose multi-cluster WARC Server as `warc-server.api.wa.bl.uk`

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

Each service supports two host names, the real `.ldls.org.uk` name and a `.beta.ldls.org.uk` version that could be used if it is necessary to test this system in parallel with the original system.

_TODO_ Add port map here:


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
    - The public web, if only temporarily, to download the Docker images during installation/deployment.
    - The DLS back-end systems where ARK-based resources can be downloaded (e.g. `access.dl.bl.uk`, `staffaccess.dl.bl.uk`).
    - The UKWA back-end systems where URL lookups and WARC record retrieval can be done (`cdx.api.wa.bl.uk`, `webhdfs.api.wa.bl.uk`, likely accessed from Access VLAN via web archive proxy).
- The set of files in this folder.

It is envisages that the same stack will be deployed in BSP and STP, and connected up using the existing failover mechanism(s).

Operations
----------

### Deployment

...

note  ops like `docker service update --force access_rrwb_nginx` required to get NGINX to reload configuration.

### Updating the Block List

...

### Updating The Stack

...

