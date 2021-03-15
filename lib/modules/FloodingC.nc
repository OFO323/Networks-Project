#include <Timer.h>
#include "../../includes/am_types.h"
#include "../../includes/packet.h"

configuration FloodingC {
    provides interface Flooding;

}

implementation {
    components FloodingP;
    Flooding = FloodingP.Flooding;

    //now grants the reciever funcs to Flooding module [check Node.nc for example of how it was used]

    components new AMReceiverC(AM_PACK) as FloodingReciever; //AMReceiverC accepts AM type as parameter and has a .recieve func to wire and use 
    FloodingP.FloodRecieve -> FloodingReciever; 

    components new SimpleSendC(AM_PACK);
    FloodingP.FloodSender -> SimpleSendC;

    components new HashmapC(uint16_t, 50) as h; //used for identifying packets to prevent infinite circulation
    FloodingP.f_Hashmap -> h;
}