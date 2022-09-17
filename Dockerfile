#
# AutoCast docker image
# Note: this is a WIP and is not ready yet!
#
# CUDA 11.0, Ubuntu 22.04 base image with nvidia-container-toolkit support
#
#FROM docker.io/nvidia/cuda:11.0.3-cudnn8-devel-ubuntu20.04
FROM docker.io/nvidia/cuda:11.1.1-cudnn8-devel-ubuntu20.04

# Cache buster for apt updates (just in case!)
ENV AUTOCAST_DOCKER_CACHE_BUSTER_V=1
RUN apt update

# Environment variables
ENV LANG en_US.UTF-8
ENV PYTHONIOENCODING=utf-8
ENV DEBIAN_FRONTEND=noninteractive

# Env vars for nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute
ENV QT_X11_NO_MITSHM 1

# Make sure both the CUDA compiler and NVIDIA-SMI runs
# Note: if this fails, see:
#       https://stackoverflow.com/questions/59691207/docker-build-with-nvidia-runtime
RUN nvcc --version
RUN nvidia-smi

# Configure timezone so tzdata won't hang forever
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install base apt packages
RUN apt install -y mosquitto python3 python3-pip python3-dev python3-opencv python-is-python3 build-essential software-properties-common bash git zip unzip curl gnupg2 lsb-release wget mosquitto-clients can-utils libopenblas-dev curl nano vim iputils-ping net-tools traceroute tcpdump gcc g++ supervisor --no-install-recommends

# Additional apt packages
RUN apt install -y sudo xdg-user-dirs libsdl2-2.0-0 xserver-xorg libvulkan1 --no-install-recommends

# Update pip
RUN pip3 install --upgrade pip

# Base Python packages
RUN pip3 install numpy pygame pillow scipy paho-mqtt python-can pyserial ninja open3d

# CARLA 0.9.11
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1AF1527DE64CB8D9
RUN add-apt-repository "deb [arch=amd64] http://dist.carla.org/carla $(lsb_release -sc) main"
RUN apt install -y carla-simulator=0.9.11 --no-install-recommends

# PyTorch 1.7.1 for CUDA 11.0
RUN pip3 install torch==1.7.1+cu110 torchvision==0.8.2+cu110 torchaudio==0.7.2 -f https://download.pytorch.org/whl/torch_stable.html

# PyTorch Geometrics
RUN pip3 install torch-scatter==2.0.7 torch-sparse==0.6.9 -f https://data.pyg.org/whl/torch-1.7.1+cu101.html

# Minkowski Engine
# (if something's going to fail, it's likely this step...)
RUN pip3 install MinkowskiEngine --install-option="--blas=openblas" -v --no-deps

# ======================================================================================
# Try not to edit anything above this line to avoid MinkowskiEngine compilation pains
# (will gobble all your CPU and may lock up the machine!)
# ======================================================================================

# AutoCast doesn't like default networkx
RUN apt purge -y python3-networkx

# Cache buster for AutoCast, so we can pull the latest code in
ENV AUTOCAST_CACHE_BUSTER_V=1

# Submodule things doesn't work in here (lack of SSH and a signed-in user, so let's do this for now)
RUN git clone https://github.com/hangqiu/AutoCast.git /opt/autocast
RUN git clone https://github.com/hangqiu/autocastsim /opt/autocast/AutoCastSim
RUN bash -c "cd /opt/autocast"
RUN bash -c "cd /opt/autocast && pip3 install -r requirements.txt"
RUN bash -c "cd /opt/autocast/AutoCastSim && pip3 install -r requirements.txt"
RUN chmod +x /opt/autocast/*.sh

# CARLA (well, UE4) will not run as root, so we need an extra user
RUN echo "%sudo ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN useradd -rm -d /opt/autocast -s /bin/bash -g root -G sudo -u 1001 autocast
RUN chmod -R 777 /opt/autocast

# AutoCast environment variables
ENV AC_ROOT=/opt/autocast
ENV SIM_ROOT=/opt/autocast/AutoCastSim
ENV SCENARIO_RUNNER_ROOT=/opt/autocast/AutoCastSim/srunner
RUN bash -c "echo $PYTHONPATH"
ENV PYTHONPATH="${SCENARIO_RUNNER_ROOT}:${SIM_ROOT}"
RUN bash -c "echo $PYTHONPATH"

# Make git ignore permissions globally, so we can push things from within the 
# container without causing problems
RUN git config --global core.filemode false

# Code-server package
RUN wget -O /tmp/codeserver.deb https://github.com/coder/code-server/releases/download/v4.7.0/code-server_4.7.0_amd64.deb
RUN dpkg -i /tmp/codeserver.deb
RUN apt install -y -f
RUN mkdir -p /opt/autocast/.local/share/code-server/User
RUN echo '{"workbench.colorTheme": "Default Dark+"}' > /opt/autocast/.local/share/code-server/User/settings.json
RUN chown -R autocast /opt/autocast/.local
EXPOSE 9001

# ======================================================================================
# Because we're copying in files, ANYTHING below this line WILL be run every time
# the container is built. So try to avoid installing apt packages below here...
# ======================================================================================

# Supervisor configuration
COPY configs/supervisord.conf /etc/supervisord.conf
COPY scripts/launch-container.sh /launch-container.sh
RUN chmod +x /launch-container.sh
RUN chmod 777 /etc/supervisord.conf

# Set render offscreen as not to depend on the host's Xorg server (may result in slightly reduced performance)
ENV DISPLAY=
ENV SDL_VIDEODRIVER=offscreen

# Expose CARLA RPC port
EXPOSE 2001

# Commit ID and container versions
COPY .imagebuild-git-commit /CONTAINER_BUILD
COPY configs/version /CONTAINER_VERSION

# Specify user to run. Note: after this, we will need SUDO to do anything!
USER autocast
WORKDIR /opt/autocast

# All environment variables will need to be set again for this user, it seems
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute
ENV QT_X11_NO_MITSHM 1
ENV DISPLAY=
ENV SDL_VIDEODRIVER=offscreen
ENV AC_ROOT=/opt/autocast
ENV SIM_ROOT=/opt/autocast/AutoCastSim
ENV SCENARIO_RUNNER_ROOT=/opt/autocast/AutoCastSim/srunner
ENV PYTHONPATH="/usr/lib/python3.8/site-packages:${SCENARIO_RUNNER_ROOT}:${SIM_ROOT}"
RUN bash -c "echo $PYTHONPATH"

# Bash will complain about a missing bashrc, so we add one...
COPY scripts/bash.bashrc /opt/autocast/.bashrc

# What to execute?
CMD ["/bin/bash", "/launch-container.sh"]
