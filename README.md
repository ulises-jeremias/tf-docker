# TF Docker

## Quickstart

```sh
$ ./bin/start [-n <name>] [-t <tag>]
```

## Setup and use docker

Build the docker image,

```sh
$ docker build --rm -f docker/<tag>.Dockerfile -t <name>:latest .
```

and now run the image

```sh
$ docker run --rm -u $(id -u):$(id -g) -p 6006:6006 -p 8888:8888 <name>:latest
```

Visit that link, hey look your jupyter notebooks are ready to be created.

If you want, you can attach a shell to the running container

```sh
$ docker exec -it <container-id> /bin/sh -c "[ -e /bin/bash ] && /bin/bash || /bin/sh"
```

And then you can find the entire source code in `/develop`.

```sh
$ cd /develop
```

Test the environment as follow,

```sh
$ python starterfile.py
```
