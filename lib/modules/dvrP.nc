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
// * change the pkt structure to carry new DV info: dest, nextHop, cost, TTL
// * 


module dvrP{
    provides interface dvr;


    //uses interface
    uses interface Receive;
    uses interface SimpleSend as dvrSend;

    uses interface Timer<TMilli> as dvrTimer;
    uses interface Timer<TMilli> as dvrTimer2;

    uses interface Random;

    uses interface List<uint16_t> as neighborList;
    uses interface List<RouteMsg> as r_List;

    uses interface Hashmap<uint8_t> as distVect;
    
    //uses interface Hashmap<RouteMsg*> as routeTable;

    uses interface Neighbor; //used to pull DV info from closest neighbors


}

implementation {
    pack newRoute;

    //temp var to hold initial/pkt values for nodes
    RouteMsg nR; 

    //RouteMsg routeTable[MAX_ROUTES]; //migth get rid

    uint16_t numRoutes; //used to show how many routes per node[needed for forloop search/comparison]
    uint16_t nSize;
    uint16_t i;
    uint8_t neighID;
    uint8_t *neighbors;
    uint8_t z;
    uint8_t x;

    uint32_t t, del; ////used for timer
    
    uint16_t distV[255];

    //should start randomly and send out information periodically
    command void dvr.initalizeNodes(){
        numRoutes = 0;

        //both functions below employ neighbor discovery to inititialize the nodes
        call dvrTimer2.startOneShot(90000); //initialize nodes

        //call dvrTimer.startOneShot(call Random.rand32() % 2000);
        // t = 90001;
        // del = 20000 + (call Random.rand32()) % 10021;
        // call dvrTimer.startPeriodicAt(t, del); //send DV info

        



    }

    command void dvr.initalizeDV(){

        //convertNeighbors();

        call distVect.insert(TOS_NODE_ID, 0); //node only knows distance to itself initially + neighbors

        neighbors = call Neighbor.getNeighbors();
        
        //dbg(GENERAL_CHANNEL,"added %d to DV\n", neighbors[0]); 

        //add immediate neighbors' distances to DV
        for (i = 0; neighbors[i] != 0; i++) {
            call distVect.insert(neighbors[i], 1);
            //dbg(GENERAL_CHANNEL,"added %d to DV\n", neighbors[i]);
            call neighborList.pushfront(neighbors[i]);
        }

        //dbg(GENERAL_CHANNEL, "DV FOR NODE %d is...\n", TOS_NODE_ID);

        //iterate thru each neighbor value extract value of cost
        for(i = 0; i < call distVect.size(); i++){
            //dbg(GENERAL_CHANNEL, "Destination %d | Cost %d\n", neighbors[i], call distVect.get(neighbors[i]));
        }
    }

    command void dvr.intializeRT(){

        //initial # of immediate nieghbors
        nSize = (uint16_t)call Neighbor.neighSize(); 


        i = 0;
        nR.dest = TOS_NODE_ID;
        nR.cost = 0;
        nR.nextHop = TOS_NODE_ID;
        nR.TTL = MAX_ROUTE_TTL;
        routeTable[0] = nR;
        //++numRoutes;

        dbg(GENERAL_CHANNEL, "Table of %d\n:", TOS_NODE_ID);
        //add immediate neighbors to inital RT
        for(i = 1; i < (nSize+1); i++){
            neighID = call neighborList.get(i-1);
            //RouteMsg route;
            //dbg(GENERAL_CHANNEL, "iterating thru RT array : %d \n", i);
            
            //makeRoute(&nR, neighID, neighID, 1);
            nR.dest = neighID;
            nR.nextHop = neighID;
            nR.cost = 1;
            routeTable[i] = nR;
            
            dbg(GENERAL_CHANNEL, "Destination %d | Cost %d | Next Hop %d\n", nR.dest, nR.cost, nR.nextHop);
            
            //++numRoutes;
        }
        dbg(GENERAL_CHANNEL, "numRoutes is %d\n", numRoutes);
        // call dvrTimer.startOneShot(call Random.rand32() % 2000);
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

    command void dvr.sendRoutes(){
        nSize = (uint16_t)call Neighbor.neighSize(); 
        for(i = 0; i < (nSize); i++){
            nR.dest = routeTable[i].dest; 
            nR.nextHop = routeTable[i].nextHop;
            nR.cost = routeTable[i].cost;
            nR.TTL = TOS_NODE_ID; //wanna track this for a bit
            memcpy((&newRoute.payload), &routeTable, sizeof(routeTable));

            dbg(GENERAL_CHANNEL, "packet sent\n");
            
            call dvrSend.send(newRoute, AM_BROADCAST_ADDR); //might chng this to broadcast since next hop might end up being
        }
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
        dbg(GENERAL_CHANNEL, "received packet at node %d\n", TOS_NODE_ID);
        
        if(len==sizeof(pack)){
            pack* myMsg=(pack*) payload;

            dbg(GENERAL_CHANNEL, "testing recieved destination : %d \n", myMsg->TTL);
            
            //this is where nodes will update their routes given DV information recieved by neighbors  
            //call dvr.updateRoutingTable(new route, )

        }
        dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
    }

    event void dvrTimer.fired(){
        dbg(GENERAL_CHANNEL, "timer fired\n");
        call dvr.sendRoutes();
        call dvrTimer.stop();
    }

    event void dvrTimer2.fired(){
        call dvr.initalizeDV();
        call dvr.intializeRT();
    }

    //placeholder: may be redundant but can be useful for updating nieghbor array in situations where node connection lost
    void convertNeighbors(){
        neighbors = call Neighbor.getNeighbors();
        for (i = 0; neighbors[i] != 0; i++) {
            call neighborList.pushfront(neighbors[i]);
        }
    }

}
