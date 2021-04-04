/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"

configuration NodeC{
}
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;

    Node -> MainC.Boot;

    Node.Receive -> GeneralReceive;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;


    //project 1

    components new TimerMilliC() as t0; //new timer wired to TOS built in timer
    //Node.projTimer -> t0;
 
    components RandomC as r;  
    Node.rand -> r;


    //flooding module connected 
    // components FloodingC;
    // Node.Flooding -> FloodingC;

    //Project 2

    //DVR Componenet
        //will use :
        //DV componenent [?]
        //Routing Table Componenet [?]
    //not sure if should split into different modules or all in one

    components dvrC;
    Node.dvr -> dvrC;

    
    components NeighborC;
    Node.Neighbor -> NeighborC;
}