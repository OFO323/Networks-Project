#include "../../includes/route.h"

interface dvr {
    command void initalizeNodes();

    command void initalizeDV();

    command void intializeRT();

    command void mergeRoutes(RouteMsg *route);

    command void updateRoutingTable(RouteMsg *newR, uint16_t numNewRoutes);

    command void sendRoutes();
}