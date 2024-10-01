////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterCRU60Dx.h
/// \brief Interface to algorithm class for sorting VD CRUs of geo::XXXGeo objects
///        this targets the final 60D anode geometry
///        The direction of the drift is assumed to be the X axis for now
///
/// \version $Id:  $
/// \author vgalymov@ipnl.in2p3.fr
///
/// 3/9/2023 Add a flag for using ProtoDUNE-VD's TPCSorter, wgu@bnl.gov 
////////////////////////////////////////////////////////////////////////
#ifndef GEO_GEOOBJECTSORTERCRU60D_H
#define GEO_GEOOBJECTSORTERCRU60D_H

#include "fhiclcpp/fwd.h"
#include "larcorealg/Geometry/GeoObjectSorter.h"

namespace geo{

  class GeoObjectSorterCRU60D : public GeoObjectSorter {
  public:
    GeoObjectSorterCRU60D(fhicl::ParameterSet const& p);

  private:
    bool compareCryostats(CryostatGeo const& c1, CryostatGeo const& c2) const override;
    bool compareTPCs(TPCGeo const& t1, TPCGeo const& t2) const override;
    bool compareOpDets(OpDetGeo const& t1, OpDetGeo const& t2) const override;

    bool fSortTPCPDVD;
  };

}

#endif // GEO_GEOOBJECTSORTERCRU60D_H
