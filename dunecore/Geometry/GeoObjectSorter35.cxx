////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorter35.cxx
/// \brief Interface to algorithm class for sorting standard geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  brebel@fnal.gov
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/GeoObjectSorter35.h"
#include "dunecore/Geometry/Comparators.h"
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/TPCGeo.h"

// #include "messagefacility/MessageLogger/MessageLogger.h"

namespace geo{

  GeoObjectSorter35::GeoObjectSorter35(fhicl::ParameterSet const&)
  {}

  //----------------------------------------------------------------------------
  bool GeoObjectSorter35::compareCryostats(CryostatGeo const& c1, CryostatGeo const& c2) const
  {
    geo::CryostatGeo::LocalPoint_t const local{};
    auto const xyz1 = c1.toWorldCoords(local);
    auto const xyz2 = c2.toWorldCoords(local);

    return xyz1.X() < xyz2.X();
  }

  //----------------------------------------------------------------------------
  bool GeoObjectSorter35::compareTPCs(TPCGeo const& t1, TPCGeo const& t2) const
  {
    // very useful for aligning volume sorting with GDML bounds
    //  --> looking at this output is one way to find the z-borders between APAs,
    //      which tells soreWire35 to sort depending on z position via "InVertSplitRegion"
    //mf::LogVerbatim("sortTPC35") << "tpx z range = " << xyz1.Z() - t1->Length()/2
    //				 << " to " << xyz1.Z() + t1->Length()/2;

    // The goal is to number TPCs first in the x direction so that,
    // in the case of APA configuration, TPCs 2c and 2c+1 make up APA c.
    // then numbering will go in y then in z direction.
    return compareIncreasingZYX(t1.GetCenter(), t2.GetCenter());
  }
}
