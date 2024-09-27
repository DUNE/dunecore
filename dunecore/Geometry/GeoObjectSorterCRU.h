////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterCRU.h
/// \brief Interface to algorithm class for sorting VD CRUs of geo::XXXGeo objects
///
/// \version $Id:  $
/// \author vgalymov@ipnl.in2p3.fr
////////////////////////////////////////////////////////////////////////
#ifndef GEO_GEOOBJECTSORTERCRU_H
#define GEO_GEOOBJECTSORTERCRU_H

#include "fhiclcpp/fwd.h"
#include "larcorealg/Geometry/GeoObjectSorter.h"

namespace geo{

  class GeoObjectSorterCRU : public GeoObjectSorter {
  public:
    GeoObjectSorterCRU(fhicl::ParameterSet const& p);

  private:
    bool compareCryostats(CryostatGeo const& c1, CryostatGeo const& c2) const override;
    bool compareTPCs(TPCGeo const& t1, TPCGeo const& t2) const override;
    bool compareOpDets(OpDetGeo const& t1, OpDetGeo const& t2) const override;
  };

}

#endif // GEO_GEOOBJECTSORTERCRM_H
