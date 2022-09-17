# AutoCast container bashrc

# Show version
AUTOCAST_CONTAINER_BUILD=$(cat /CONTAINER_BUILD)
AUTOCAST_CONTAINER_VERSION=$(cat /CONTAINER_VERSION)
AUTOCAST_CONTAINER_IP=$(hostname -I)
echo ""
printf "Container:\t$AUTOCAST_CONTAINER_VERSION\n"
printf "Build:\t\t$AUTOCAST_CONTAINER_BUILD\n"
printf "My IP address:\t$AUTOCAST_CONTAINER_IP\n"
echo ""