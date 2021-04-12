#include "../../includes/packet.h"
#include "../../includes/route.h"
#include <Timer.h>

configuration dvrC{
    provides interface dvr;
}

implementation{
    components dvrP;
    dvr = dvrP;

    //reverted back to AM_PACK to work with Node.nc

    components new SimpleSendC(AM_PACK) as routeSender;
    dvrP.dvrSend -> routeSender;

    components new AMReceiverC(AM_PACK) as routeReciever;
    dvrP.Receive -> routeReciever;

    components new TimerMilliC() as t;
    dvrP.dvrTimer -> t;
    dvrP.dvrTimer2 -> t;

    components RandomC as rand;
    dvrP.Random -> rand;

    components new ListC(RouteMsg, 256) as l2;
    dvrP.routeTable ->l2;

}
