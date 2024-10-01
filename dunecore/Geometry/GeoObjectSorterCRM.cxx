////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterCRM.cxx
/// \brief Interface to algorithm class for sorting dual-phase CRM geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  brebel@fnal.gov vgalymov@ipnl.in2p3.fr
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/GeoObjectSorterCRM.h"
#include "dunecore/Geometry/Comparators.h"
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/TPCGeo.h"

namespace geo{

  //----------------------------------------------------------------------------
  GeoObjectSorterCRM::GeoObjectSorterCRM(fhicl::ParameterSet const&)
  {
  }

  //----------------------------------------------------------------------------
  // Define sort order for cryostats in dual-phase configuration
  bool GeoObjectSorterCRM::compareCryostats(CryostatGeo const& c1, CryostatGeo const& c2) const
  {
    geo::CryostatGeo::LocalPoint_t const local{};
    auto const xyz1 = c1.toWorldCoords(local);
    auto const xyz2 = c2.toWorldCoords(local);

    return xyz1.X() < xyz2.X();
  }

  //----------------------------------------------------------------------------
  bool GeoObjectSorterCRM::compareTPCs(TPCGeo const& t1, TPCGeo const& t2) const
  {
    auto const xyz1 = t1.GetCenter();
    auto const xyz2 = t2.GetCenter();

    // First sort all TPCs into same-z groups
    if(xyz1.Z()<xyz2.Z()) return true;

    // Within a same-z group, sort TPCs into same-y groups
    if(xyz1.Z() == xyz2.Z() && xyz1.Y() < xyz2.Y()) return true;

    return false;
  }

  //----------------------------------------------------------------------------
  bool GeoObjectSorterCRM::compareOpDets(OpDetGeo const& t1, OpDetGeo const& t2) const
  {
    return compareDecreasingXZY(t1.GetCenter(), t2.GetCenter());
 }

}
