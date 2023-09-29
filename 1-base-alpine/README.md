A fork of: https://github.com/linuxserver/docker-baseimage-alpine

Image size: 19,4 MB

Added: repository: edge(main, community and testing)

Weekly builds @Saturday at 3:00 (AM)

	-rebuilds new base image from scratch @http://nl.alpinelinux.org/alpine (Alpine 3.12)
	-Base OS is updated
	-Packages are updated
	-Application within image(container) gets updated if new release is available. (Don't manual update Application within container.)

To update your container:

Via Docker Run/Create

    -Update the image: docker pull thies88/containername
    -Stop the running container: docker stop containername
    -Delete the container: docker rm containername
    -Recreate a new container with the same docker create parameters used at the setup of the container (if mapped correctly to a host folder, your /config folder and settings will be preserved)
    -Start the new container: docker start containername
    -You can also remove the old dangling images: docker image prune

Unraid users can use "Check for updates" within Unraid WebGui

&nbsp;

A custom base image built with [Alpine linux][https://alpinelinux.org/] and [S6 overlay](https://github.com/just-containers/s6-overlay) Based on: https://github.com/linuxserver/docker-baseimage-alpine
