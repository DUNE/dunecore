////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterAPA.cxx
/// \brief Interface to algorithm class for sorting standard geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  brebel@fnal.gov
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/AuxDetGeoObjectSorterYZX.h"
#include "dunecore/Geometry/Comparators.h"
#include "larcorealg/Geometry/AuxDetGeo.h"
#include "larcorealg/Geometry/AuxDetSensitiveGeo.h"

namespace geo{

  //----------------------------------------------------------------------------
  AuxDetGeoObjectSorterYZX::AuxDetGeoObjectSorterYZX(fhicl::ParameterSet const&)
  {
  }

  //----------------------------------------------------------------------------
  bool AuxDetGeoObjectSorterYZX::compareAuxDets(AuxDetGeo const& ad1, AuxDetGeo const& ad2) const
  {
    // NOTE: This initial sorting is arbitrary, there are no APAAlg
    //       users using AuxDet yet
    return compareIncreasingYZX(ad1.GetCenter(), ad2.GetCenter());
  }

  //----------------------------------------------------------------------------
  bool AuxDetGeoObjectSorterYZX::compareAuxDetSensitives(AuxDetSensitiveGeo const& ad1,
                                                         AuxDetSensitiveGeo const& ad2) const
  {
    // NOTE: This initial sorting is arbitrary, there are no APAAlg
    //       users using AuxDet yet
    return compareIncreasingYZX(ad1.GetCenter(), ad2.GetCenter());
  }

}
