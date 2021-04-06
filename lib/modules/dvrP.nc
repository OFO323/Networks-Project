#include <Timer.h>
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/route.h"


//Peterson 3.3.2 pg 243-252

//PROCESS:
// * nodes initalize their own distance vector [0 for self, inifinity [16] for all other nodes] and then send out to neigbors
// * nodes recieve DVs from neighbors and adds known distance of each neighbor to their sent DV distances 
//      - will simply be +1 to neighbor's DV since we only care about number of hops 
// * all nodes carry out same process and periodically send out DV updates to neighbors 
//      - each node maintains intermediate table to that calculates cost
//      - nodes compare intermediate table w/ and replace RT's current route if cost is lower 


//TODO:
// - create an initalized distance vector for each node [every destination from node except self/immediate neighbors should be inifinte(i.e. 16 by RIP)] [done]
// - create initalized routing table to be updated after first set of hops [done]
//above is done but still need to test 


// * test each node's initial RT and DV
// * decide on when timers should be fired 
// * implement dvr.sendRoutes [pseudcode in textbook]


module dvrP{
    provides interface dvr;


    //uses interface
    uses interface Receive;
    uses interface SimpleSend as dvrSend;

    uses interface Timer<TMilli> as dvrTimer;
    uses interface Random;

    uses interface List<uint16_t> as neighborList;

    uses interface Hashmap<uint8_t> as distVect;
    
    //uses interface Hashmap<RouteMsg*> as routeTable;

    uses interface Neighbor; //used to pull DV info from closest neighbors


}

implementation {
    RouteMsg newRoute;


    uint16_t nSize;
    uint16_t i;
    uint8_t neighID;
    uint8_t *neighbors;
    uint8_t z;
    uint8_t x;
    
    //RouteMsg routeTable[255]; //this is already included in route.h

    uint16_t distV[255];

    void makeRoute(RouteMsg *route, uint16_t dest, uint16_t nextHop, uint16_t cost, uint16_t TTL, uint8_t* payload, uint8_t length);


    //should start randomly and send out information periodically
    command void dvr.initalizeNodes(){

        //both functions below employ neighbor discovery to inititialize the nodes
        call dvr.initalizeDV();
        call dvr.intializeRT();

        //RH:should timer start randomly or in sync?
        //call dvrTimer.startPeriodicAt(t, del);

    }

    command void dvr.initalizeDV(){

        //convertNeighbors();

        call distVect.insert(TOS_NODE_ID, 0); //node only knows distance to itself initially + neighbors

        //call Neighbor.printNeighbors();

        neighbors = call Neighbor.getNeighbors();
        dbg(GENERAL_CHANNEL,"added %d to DV\n", neighbors[0]); //issue : neighbors not recieved

        //add immediate neighbors' distances to DV
        for (i = 0; neighbors[i] != 0; i++) {
            call distVect.insert(neighbors[i], 1);
            dbg(GENERAL_CHANNEL,"added %d to DV\n", neighbors[i]);
            //call neighborList.pushfront(neighbors[i]);
        }

        dbg(GENERAL_CHANNEL, "DV FOR NODE %d is...\n", TOS_NODE_ID);

        //iterate thru each neighbor value extract value of cost
        for(i = 0; i < call distVect.size(); i++){
            dbg(GENERAL_CHANNEL, "Destination %d | Cost %d\n", neighbors[i], call distVect.get(neighbors[i]));
        }
    }

    command void dvr.intializeRT(){

        //initial # of immediate nieghbors
        nSize = (uint16_t)call Neighbor.neighSize(); //issue : nSize not recieved 
        dbg(GENERAL_CHANNEL,"nSize is %d\n", nSize);

        //add self to RT
        makeRoute(&newRoute, TOS_NODE_ID, TOS_NODE_ID, 0, MAX_ROUTE_TTL, "RT msg", PACKET_MAX_PAYLOAD_SIZE);
        //dbg(GENERAL_CHANNEL, "Adding self to RT : %d\n", TOS_NODE_ID);

        //routeTable.insert(TOS_NODE_ID, newRoute*); //err here
        i = 0;
        routeTable[i] = newRoute;

        //add immediate neighbors to inital RT
        for(i = 1; i < nSize; i++){
            dbg(GENERAL_CHANNEL, "iterating thru RT array : %d \n", i);
            neighID = call neighborList.get(i);
            makeRoute(&newRoute, neighID, neighID, 1, MAX_ROUTE_TTL, "RT msg", PACKET_MAX_PAYLOAD_SIZE);
            routeTable[i] = newRoute;
        }
    }

    command void dvr.mergeRoutes(RouteMsg *route){
        for(z = 0; z < numRoutes; ++z){
            if(route->dest == routeTable[z].dest){ //might cause error
                if((route->cost +1) < routeTable[z].cost){
                    //found better route
                    dbg(GENERAL_CHANNEL, "found better route\n");
                    break; 
                }else if(route->nextHop == routeTable[z].nextHop) {
                    //metric for current next hop may have changed
                    dbg(GENERAL_CHANNEL, "metric for current next hop may have changed\n");
                    break;
                }else{
                    //route not interesting 
                    dbg(GENERAL_CHANNEL, "route not interesting\n");
                    return;
                }
            }
        }

        if(z == numRoutes){
            /* this is a completely new route; is there room for it? */
            if(numRoutes < MAX_ROUTES){
                ++numRoutes;
            } else {
                /* can't fit this route in table so give up */
                dbg(GENERAL_CHANNEL, "cant fit this route in table so give up\n");
                return;
            }
        }

        routeTable[z] = *route;
        routeTable[z].TTL = MAX_ROUTE_TTL;
        //account for hop from current node
        ++routeTable[z].cost;
        
    }
    //calls mergeRoute to incorporate all the routes contained in a routing update
    //that is received from a neighboring node.
    command void dvr.updateRoutingTable(RouteMsg *newR, uint16_t numNewRoutes){
        for(x = 0; x < numNewRoutes; ++x){
            call dvr.mergeRoutes(&newR[x]); //this might cause error [what data structure is this accessing?]
        }
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
        if(len==sizeof(RouteMsg)){
            RouteMsg* myMsg=(RouteMsg*) payload;

            //this is where nodes will update their routes given DV information recieved by neighbors  
            //call dvr.updateRoutingTable(new route, )

        }
    }

    event void dvrTimer.fired(){
        //when timer fires, node periodically sends routes DV to neighbors 
        //call dvr.sendRoutes() 
    }

    //placeholder: may be redundant but can be useful for updating nieghbor array in situations where node connection lost
    void convertNeighbors(){
        neighbors = call Neighbor.getNeighbors();
        for (i = 0; neighbors[i] != 0; i++) {
            call neighborList.pushfront(neighbors[i]);
        }
    }

    //changed to new DVR struct to be sent to neighbors
    void makeRoute(RouteMsg *route, uint16_t dest, uint16_t nextHop, uint16_t cost, uint16_t TTL, uint8_t* payload, uint8_t length){
      route->dest = dest;
      route->nextHop = nextHop;
      route->cost = cost;
      route->TTL = TTL;
      memcpy(route->payload, payload, length);
   }
}