
## Deployment

Unlike other systems, deployment of GitLab Runner is not done inside Docker.

Following offical repo installation if possible:

https://docs.gitlab.com/runner/install/linux-repository.html

Falling back on direct package installation if necessary.

https://docs.gitlab.com/runner/install/linux-manually.html#using-debrpm-package

The Runner then needs to be registered. To do this, go to the relevant page in GitLab to get the right registration token, and run gitlab-runner and complete the registration.

Here's an example:


```
[root@dev1 gitlab-runner]# gitlab-runner register
Runtime platform                                    arch=amd64 os=linux pid=5287 revision=76984217 version=15.1.0
Running in system-mode.

Enter the GitLab instance URL (for example, https://gitlab.com/):
http://git.wa.bl.uk
Enter the registration token:
XXXXXXXXXXXXXXXXXXXX
Enter a description for the runner:
[dev1]:
Enter tags for the runner (comma-separated):
dev
Enter optional maintenance note for the runner:

Registering runner... succeeded                     runner=7TavUk_M
Enter an executor: docker, docker-ssh, virtualbox, docker-ssh+machine, kubernetes, custom, shell, ssh, docker+machine, parallels:
shell
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

And then

```
# gitlab-runner install --user gitlab-runner
# usermod -aG docker gitlab-runner
# gitlab-runner start
```

This is using the registration token for the [UKWA Group](http://git.wa.bl.uk/groups/ukwa/-/settings/ci_cd#runners-settings).

It uses the hostname to ID the runner, and add the dev tag to identify it as part of the DEV Swarm.

It uses the [shell executor](https://docs.gitlab.com/runner/executors/shell.html), as the idea is to use this to run deployments directly on our machines. That is why the `gitlab-runner` user needs to be in the `docker` group.

The same setup can be used on BETA and PROD Swarms, tagged `beta` and `prod`, and so on.

### DLS Setup

For DLS services, we do the same thing, but associate the runners with the [specific project only](http://git.wa.bl.uk/ukwa/npld-access-deployment/-/settings/ci_cd), and tag the runners as `dls-irc`,`dls-live-sbp` and `dls-live-lon`.  This allows `staging` deployments to target IRC and `production` to run on both `dls-live-lon` and `dls-bsp-lon`.

In this case, the runner should run as `axsadmin`, not `gitlab-runner`.


### Dependency Management

We should also be able to use the [Dependency Proxy](http://git.wa.bl.uk/help/user/packages/dependency_proxy/index) to manage mediated access to the necessary Docker Images. The only issue I've found is that the Docker command itself insists on using HTTPS, so even though it's only internal, we'll need to make GitLab accessible as https://git.wa.bl.uk with a proper certificate etc.
