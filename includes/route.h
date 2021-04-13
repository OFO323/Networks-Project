#ifndef ROUTE_H
#define ROUTE_H

// Rodolfo Higuera
//struct for each route in each node's RT 
//with neighbors 
//to extract information, nodes will have to interate through a list of routes
// for comparison with its own RT table values 

enum {
    MAX_ROUTES = 128,
    MAX_ROUTE_TTL = 120,
    MAX_COST = 16,      //given by book 
    ROUTE_SIZE = 5,
    //may add more stuff for checks
};

typedef nx_struct RouteMsg{
    nx_uint16_t dest;
    nx_uint16_t cost;
    nx_uint16_t nextHop;
    nx_uint16_t TTL;
    nx_uint16_t chngRoute;
} RouteMsg; //


#endif
