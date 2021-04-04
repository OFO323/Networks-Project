#include "../../includes/packet.h"
#include "../../includes/route.h"
#include <Timer.h>

configuration dvrC{
    provides interface dvr;
}

implementation{
    components dvrP;
    dvr = dvrP.dvr;

    //may nee to include package type (i.e. ROUTE_PACK in route.h)
    components new SimpleSendC(AM_ROUTE_PACK) as routeSender;
    dvrP.dvrSend -> routeSender;

    components new AMReceiverC(AM_ROUTE_PACK) as routeReciever;
    dvrP.Receive -> routeReciever;

    components new TimerMilliC() as t;
    dvrP.dvrTimer -> t;

    components RandomC as rand;
    dvrP.Random -> rand;

    components new ListC(uint16_t, 50) as l;
    dvrP.neighborList -> l;

    components new HashmapC(uint8_t, 50) as h;
    dvrP.distVect -> h;

    //components new HashmapC(uint16_t, 50) as h2;
    // dvrP.routeTable -> h; //says no match???

    components NeighborC as n;
    dvrP.Neighbor -> n;
}