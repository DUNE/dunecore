#ifndef GEO_WIREREADOUTSORTERAPA_H
#define GEO_WIREREADOUTSORTERAPA_H

#include "larcorealg/Geometry/fwd.h"
#include "larcorealg/Geometry/WireReadoutSorter.h"

namespace geo {
  class WireReadoutSorterAPA : public WireReadoutSorter {
    bool compareWires(WireGeo const& w1, WireGeo const& w2) const override;
  };
}

#endif // GEO_WIREREADOUTSORTERAPA_H
