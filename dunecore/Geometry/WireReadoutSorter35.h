#ifndef GEO_WIREREADOUTSORTER35_H
#define GEO_WIREREADOUTSORTER35_H

#include "larcorealg/Geometry/WireReadoutSorter.h"
#include "larcorealg/Geometry/fwd.h"
#include "fhiclcpp/fwd.h"

#include <string>

namespace geo {
  //----------------------------------------------------------------------------
  // we want the wires to be sorted such that the smallest corner wire
  // on the readout end of a plane is wire zero, with wire number
  // increasing away from that wire.

  // Since 35t has an APA which is both above and below the world origin,
  // we cannot use the APA trick. If we could ask where wire 0 was, we could
  // still do this in a single implimentation, but we aren't sure what wire
  // center we will be getting, so this reversed sorting must be handled
  // at the plane level where there is one vertical center.
  // If the plane center is above, count from top down (the top stacked and
  // largest APAs) If the plane is below (bottom stacked APA) count bottom up
  class WireReadoutSorter35 : public WireReadoutSorter {
  public:
    explicit WireReadoutSorter35(fhicl::ParameterSet const& p);

  private:
    bool compareWires(WireGeo const& w1, WireGeo const& w2) const override;

    std::string fDetVersion;
  };

} // namespace

#endif // GEO_WIREREADOUTSORTER35_H
