# AutoCast Container

A containerized dev/test environment for [AutoCast](https://github.com/hangqiu/autocast)

### Instant images (just add hot water!)

If you just want to quickly run the image, there's a public pre-built release available [here](https://quay.io/repository/adrlab/autocast). To pull, simply run:

```
docker pull quay.io/adrlab/autocast:latest
```

### Build prerequisites

* Docker Engine. This is tested on `Docker version 20.10.17, build 100c701`
* [NVIDIA container runtime](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
* A NVIDIA GPU

### How to build?
Make sure you have Docker and the NVIDIA container runtime installed. Note that you'll also need to set Docker's default runtime to `nvidia` for the build to work (the build *requires* an active GPU).

Your `/etc/docker/daemon.json` should look somewhat like this:

```
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
         } 
    },
    "default-runtime": "nvidia" 
}
```

(Make sure to restart the Docker daemon after modifying the config so that it takes effect!)

After that, simply run `docker build .` from the root directory of this repository, and if all goes well, ~30 minutes later you'll get your very own AutoCast container image.
