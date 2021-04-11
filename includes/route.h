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
    ROUTE_SIZE = 6,
    MAX_COST_ROUTE = 20
};

typedef nx_struct RouteMsg{
    nx_uint16_t dest;
    nx_uint16_t nextHop;
    nx_uint16_t cost;
    nx_uint16_t TTL;
} RouteMsg; //

enum {
    AM_ROUTE_PACK = 11 //might need this to differentiate route packets w/ other types for checks 
};

//uint16_t numRoutes = 0; //used to show how many routes per node[needed for forloop search/comparison]
//RouteMsg routeTable[MAX_ROUTES]; // should this be a *pointer? we'll find out!

#endif
