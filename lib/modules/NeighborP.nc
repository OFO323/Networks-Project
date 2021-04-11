#include <Timer.h>
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/protocol.h"

module NeighborP{

    provides interface Neighbor;

    //for recieving/sending packets with protocol: PING_REPLY
    
    uses interface Receive;
    uses interface SimpleSend as NeighborSend;

    uses interface Timer<TMilli> as n_timer; //timer used to fire neighbor discovery actions for each node
    uses interface Random;

    uses interface List<uint16_t> as n_List; //RH: stores the neighbors for each node 

}
//DD: If we call something through the interface, we have ea. command as [interface].[function name]() {}
//however, if we call through the same module file, then we only need to call by the function name directly, 
//given that our interface doesn't already include this function. See the call at line 43 and correlate with 49.


implementation {
    pack sendPackage;
    uint8_t n_array[40] = {0};

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

    uint32_t t, del; //used for timer

    uint16_t i; //counter for print neighbor 
    uint16_t j;

    //project 2: used to get nieghbors to initalize DV of each node
    uint16_t x;

    uint8_t nSize;

    //way of choosing which node discovers neighbors first [deals with problem of congestion]
    command void Neighbor.initTimer(){
        t = (call Random.rand32()) % 2013;
        del = 1000 + (call Random.rand32()) % 10021;

        call n_timer.startPeriodicAt(t, del);

        //dbg(GENERAL_CHANNEL, "Timer for node %d fired started at %d with interval %d\n", TOS_NODE_ID, t, del);
    }

    //process is called when timer fires for each node
    command void Neighbor.beginNeighborDiscovery(){
        //send discovery packet to nodes attached to TOS_NODE_ID

        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, PROTOCOL_PINGREPLY, 0, "Neighbor node?", PACKET_MAX_PAYLOAD_SIZE);
        call NeighborSend.send(sendPackage, AM_BROADCAST_ADDR);

    }

    command void Neighbor.printNeighbors(){

        for (i = 0; i < call n_List.size(); i++){
            dbg(NEIGHBOR_CHANNEL, "A neighbor of node %d is %d\n",TOS_NODE_ID, call n_List.get(i));
        }
    }
    
    //RH : added as an extension for project 2
    //works fine but may need to implement check incase multiple of the same nodeID appear
    command uint8_t* Neighbor.getNeighbors(){ 
        //adding in the copy to an array here
        for (i = 0; i < call n_List.size(); i++) { 
            n_array[i] = call n_List.get(i);
            //dbg(NEIGHBOR_CHANNEL,"added %d to neighbor array\n", n_array[i]);
        }
        return n_array;
    }

    command uint16_t* Neighbor.neighSize(){
        nSize = call n_List.size();
        return (uint16_t*)nSize; 
    }

    event void n_timer.fired(){
        call Neighbor.beginNeighborDiscovery();

        //project 1, no longer needed
        //call Neighbor.printNeighbors(); //move to Node.nc
        //check status [if still active]
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      if(len==sizeof(pack)){
            pack* myMsg=(pack*) payload;
            if(myMsg->protocol == 1){ //ping reply received -> neighbor acknowledged and added to list 
                /*where you would add to list*/
                if (myMsg->TTL == 0){      
                    //dbg(GENERAL_CHANNEL, "packet expired // TTL == 0\n"); //RH: debug                     
                    return msg;
                }
                //sending back ping reply from TOS_NODE_ID[one hop away from myMsg->src]
                makePack(&sendPackage, TOS_NODE_ID, myMsg->src, myMsg->TTL - 1, PROTOCOL_PINGREPLY, 0, "Yes we're neighbors!", PACKET_MAX_PAYLOAD_SIZE);
                call NeighborSend.send(sendPackage, myMsg->src);
                    
                if(myMsg->TTL == 1){
                    //dbg(GENERAL_CHANNEL, "neighbor node %d acknowledged\n", myMsg->src);

                    for(j = 0; j < call n_List.size(); j++){ //check current list of neighbors 
                        if(myMsg->src == call n_List.get(j)){ //already in list 
                            
                            return msg;                  //discard 
                        }
                    }
                    call n_List.pushfront(myMsg->src); //add to list
                }
            }
            return msg;
        }
    }

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }


}