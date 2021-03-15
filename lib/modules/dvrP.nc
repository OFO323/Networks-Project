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



    uses interface Receive;
    uses interface SimpleSend as dvrSend;

    uses interface Timer<TMilli> as dvrTimer;
    uses interface Random;

    uses interface List<uint16_t> as neighborList;

    uses interface Hashmap<uint16_t> as distVect;
    
    uses interface Hashmap<Route*> as routeTable;

    uses interface Neighbor; //used to pull DV info from closest neighbors


}

implementation {
    Route newRoute;

    uint32_t i, j;

    //get immediate neighbors [might need to move into functions if causing errors]
    neighborList = call Neighbor.getNeighbors();


    void makeRoute(Route *route, uint16_t dest, uint16_t nextHop, uint16_t cost, uint16_t TTL);

    //should start randomly and send out information periodically
    command void dvr.initalizeNodes(){
        call dvr.initalizeDV();
        call dvr.intializeRT();


        //RH:should timer start randomly or in sync?


        //call dvrTimer.startPeriodicAt(t, del);

    }

    command void dvr.initalizeDV(){
        call distVect.insert(TOS_NODE_ID, 0); //node only knows distance to itself initially + neighbors
        //RH:should we iterate thru immediate neighbors at this point or is that later?

        //add immediate neighbor distances to DV
        for(i = 0; i < call neighborList.size(); i++){
            call distVect.insert(i, 1);
        } 
    }

    command void dvr.initalizeRT(){
        //add self to RT
        makeRoute(&newRoute, TOS_NODE_ID, TOS_NODE_ID, 0, MAX_TTL);
        routeTable.insert(TOS_NODE_ID, newRoute);

        //add neighbors to inital RT
        for(j = 0; call neighborList.size(); i++){
            makeRoute(&newRoute, call neighborList.get(i), call neighborList.get(i), 1, MAX_TTL);
            routeTable.insert(call neighborList.get(i), newRoute);
        }
    }


    event void dvrTimer.fired(){
        //call dvr.sendRoutes 
        //call dvr.mergeRoutes
        //call dvr.updateRoutingTable
    }



    //changed to new RT struct to be sent to neighbors
    void makeRoute(Route *route, uint16_t dest, uint16_t nextHop, uint16_t cost, uint16_t TTL){
      Route->dest = dest;
      Route->nextHop = nextHop;
      Route->cost = cost;
      Route->TTL = TTL;
      memcpy(Route->payload, payload, length);
   }
}