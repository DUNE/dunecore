#ifndef GEO_WIREREADOUTSORTERCRU_H
#define GEO_WIREREADOUTSORTERCRU_H

#include "larcorealg/Geometry/WireReadoutSorter.h"
#include "larcorealg/Geometry/WireGeo.h"

namespace geo {
  class WireReadoutSorterCRU : public WireReadoutSorter {
  private:
    bool compareWires(WireGeo const& w1, WireGeo const& w2) const override;
  };
}

#endif // GEO_WIREREADOUTSORTERCRU_H
