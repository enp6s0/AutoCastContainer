#!/bin/bash
#
# AutoCast container launch script
#
# =================================================================================================
version=$(cat /CONTAINER_VERSION)
build=$(cat /CONTAINER_BUILD)
echo ""
echo "$version [CONTAINER]"
echo ""
echo "Build: $build"
echo ""

# =================================================================================================
# Preflight checks
# =================================================================================================

# Make sure NVIDIA-SMI works
nvidia-smi > /tmp/launch-nvidia-smi
if [ $? -ne 0 ];
then
    echo "Container error (2): NVIDIA GPU within the container not working properly. Confirm GPU is available and nvidia-container-toolkit is working?"
    exit 2
fi

# =================================================================================================
# Run supervisor in the foreground to keep the container up "forever"
# =================================================================================================
supervisord -n -c /etc/supervisord.conf
