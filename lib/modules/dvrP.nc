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

    //uses interface List<uint16_t> as neighborList;

    //uses interface Hashmap<uint16_t> as distVect;
    
    //uses interface Hashmap<Route*> as routeTable;

    uses interface Neighbor; //used to pull DV info from closest neighbors


}

implementation {
    RouteMsg newRoute;


    uint16_t i, j, x, z, keys[], neighbor, neighNum;
    uint16_t nSize;
    //get immediate neighbors [might need to move into functions if causing errors]
    neighborList = (call Neighbor.getNeighbors()
    // how to pass the array directly into this list? 
    //1. retrieve the pointer data
    //2. iterate through the array and add onto the neighborList
    );



    //will use arrays instead of list and hashmap [brute force-ish but it'll do]
    RouteMsg routeTable[255]; 
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

    // command void dvr.initalizeDV(){
    //     call distVect.insert(TOS_NODE_ID, 0); //node only knows distance to itself initially + neighbors

    //     //add immediate neighbor distances to DV
    //     for(i = 0; i < nSize; i++){
    //         call distVect.insert(i, 1);
    //     }

    //     dbg(GENERAL_CHANNEL, "DV FOR NODE %d is...", TOS_NODE_ID);


    //     //iterate thru each neighbor value
    //     //extract value of cost
    //     // for(i = 0; i < call distVect.size(); i++){
    //     //     dbg(GENERAL_CHANNEL, "Destination %d | Cost %d", i, );
    //     // }
    // }

    // command void dvr.intializeRT(){
    //     //add self to RT
    //     makeRoute(&newRoute, TOS_NODE_ID, TOS_NODE_ID, 0, MAX_ROUTE_TTL);
    //     routeTable.insert(TOS_NODE_ID, newRoute*); //err here

    //     //add neighbors to inital RT
    //     for(j = 0; i < nSize; i++){
    //         neighNum = call neighborList.get(i);
    //         makeRoute(&newRoute, neighNum, neighNum, 1, MAX_ROUTE_TTL);
    //         routeTable.insert(neighNum, newRoute*);
    //     }
    // }

    // command void dvr.mergeRoutes(RouteMsg *route){
    //     for(z = 0; z < numRoutes; ++z){
    //         if(route->dest == routeTable[z].dest){ //might cause error
    //             if((route->cost +1) < routeTable[z].cost){
    //                 //found better route
    //                 break; 
    //             }else if(route->nextHop == routeTable[z].nextHop) {
    //                 //metric for current next hop may have changed
    //                 break;

    //             }else{
    //                 //route not interesting 
    //                 return;
    //             }
    //         }
    //     }

    //     if(z == numRoutes){
    //         /* this is a completely new route; is there room for it? */
    //         if(numRoutes < MAX_ROUTES){
    //             ++numRoutes;
    //         } else {
    //             /* can't fit this route in table so give up */
    //             return;
    //         }
    //     }

    //     routeTable[z] = *route;
    //     routeTable[z].TTL = MAX_ROUTE_TTL;
    //     ++routeTable[z].cost;
        
    // }

    // command void dvr.updateRoutingTable(Route *newRoute, uint16_t numNewRoutes){
    //     for(x = 0; x < numNewRoutes; ++x){
    //         call dvr.mergeRoutes(&newRoute[x]); //this might cause error [what data structure is this accessing?]
    //     }
    // }


    event void dvrTimer.fired(){
        //call dvr.sendRoutes 
        //call dvr.mergeRoutes
        //call dvr.updateRoutingTable
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