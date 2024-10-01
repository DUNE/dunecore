////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterAPA.cxx
/// \brief Interface to algorithm class for sorting standard geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  brebel@fnal.gov
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/GeoObjectSorterAPA.h"
#include "dunecore/Geometry/Comparators.h"
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/TPCGeo.h"

namespace geo{

  //----------------------------------------------------------------------------
  GeoObjectSorterAPA::GeoObjectSorterAPA(fhicl::ParameterSet const&)
  {
  }

  //----------------------------------------------------------------------------
  // Define sort order for cryostats in APA configuration
  //   same as standard
  bool GeoObjectSorterAPA::compareCryostats(CryostatGeo const& c1, CryostatGeo const& c2) const
  {
    geo::CryostatGeo::LocalPoint_t const local{};
    auto const xyz1 = c1.toWorldCoords(local);
    auto const xyz2 = c2.toWorldCoords(local);

    return xyz1.X() < xyz2.X();
  }


  //----------------------------------------------------------------------------
  // Define sort order for tpcs in APA configuration.
  bool GeoObjectSorterAPA::compareTPCs(TPCGeo const& t1, TPCGeo const& t2) const
  {
    // The goal is to number TPCs first in the x direction so that,
    // in the case of APA configuration, TPCs 2c and 2c+1 make up APA c.
    // then numbering will go in y then in z direction.
    return compareIncreasingZYX(t1.GetCenter(), t2.GetCenter());
  }

 //----------------------------------------------------------------------------
  bool GeoObjectSorterAPA::compareOpDets(OpDetGeo const& t1, OpDetGeo const& t2) const
  {
    return compareDecreasingXZY(t1.GetCenter(), t2.GetCenter());
 }

}
