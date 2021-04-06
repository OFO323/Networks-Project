interface Neighbor {
    //DD: Events that can be called through Neighbor interface
    command void initTimer();

    command void beginNeighborDiscovery();

    command void printNeighbors();

    command uint8_t* getNeighbors();

    command uint16_t* neighSize();
}