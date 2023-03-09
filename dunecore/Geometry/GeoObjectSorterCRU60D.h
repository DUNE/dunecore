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

#include <vector>

#include "fhiclcpp/fwd.h"
#include "larcorealg/Geometry/GeoObjectSorter.h"

namespace geo{

  class GeoObjectSorterCRU60D : public GeoObjectSorter {
  public:

    GeoObjectSorterCRU60D(fhicl::ParameterSet const& p);

    void SortAuxDets        (std::vector<geo::AuxDetGeo>         & adgeo)    const;
    void SortAuxDetSensitive(std::vector<geo::AuxDetSensitiveGeo>& adsgeo)   const;
    void SortCryostats      (std::vector<geo::CryostatGeo>       & cgeo)     const;
    void SortTPCs           (std::vector<geo::TPCGeo>            & tgeo)     const;
    void SortPlanes         (std::vector<geo::PlaneGeo>          & pgeo,
                             geo::DriftDirection_t                 driftDir) const;
    void SortWires          (std::vector<geo::WireGeo>           & wgeo)     const;
    void SortOpDets         (std::vector<geo::OpDetGeo> & opdet) const;

    bool fSortTPCPDVD;

  };

}

#endif // GEO_GEOOBJECTSORTERCRU60D_H
