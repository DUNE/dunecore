////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterICEBERG.h
/// \brief Interface to algorithm class for standard sorting of geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  Tom Junk, modeled on an original by Brian Rebel
////////////////////////////////////////////////////////////////////////
#ifndef GEO_GEOOBJECTSORTERICEBERG_H
#define GEO_GEOOBJECTSORTERICEBERG_H

#include <vector>

#include "fhiclcpp/fwd.h"
#include "larcorealg/Geometry/GeoObjectSorter.h"

namespace geo{

  class GeoObjectSorterICEBERG : public GeoObjectSorter {
  public:

    GeoObjectSorterICEBERG(fhicl::ParameterSet const& p);

    void SortAuxDets        (std::vector<geo::AuxDetGeo>            & adgeo)    const;
    void SortAuxDetSensitive(std::vector<geo::AuxDetSensitiveGeo>   & adgeo)    const;
    void SortCryostats      (std::vector<geo::CryostatGeo>          & cgeo)     const;
    void SortTPCs           (std::vector<geo::TPCGeo>               & tgeo)     const;
    void SortPlanes         (std::vector<geo::PlaneGeo>             & pgeo,
                             geo::DriftDirection_t                    driftDir) const;
    void SortWires          (std::vector<geo::WireGeo>              & wgeo)     const;
    void SortOpDets         (std::vector<geo::OpDetGeo> & opdet) const;

  };

}

#endif // GEO_GEOOBJECTSORTERICEBERG_H
