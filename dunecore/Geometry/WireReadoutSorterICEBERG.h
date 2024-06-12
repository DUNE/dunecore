#ifndef GEO_WIREREADOUTSORTERICEBERG_H
#define GEO_WIREREADOUTSORTERICEBERG_H

#include "larcorealg/Geometry/fwd.h"
#include "larcorealg/Geometry/WireReadoutSorter.h"

namespace geo {
  class WireReadoutSorterICEBERG : public WireReadoutSorter {
    bool compareWires(WireGeo const& w1, WireGeo const& w2) const override;
  };
}

#endif // GEO_WIREREADOUTSORTERICEBERG_H
