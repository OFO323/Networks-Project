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
// * test each node's initial RT and DV
// * decide on when timers should be fired 
// * implement dvr.sendRoutes [pseudcode in textbook]


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
    RouteMsg nR;
    //RouteMsg routeTable[MAX_ROUTES];

    //void makeRoute(pack *route, uint16_t dest, uint16_t nextHop, uint16_t cost, uint16_t TTL, uint8_t* payload, uint8_t length);
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);


    uint16_t numRoutes; //used to show how many routes per node[needed for forloop search/comparison]
    uint16_t nSize;
    uint16_t i;
    uint8_t neighID;
    uint8_t *neighbors;
    uint8_t z;
    uint8_t x;

    uint32_t t, del; //used for timer
    
    uint16_t distV[255];


    //should start randomly and send out information periodically
    command void dvr.initalizeNodes(){
        numRoutes = 0;
        //both functions below employ neighbor discovery to inititialize the nodes
        // t = (call Random.rand32()) % 2013;
        // del = 5000 + (call Random.rand32()) % 10021;
        // call dvrTimer.startPeriodicAt(t, del); //send DV info

        /*initialize nodes with their initial Routing Table */
        call dvrTimer2.startOneShot(90000); 

    }

    event void dvrTimer2.fired(){
        call dvr.initalizeDV();
        call dvr.intializeRT();

    }

    command void dvr.initalizeDV(){

        //convertNeighbors();

        call distVect.insert(TOS_NODE_ID, 0); //node only knows distance to itself initially + neighbors

        //call Neighbor.printNeighbors();

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

        //add self to RT
        //makeRoute(&nR, TOS_NODE_ID, TOS_NODE_ID, 0);
        //dbg(GENERAL_CHANNEL, "Adding self to RT : %d\n", TOS_NODE_ID);

        
        i = 0;
        nR.dest = TOS_NODE_ID;
        nR.cost = 0;
        nR.nextHop = TOS_NODE_ID;
        nR.TTL = MAX_ROUTE_TTL;
        call r_List.pushfront(nR);
        ++numRoutes;

        //add immediate neighbors to inital RT
        for(i = 1; i < nSize; i++){
            RouteMsg route;
            //dbg(GENERAL_CHANNEL, "iterating thru RT array : %d \n", i);
            //I think we have to add the elements to the route before pushing back, trying this first
            neighID = call neighborList.get(i);
            if (neighID == 0) continue;

            route.dest = neighID;
            route.cost = 1;
            route.nextHop = neighID;
            ++numRoutes;
            
            call r_List.pushback(route);
            
            
            //makePack(&newRoute, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_ROUTE_TTL, PROTOCOL_DV, 1, newRoute.payload, PACKET_MAX_PAYLOAD_SIZE);
            
            // makeRoute(&nR, neighID, neighID, 1);
            // dbg(GENERAL_CHANNEL, "Destination %d | Cost %d | Next Hop %d\n", neighID, call distVect.get(neighbors[i]), neighID);
            // routeTable[i] = nR;
            // ++numRoutes;
        }
        dbg(GENERAL_CHANNEL, "numRoutes is %d\n", numRoutes);
        dbg(GENERAL_CHANNEL, "Table of %d\n", TOS_NODE_ID);
        call dvr.printAll();


    }

    command void dvr.printAll() {
        uint16_t sizeOfTable = call r_List.size();
        uint16_t b;
        

        
        for (b = 0; b < sizeOfTable; b++) {
            RouteMsg route = call r_List.get(b);
            dbg(GENERAL_CHANNEL, "Destination %d | Cost %d | Next Hop %d\n", route.dest, route.cost, route.nextHop);
            memcpy((&newRoute.payload)+b*ROUTE_SIZE, &route, ROUTE_SIZE);
            call dvrSend.send(newRoute, AM_BROADCAST_ADDR);

            
        }
        
    }
    

    //command void dvr.mergeRoutes(RouteMsg *route){
    //     for(z = 0; z < numRoutes; ++z){
    //         if(route->dest == routeTable[z].dest){ //might cause error
    //             if((route->cost +1) < routeTable[z].cost){
    //                 //found better route
    //                 dbg(GENERAL_CHANNEL, "found better route\n");
    //                 break; 
    //             }else if(route->nextHop == routeTable[z].nextHop) {
    //                 //metric for current next hop may have changed
    //                 dbg(GENERAL_CHANNEL, "metric for current next hop may have changed\n");
    //                 break;
    //             }else{
    //                 //route not interesting 
    //                 dbg(GENERAL_CHANNEL, "route not interesting\n");
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
    //             dbg(GENERAL_CHANNEL, "cant fit this route in table so give up\n");
    //             return;
    //         }
    //     }

    //     routeTable[z] = *route;
    //     routeTable[z].TTL = MAX_ROUTE_TTL;
    //     //account for hop from current node
    //     ++routeTable[z].cost;
        
    //}
    //calls mergeRoute to incorporate all the routes contained in a routing update
    //that is received from a neighboring node.
    // command void dvr.updateRoutingTable(RouteMsg *newR, uint16_t numNewRoutes){
    //     for(x = 0; x < numNewRoutes; ++x){
    //         call dvr.mergeRoutes(&newR[x]); //this might cause error [what data structure is this accessing?]
    //     }
    // }


    // command void dvr.send(pack* package) {
    //     RouteMsg testroute;
    //     uint8_t size = call r_List.size();
    //     uint8_t r;

    //     for (r = 0; r < size; r++) {
    //         testroute = call r_List.get(i);
    //         if ((package->dest == testroute.dest)) {
    //             dbg(GENERAL_CHANNEL, "sent package to %d\n", testroute.nextHop);
    //             //call dvrSend.send(*package, testroute.nextHop);
    //         }
    //     }
    // }


    // command void dvr.sendRoutes(){
    //     makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_ROUTE_TTL, PROTOCOL_DV, 1, &nR, PACKET_MAX_PAYLOAD_SIZE);
    //     call dvrSend.send(newRoute, AM_BROADCAST_ADDR);

    //     // for(i = 0; i < numRoutes; i++){


    //     //     nR.dest = routeTable[i].dest; 
    //     //     nR.nextHop = routeTable[i].nextHop;
    //     //     nR.cost = routeTable[i].cost;

    //     //     makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_ROUTE_TTL, PROTOCOL_DV, 1, &nR, PACKET_MAX_PAYLOAD_SIZE);
            
    //     // }
    // }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
        
        if(len==sizeof(RouteMsg)){
            RouteMsg* myMsg=(RouteMsg*) payload;
            dbg(GENERAL_CHANNEL, "packet received at node %d\n", TOS_NODE_ID);
            
            //this is where nodes will update their routes given DV information recieved by neighbors  
            //call dvr.updateRoutingTable(new route, )

        }
    }

    event void dvrTimer.fired(){
        // makePack(&sendPackage)
        // call dvr.send()
    }


    //placeholder: may be redundant but can be useful for updating nieghbor array in situations where node connection lost
    void convertNeighbors(){
        neighbors = call Neighbor.getNeighbors();
        for (i = 0; neighbors[i] != 0; i++) {
            call neighborList.pushfront(neighbors[i]);
        }
    }

    //changed to new DVR struct to be sent to neighbors

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length){
      Package->dest = dest;
      Package->src = src;
      Package->seq = seq;
      Package->TTL = TTL;
      Package->protocol = Protocol;
      memcpy(Package->payload, payload, length);
   }
}
