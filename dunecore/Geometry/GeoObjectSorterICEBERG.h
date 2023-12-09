////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterICEBERG.h
/// \brief Interface to algorithm class for standard sorting of geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  Tom Junk, modeled on an original by Brian Rebel
////////////////////////////////////////////////////////////////////////
#ifndef GEO_GEOOBJECTSORTERICEBERG_H
#define GEO_GEOOBJECTSORTERICEBERG_H

#include "fhiclcpp/fwd.h"
#include "larcorealg/Geometry/GeoObjectSorter.h"

namespace geo{

  class GeoObjectSorterICEBERG : public GeoObjectSorter {
  public:
    GeoObjectSorterICEBERG(fhicl::ParameterSet const& p);

  private:
    bool compareCryostats(geo::CryostatGeo const& c1, geo::CryostatGeo const& c2) const override;
    bool compareTPCs(geo::TPCGeo const& t1, geo::TPCGeo const& t2) const override;
    bool compareOpDets(OpDetGeo const& t1, OpDetGeo const& t2) const override;
  };

}

#endif // GEO_GEOOBJECTSORTERICEBERG_H
