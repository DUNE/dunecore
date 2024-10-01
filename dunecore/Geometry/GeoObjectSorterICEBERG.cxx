////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterICEBERG.cxx
/// \brief Interface to algorithm class for sorting standard geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  Tom Junk, based on the APA object sorter by Brian Rebel
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/GeoObjectSorterICEBERG.h"
#include "dunecore/Geometry/Comparators.h"
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/TPCGeo.h"

namespace geo{

  //----------------------------------------------------------------------------
  GeoObjectSorterICEBERG::GeoObjectSorterICEBERG(fhicl::ParameterSet const&)
  {
  }

  //----------------------------------------------------------------------------
  // Define sort order for cryostats in ICEBERG configuration
  //   same as standard
  bool GeoObjectSorterICEBERG::compareCryostats(geo::CryostatGeo const& c1, geo::CryostatGeo const& c2) const
  {
    geo::CryostatGeo::LocalPoint_t const local{};
    auto const xyz1 = c1.toWorldCoords(local);
    auto const xyz2 = c2.toWorldCoords(local);

    return xyz1.X() < xyz2.X();
  }


  //----------------------------------------------------------------------------
  // Define sort order for tpcs in ICEBERG configuration.
  bool GeoObjectSorterICEBERG::compareTPCs(geo::TPCGeo const& t1, geo::TPCGeo const& t2) const
  {
    // The goal is to number TPCs first in the x direction so that,
    // in the case of ICEBERG configuration, TPCs 2c and 2c+1 make up ICEBERG c.
    // then numbering will go in y then in z direction.
    return compareIncreasingZYX(t1.GetCenter(), t2.GetCenter());
  }

  //----------------------------------------------------------------------------
  bool GeoObjectSorterICEBERG::compareOpDets(OpDetGeo const& t1, OpDetGeo const& t2) const
      {
    return compareDecreasingXZY(t1.GetCenter(), t2.GetCenter());
 }

}
