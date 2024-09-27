#ifndef GEO_AUXDETGEOOBJECTSORTERYZX_H
#define GEO_AUXDETGEOOBJECTSORTERYZX_H

#include "fhiclcpp/fwd.h"
#include "larcorealg/Geometry/AuxDetGeoObjectSorter.h"

namespace geo{

  class AuxDetGeoObjectSorterYZX : public AuxDetGeoObjectSorter {
  public:
    explicit AuxDetGeoObjectSorterYZX(fhicl::ParameterSet const&);

  private:
    bool compareAuxDets(AuxDetGeo const& ad1, AuxDetGeo const& ad2) const override;
    bool compareAuxDetSensitives(AuxDetSensitiveGeo const& ad1,
                                 AuxDetSensitiveGeo const& ad2) const override;
  };

}

#endif // GEO_AUXDETGEOOBJECTSORTERYZX_H
