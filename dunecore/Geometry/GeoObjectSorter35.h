////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorter35.h
/// \brief Interface to algorithm class for standard sorting of geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  brebel@fnal.gov
////////////////////////////////////////////////////////////////////////
#ifndef GEO_GEOOBJECTSORTER35_H
#define GEO_GEOOBJECTSORTER35_H

#include "fhiclcpp/fwd.h"
#include "larcorealg/Geometry/GeoObjectSorter.h"

namespace geo{

  class GeoObjectSorter35 : public GeoObjectSorter {
  public:
    explicit GeoObjectSorter35(fhicl::ParameterSet const&);

  private:
    bool compareCryostats(CryostatGeo const& c1, CryostatGeo const& c2) const override;
    bool compareTPCs(TPCGeo const& t1, TPCGeo const& t2) const override;
  };

}

#endif // GEO_GEOOBJECTSORTER35_H
