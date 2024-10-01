////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterAPA.h
/// \brief Interface to algorithm class for standard sorting of geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  brebel@fnal.gov
////////////////////////////////////////////////////////////////////////
#ifndef GEO_GEOOBJECTSORTERAPA_H
#define GEO_GEOOBJECTSORTERAPA_H

#include "fhiclcpp/fwd.h"
#include "larcorealg/Geometry/GeoObjectSorter.h"

namespace geo{

  class GeoObjectSorterAPA : public GeoObjectSorter {
  public:
    GeoObjectSorterAPA(fhicl::ParameterSet const& p);

  private:
    bool compareCryostats(CryostatGeo const& c1, CryostatGeo const& c2) const override;
    bool compareTPCs(TPCGeo const& t1, TPCGeo const& t2) const override;
    bool compareOpDets(OpDetGeo const& t1, OpDetGeo const& t2) const override;
  };

}

#endif // GEO_GEOOBJECTSORTERAPA_H
