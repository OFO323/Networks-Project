#include "../../includes/packet.h"
#include <Timer.h>

configuration NeighborC {
    provides interface Neighbor;
}
//DD: We need to call the functions from the module file, so now its correct bc
//[file].[whatever we want to wire] -> [component we are wiring to]
implementation {

    components NeighborP;
    Neighbor = NeighborP.Neighbor;

    components new SimpleSendC(AM_PACK);
    NeighborP.NeighborSend -> SimpleSendC;

    components new AMReceiverC(AM_PACK) as neigborReciever;
    NeighborP.Receive -> neigborReciever;

    components new TimerMilliC() as t;
    NeighborP.n_timer -> t;

    components RandomC as rand;
    NeighborP.Random -> rand;

    components new ListC(uint16_t, 50) as l;
    NeighborP.n_List -> l;
}