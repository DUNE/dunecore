////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterAPA.cxx
/// \brief Interface to algorithm class for sorting standard geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  brebel@fnal.gov
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/GeoObjectSorterAPA.h"
#include "dunecore/Geometry/OpDetSorter.h"
#include "larcorealg/Geometry/AuxDetGeo.h"
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/TPCGeo.h"
#include "larcorealg/Geometry/PlaneGeo.h"
#include "larcorealg/Geometry/WireGeo.h"

namespace geo{

  //----------------------------------------------------------------------------
  static bool sortAuxDetAPA(const AuxDetGeo& ad1, const AuxDetGeo& ad2)
  {

    // NOTE: This initial sorting is arbitrary, there
    //       are no APAAlg users using AuxDet yet

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
  static bool sortAuxDetSensitiveAPA(const AuxDetSensitiveGeo& ad1, const AuxDetSensitiveGeo& ad2)
  {

    // NOTE: This initial sorting is arbitrary, there
    //       are no APAAlg users using AuxDet yet

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
  // Define sort order for cryostats in APA configuration
  //   same as standard
  static bool sortCryoAPA(const CryostatGeo& c1, const CryostatGeo& c2)
  {
    geo::CryostatGeo::LocalPoint_t const local{};
    auto const xyz1 = c1.toWorldCoords(local);
    auto const xyz2 = c2.toWorldCoords(local);

    return xyz1.X() < xyz2.X();
  }


  //----------------------------------------------------------------------------
  // Define sort order for tpcs in APA configuration.
  static bool sortTPCAPA(const TPCGeo& t1, const TPCGeo& t2)
  {
    auto const xyz1 = t1.GetCenter();
    auto const xyz2 = t2.GetCenter();

    // The goal is to number TPCs first in the x direction so that,
    // in the case of APA configuration, TPCs 2c and 2c+1 make up APA c.
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
  // Define sort order for planes in APA configuration
  //   same as standard, but implemented differently
  static bool sortPlaneAPA(const PlaneGeo& p1, const PlaneGeo& p2)
  {
    auto const xyz1 = p1.GetBoxCenter();
    auto const xyz2 = p2.GetBoxCenter();

    return xyz1.X() > xyz2.X();
  }


  //----------------------------------------------------------------------------
  bool sortWireAPA(WireGeo& w1, WireGeo& w2){
    auto const xyz1 = w1.GetCenter();
    auto const xyz2 = w2.GetCenter();

    // we want the wires to be sorted such that the smallest corner wire
    // on the readout end of a plane is wire zero, with wire number
    // increasing away from that wire.

    // if a top TPC, count from top down
    if( xyz1.Y()>0 && xyz1.Y() > xyz2.Y() ) return true;

    // if a bottom TPC, count from bottom up
    if( xyz1.Y()<0 && xyz1.Y() < xyz2.Y() ) return true;

    // sort the all vertical wires to increase in +z direction
    if( xyz1.Y() == xyz2.Y() && xyz1.Z() < xyz2.Z() ) return true;

    return false;
  }


  //----------------------------------------------------------------------------
  GeoObjectSorterAPA::GeoObjectSorterAPA(fhicl::ParameterSet const&)
  {
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterAPA::SortAuxDets(std::vector<geo::AuxDetGeo> & adgeo) const
  {
    std::sort(adgeo.begin(), adgeo.end(), sortAuxDetAPA);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterAPA::SortAuxDetSensitive(std::vector<geo::AuxDetSensitiveGeo> & adgeo) const
  {
    std::sort(adgeo.begin(), adgeo.end(), sortAuxDetSensitiveAPA);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterAPA::SortCryostats(std::vector<geo::CryostatGeo> & cgeo) const
  {
    std::sort(cgeo.begin(), cgeo.end(), sortCryoAPA);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterAPA::SortTPCs(std::vector<geo::TPCGeo>  & tgeo) const
  {
    std::sort(tgeo.begin(), tgeo.end(), sortTPCAPA);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterAPA::SortPlanes(std::vector<geo::PlaneGeo> & pgeo,
                                      geo::DriftDirection_t  const driftDir) const
  {
    // sort the planes to increase in drift direction
    // The drift direction has to be set before this method is called.  It is set when
    // the CryostatGeo objects are sorted by the CryostatGeo::SortSubVolumes method
    if     (driftDir == geo::kPosX) std::sort(pgeo.rbegin(), pgeo.rend(), sortPlaneAPA);
    else if(driftDir == geo::kNegX) std::sort(pgeo.begin(),  pgeo.end(),  sortPlaneAPA);
    else if(driftDir == geo::kUnknownDrift)
      throw cet::exception("TPCGeo") << "Drift direction is unknown, can't sort the planes\n";
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterAPA::SortWires(std::vector<geo::WireGeo> & wgeo) const
  {
    std::sort(wgeo.begin(), wgeo.end(), sortWireAPA);
  }

  //----------------------------------------------------------------------------
 void GeoObjectSorterAPA::SortOpDets         (std::vector<geo::OpDetGeo> & opdet) const {
   std::sort(opdet.begin(), opdet.end(), sortorderOpDet);
 }

}
