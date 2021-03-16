#include <Timer.h>
#include "../../includes/packet.h"
#include "../../includes/sendInfo.h"
#include "../../includes/channels.h"
#include "../../includes/command.h"

//look into AMpacket interface to extract src and destination in the .recieve function 

module FloodingP {

    provides interface Flooding;

    uses interface SimpleSend as FloodSender;
    uses interface Packet;

    uses interface Receive as FloodRecieve;

    uses interface Hashmap<uint16_t> as f_Hashmap;


}

//goal: Each node floods a packet to all it neighbor nodes. 
//These packets continue to flood until it reaches its final destination. 
//Must work as pings and ping replies. 
//Only use information accessible from the packet and its headers.

implementation {

    message_t pkt;
    pack sendPackage;
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
    bool result;
    bool msgArrived;


    command void Flooding.beginFlood(uint16_t destination, uint8_t *payload, uint16_t num) { //starts broadcasting packet to neighbors

        //dbg(GENERAL_CHANNEL, "FLOODING BEGINS\n");   
        //make & send flooding packets out with the appropriate sequence number
        makePack(&sendPackage, TOS_NODE_ID, destination, 10, PROTOCOL_PING, num, payload, PACKET_MAX_PAYLOAD_SIZE);
        call FloodSender.send(sendPackage, AM_BROADCAST_ADDR);

    }
    //logic for event in which flood pack is recieved 

    event message_t* FloodRecieve.receive(message_t* msg, void* payload, uint8_t len) { 
        
        if (len == sizeof(pack)){ //check for expected size of payload 
            pack* myMsg=(pack*) payload; //typecast payload to extract data in myMsg
            //dbg(FLOODING_CHANNEL, "Packet recieved at %d from %d!\n", TOS_NODE_ID, myMsg->src);
            if (myMsg->TTL == 0){ //verify TTL > 0
                dbg(GENERAL_CHANNEL, "Packet expired from %d to destination %d with payload %s\n", myMsg->src, myMsg->dest, myMsg->payload);
                    return msg;
                }
            if ((myMsg->protocol == 0)){ //verifies it is a ping protocol 
                //dbg(FLOODING_CHANNEL, "-----Packet destination is %d-----\n", myMsg->dest); 
                }


            if(myMsg->dest == TOS_NODE_ID && msgArrived == FALSE){ //check if destination matches the current node ID
                    //get keys [pull from pointer value]
                    //iterate thru list of keys 
                    //check if each key has a sequence # that matches myMsg->seq
                        //if true , discard packet 
                    //dbg(FLOODING_CHANNEL, "Packet arrived at destination %d from node %d with payload %s\n", myMsg->dest, myMsg->src, myMsg->payload);
                    msgArrived = TRUE;
            } 
            else {
                    
                    //Check via Hashmap.contains if key == myMsg->seq THIS WILL BE A BOOLEAN
                    result = ( call f_Hashmap.contains(myMsg->seq) );
                    
                    if ((result)) {
                        //dbg(GENERAL_CHANNEL, "Discarding Packet with sequence num %d\n", myMsg->seq);
                        return msg; //if it does contain the key, discard the packet
                    }
                    else {
                        //dbg(GENERAL_CHANNEL, "Adding seq %d with src %d to hashmap\n", myMsg->seq, myMsg->src);
                        call f_Hashmap.insert(myMsg->seq, myMsg->src); //if not, add it to the hashmap 
                    }

                    myMsg->TTL -= 1; //decement with every hop

                    myMsg->protocol = PROTOCOL_PING; //maintain ping protocol [possibly redundant]

                    //send updated packet to neighbor nodes 
                    makePack(&sendPackage, TOS_NODE_ID, myMsg->dest, myMsg->TTL , myMsg->protocol, myMsg->seq, myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);   

                    if (call FloodSender.send(sendPackage, AM_BROADCAST_ADDR) == SUCCESS){
                        //dbg(FLOODING_CHANNEL, " [Node %d] : Passing flooding packet to neighbors of \n", TOS_NODE_ID);
                    } else {
                        //dbg(FLOODING_CHANNEL, "Error sending flooding packet occured at node %d\n", TOS_NODE_ID);
                    }
            }
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