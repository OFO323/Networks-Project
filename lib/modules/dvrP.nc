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
// * create an initalized distance vector for each node [every destination from node except self should be inifinte(i.e. 16 by RIP)]
// * create initalized routing table to be updated after first set of hops
module dvrP{
    provides interface dvr;



    uses interface Receive;
    uses interface SimpleSend as dvrSend;

    uses interface Timer<TMilli> as dvrTimer;
    uses interface Random;

    uses interface List<uint16_t> as neighborList;

    uses interface Hashmap<uint16_t> as distVect;
    uses interface Hashmap<uint16_t> as routeTable;

    uses interface Neighbor; //used to pull DV info from closest neighbors


}

implementation {
    Route sendRoute;

    uint32_t i;

    // need to change this to contain new struct
    void makeRoute(Route *route, uint16_t dest, uint16_t nextHop, uint16_t cost, uint16_t TTL);

    //should start randomly and send out information periodically
    command void dvr.initalizeNodes(){
        //call dvr.initalizeDV();
        //call dvr.intializeRT();


        //RH:should timer start randomly or in sync?


        //call dvrTimer.startPeriodicAt(t, del);

    }

    command void dvr.initalizeDV(){
        call distVect.insert(TOS_NODE_ID, 0); //node only knows distance to itself initially 
        //RH:should we iterate thru immediate neighbors at this point or is that later?

        neighborList = call Neighbor.getNeighbors 
    }

    command void dvr.initalizeRT(){
        call routeTable.insert()
    }


    event void dvrTimer.fired(){
        //call dvr.sendRoutes 
        //call dvr.mergeRoutes
        //call dvr.updateRoutingTable
    }



    //changed to new DV struct to be sent to neighbors
    void makeRoute(Route *route, uint16_t dest, uint16_t nextHop, uint16_t cost, uint16_t TTL){
      Route->dest = dest;
      Route->nextHop = nextHop;
      Route->cost = cost;
      Route->TTL = TTL;
      memcpy(Route->payload, payload, length);
   }
}