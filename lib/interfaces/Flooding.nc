interface Flooding {
    //Events that can be called through Flooding Interface
    command void beginFlood(uint16_t destination, uint8_t *payload, uint16_t num);
}