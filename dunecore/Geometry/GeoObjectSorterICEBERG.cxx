////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterICEBERG.cxx
/// \brief Interface to algorithm class for sorting standard geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  Tom Junk, based on the APA object sorter by Brian Rebel
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/GeoObjectSorterICEBERG.h"
#include "dunecore/Geometry/OpDetSorter.h"
#include "larcorealg/Geometry/AuxDetGeo.h"
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/TPCGeo.h"
#include "larcorealg/Geometry/PlaneGeo.h"
#include "larcorealg/Geometry/WireGeo.h"

namespace geo{

  //----------------------------------------------------------------------------
  static bool sortAuxDetICEBERG(const AuxDetGeo& ad1, const AuxDetGeo& ad2)
  {

    // NOTE: This initial sorting is arbitrary, there
    //       are no ICEBERGAlg users using AuxDet yet

    auto const xyz1 = ad1.GetCenter();
    auto const xyz2 = ad2.GetCenter();

    // First sort all AuxDets into same-y groups
    if(xyz1.Y() < xyz2.Y()) return true;

    // Within a same-y group, sort TPCs into same-z groups
    if(xyz1.Y() == xyz2.Y() && xyz1.Z() < xyz2.Z()) return true;

    // Within a same-z, same-y group, sort TPCs according to x
    if(xyz1.Z() == xyz2.Z() && xyz1.Y() == xyz2.Y() && xyz1.X() < xyz2.X()) return true;

    // none of those are true, so return false
    return false;

  }

  //----------------------------------------------------------------------------
  static bool sortAuxDetSensitiveICEBERG(const AuxDetSensitiveGeo& ad1, const AuxDetSensitiveGeo& ad2)
  {

    // NOTE: This initial sorting is arbitrary, there
    //       are no ICEBERGAlg users using AuxDet yet

    auto const xyz1 = ad1.GetCenter();
    auto const xyz2 = ad2.GetCenter();

    // First sort all AuxDets into same-y groups
    if(xyz1.Y() < xyz2.Y()) return true;

    // Within a same-y group, sort TPCs into same-z groups
    if(xyz1.Y() == xyz2.Y() && xyz1.Z() < xyz2.Z()) return true;

    // Within a same-z, same-y group, sort TPCs according to x
    if(xyz1.Z() == xyz2.Z() && xyz1.Y() == xyz2.Y() && xyz1.X() < xyz2.X()) return true;

    // none of those are true, so return false
    return false;

  }

  //----------------------------------------------------------------------------
  // Define sort order for cryostats in ICEBERG configuration
  //   same as standard
  static bool sortCryoICEBERG(const CryostatGeo& c1, const CryostatGeo& c2)
  {
    geo::CryostatGeo::LocalPoint_t const local{};
    auto const xyz1 = c1.toWorldCoords(local);
    auto const xyz2 = c2.toWorldCoords(local);

    return xyz1.X() < xyz2.X();
  }


  //----------------------------------------------------------------------------
  // Define sort order for tpcs in ICEBERG configuration.
  static bool sortTPCICEBERG(const TPCGeo& t1, const TPCGeo& t2)
  {
    auto const xyz1 = t1.GetCenter();
    auto const xyz2 = t2.GetCenter();

    // The goal is to number TPCs first in the x direction so that,
    // in the case of ICEBERG configuration, TPCs 2c and 2c+1 make up ICEBERG c.
    // then numbering will go in y then in z direction.

    // First sort all TPCs into same-z groups
    if(xyz1.Z() < xyz2.Z()) return true;

    // Within a same-z group, sort TPCs into same-y groups
    if(xyz1.Z() == xyz2.Z() && xyz1.Y() < xyz2.Y()) return true;

    // Within a same-z, same-y group, sort TPCs according to x
    if(xyz1.Z() == xyz2.Z() && xyz1.Y() == xyz2.Y() && xyz1.X() < xyz2.X()) return true;

    // none of those are true, so return false
    return false;
  }


 //----------------------------------------------------------------------------
  // Define sort order for planes in ICEBERG configuration
  //   same as standard, but implemented differently
  static bool sortPlaneICEBERG(const PlaneGeo& p1, const PlaneGeo& p2)
  {
    auto const xyz1 = p1.GetBoxCenter();
    auto const xyz2 = p2.GetBoxCenter();

    return xyz1.X() > xyz2.X();
  }


  //----------------------------------------------------------------------------
  bool sortWireICEBERG(WireGeo& w1, WireGeo& w2){
    auto const xyz1 = w1.GetCenter();
    auto const xyz2 = w2.GetCenter();

    // we want the wires to be sorted such that the smallest corner wire
    // on the readout end of a plane is wire zero, with wire number
    // increasing away from that wire.

    if ( xyz1.X() < -3.95 && xyz1.X() > -3.96) 
      {
	// U0
	if (xyz1.Z() > xyz2.Z()) return true;
      }
    if (xyz1.X() > 3.95 && xyz1.X() < 3.96)
      {
	// U1
	if (xyz1.Z() < xyz2.Z()) return true;
      }
    if ( xyz1.X() < -3.47 && xyz1.X() > -3.48) 
      {
	// V0
	if (xyz1.Z() < xyz2.Z()) return true;
      }
    if (xyz1.X() > 3.47 && xyz1.X() < 3.48)
      {
	// V1
       if (xyz1.Z() >xyz2.Z()) return true;
      }
    if ( xyz1.X() < -2.99 && xyz1.X() > -3.01) 
      {
	// Z0
       if (xyz1.Z() < xyz2.Z()) return true;
      }
    if (xyz1.X() > 2.99 && xyz1.X() < 3.01)
      {
	// Z1
       if (xyz1.Z() < xyz2.Z()) return true;
      }
    
    // if a bottom TPC, count from bottom up
    //if( xyz1.Y()<0 && xyz1.Y() < xyz2.Y() ) return true;

    // sort the all vertical wires to increase in +z direction
    //if( xyz1.Y() == xyz2.Y() && xyz1.Z() < xyz2.Z() ) return true;

    return false;
  }


  //----------------------------------------------------------------------------
  GeoObjectSorterICEBERG::GeoObjectSorterICEBERG(fhicl::ParameterSet const&)
  {
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterICEBERG::SortAuxDets(std::vector<geo::AuxDetGeo> & adgeo) const
  {
    std::sort(adgeo.begin(), adgeo.end(), sortAuxDetICEBERG);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterICEBERG::SortAuxDetSensitive(std::vector<geo::AuxDetSensitiveGeo> & adgeo) const
  {
    std::sort(adgeo.begin(), adgeo.end(), sortAuxDetSensitiveICEBERG);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterICEBERG::SortCryostats(std::vector<geo::CryostatGeo> & cgeo) const
  {
    std::sort(cgeo.begin(), cgeo.end(), sortCryoICEBERG);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterICEBERG::SortTPCs(std::vector<geo::TPCGeo>  & tgeo) const
  {
    std::sort(tgeo.begin(), tgeo.end(), sortTPCICEBERG);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterICEBERG::SortPlanes(std::vector<geo::PlaneGeo> & pgeo,
                                      geo::DriftDirection_t  const driftDir) const
  {
    // sort the planes to increase in drift direction
    // The drift direction has to be set before this method is called.  It is set when
    // the CryostatGeo objects are sorted by the CryostatGeo::SortSubVolumes method
    if     (driftDir == geo::kPosX) std::sort(pgeo.rbegin(), pgeo.rend(), sortPlaneICEBERG);
    else if(driftDir == geo::kNegX) std::sort(pgeo.begin(),  pgeo.end(),  sortPlaneICEBERG);
    else if(driftDir == geo::kUnknownDrift)
      throw cet::exception("TPCGeo") << "Drift direction is unknown, can't sort the planes\n";
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterICEBERG::SortWires(std::vector<geo::WireGeo> & wgeo) const
  {
    std::sort(wgeo.begin(), wgeo.end(), sortWireICEBERG);
  }

  //----------------------------------------------------------------------------
 void GeoObjectSorterICEBERG::SortOpDets         (std::vector<geo::OpDetGeo> & opdet) const {
   std::sort(opdet.begin(), opdet.end(), sortorderOpDet);
 }

}
