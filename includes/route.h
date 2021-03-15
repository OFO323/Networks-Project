#ifndef ROUTE_H
#define ROUTE_H

// Rodolfo Higuera
//struct for each route in each node's distance vector shared
//with neighbors 
//to extract information, nodes will have to interate through a list of routes
// for comparison with its own RT table values 

enum {
    MAX_ROUTES = 128;
    MAX_TTL = 120;
}

typedef nx_struct Route{
    nx_uint16_t dest;
    nx_uint16_t nextHop;
    nx_uint16_t cost;
    nx_uint16_t TTL;
    nx_uint8_t payload[20]; //may need to change payload size if causes issues

}Route;

uint16_t numRoutes = 0; //used to show how many routes per node[needed for forloop search/comparison]
Route routeTable[MAX_ROUTES]; // should this be a *pointer? we'll find out!

#endif