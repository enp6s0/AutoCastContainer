# AutoCast Container

A containerized dev/test environment for [AutoCast](https://github.com/hangqiu/autocast)

## What does it include?

* Ubuntu 20.04 base image
* `code-server` (on port `9001` by default) for web-based file editing and terminal access
* Everything needed to run AutoCast, in `/opt/autocast`
* GPU-enabled PyTorch and [Minkowski Engine](https://github.com/NVIDIA/MinkowskiEngine)
* [CARLA 0.9.11](https://carla-releases.s3.eu-west-3.amazonaws.com/Linux/CARLA_0.9.11.tar.gz) (note: running CARLA itself in a container can be difficult due to X server issues. For this reason, we recommend running CARLA natively outside of the container)

## Requirements

* Docker Engine
* [NVIDIA container runtime](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) and a compatible NVIDIA GPU. We've tested this on a `GTX 1080Ti` and a `RTX 3070`.


## How to run it?

### Instant images (just add hot water!)

If you just want to quickly run the image, there's a public pre-built release available [here](https://quay.io/repository/adrlab/autocast). To pull, simply run:

```
docker pull quay.io/adrlab/autocast:latest
docker run --gpus=all quay.io/adrlab/autocast:latest
```

### Building the image yourself from scratch

Make sure you have Docker and the NVIDIA container runtime installed. Note that you'll also need to set Docker's default runtime to `nvidia` for the build to work (the build *requires* an active NVIDIA GPU).

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