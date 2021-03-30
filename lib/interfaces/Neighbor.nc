interface Neighbor {
    //DD: Events that can be called through Neighbor interface
    command void initTimer();

    command void beginNeighborDiscovery();

    command void printNeighbors();

    command List<uint16_t> getNeighbors();
}