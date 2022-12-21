////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterCRM.cxx
/// \brief Interface to algorithm class for sorting dual-phase CRM geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  brebel@fnal.gov vgalymov@ipnl.in2p3.fr
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/GeoObjectSorterCRM.h"
#include "dunecore/Geometry/OpDetSorter.h"
#include "larcorealg/Geometry/AuxDetGeo.h"
#include "larcorealg/Geometry/AuxDetSensitiveGeo.h"
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/TPCGeo.h"
#include "larcorealg/Geometry/PlaneGeo.h"
#include "larcorealg/Geometry/WireGeo.h"

#include <array>
#include <string>
#include <cmath> // std::abs()

namespace geo{

  //----------------------------------------------------------------------------
  // Define sort order for cryostats in dual-phase configuration
  static bool sortAuxDetCRM(const AuxDetGeo& ad1, const AuxDetGeo& ad2)
  {

    // sort based off of GDML name, assuming ordering is encoded
    std::string ad1name = (ad1.TotalVolume())->GetName();
    std::string ad2name = (ad2.TotalVolume())->GetName();

    // assume volume name is "volAuxDet##"
    int ad1Num = atoi( ad1name.substr( 9, ad1name.size()).c_str() );
    int ad2Num = atoi( ad2name.substr( 9, ad2name.size()).c_str() );

    return ad1Num < ad2Num;

  }

  //----------------------------------------------------------------------------
  // Define sort order for cryostats in dual-phase configuration
  static bool sortAuxDetSensitiveCRM(const AuxDetSensitiveGeo& ad1, const AuxDetSensitiveGeo& ad2)
  {

    // sort based off of GDML name, assuming ordering is encoded
    std::string ad1name = (ad1.TotalVolume())->GetName();
    std::string ad2name = (ad2.TotalVolume())->GetName();

    // assume volume name is "volAuxDetSensitive##"
    int ad1Num = atoi( ad1name.substr( 9, ad1name.size()).c_str() );
    int ad2Num = atoi( ad2name.substr( 9, ad2name.size()).c_str() );

    return ad1Num < ad2Num;

  }

  //----------------------------------------------------------------------------
  // Define sort order for cryostats in dual-phase configuration
  static bool sortCryoCRM(const CryostatGeo& c1, const CryostatGeo& c2)
  {
    geo::CryostatGeo::LocalPoint_t const local{};
    auto const xyz1 = c1.toWorldCoords(local);
    auto const xyz2 = c2.toWorldCoords(local);

    return xyz1.X() < xyz2.X();
  }


  //----------------------------------------------------------------------------
  // Define sort order for tpcs in dual-phase configuration
  static bool sortTPCCRM(const TPCGeo& t1, const TPCGeo& t2)
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
  // Define sort order for planes in dual-phase configuration
  static bool sortPlaneCRM(const PlaneGeo& p1, const PlaneGeo& p2)
  {
    auto const xyz1 = p1.GetBoxCenter();
    auto const xyz2 = p2.GetBoxCenter();

    // drift direction is negative, plane number increases in drift direction
    return xyz1.X() > xyz2.X();
  }


  //----------------------------------------------------------------------------
  bool sortWireCRM(WireGeo const& w1, WireGeo const& w2){

    auto const xyz1 = w1.GetCenter();
    auto const xyz2 = w2.GetCenter();

    // for dual-phase we have to planes with wires perpendicular to each other
    // sort wires in the increasing coordinate order

    if (std::abs(xyz1.X() - xyz2.X()) < 1.0E-4 && std::abs(xyz1.Y() - xyz2.Y()) < 1.0E-4 )
      return xyz1.Z() < xyz2.Z();
    else if (std::abs(xyz1.X() - xyz2.X()) < 1.0E-4 && std::abs(xyz1.Z() - xyz2.Z()) < 1.0E-4 )
      return xyz1.Y() < xyz2.Y();
    else if (std::abs(xyz1.Y() - xyz2.Y()) < 1.0E-4 && std::abs(xyz1.Z() - xyz2.Z()) < 1.0E-4 )
      return xyz1.X() < xyz2.X();
    else { // don't know what to do
      throw cet::exception("GeoObjectSorterCRM")
        << "Uknown sorting situation for the wires in a plane\n";
    }
  } // sortWireCRM()

  //----------------------------------------------------------------------------
  GeoObjectSorterCRM::GeoObjectSorterCRM(fhicl::ParameterSet const&)
  {
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRM::SortAuxDets(std::vector<geo::AuxDetGeo> & adgeo) const
  {
    std::sort(adgeo.begin(), adgeo.end(), sortAuxDetCRM);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRM::SortAuxDetSensitive(std::vector<geo::AuxDetSensitiveGeo> & adsgeo) const
  {
    std::sort(adsgeo.begin(), adsgeo.end(), sortAuxDetSensitiveCRM);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRM::SortCryostats(std::vector<geo::CryostatGeo> & cgeo) const
  {
    std::sort(cgeo.begin(), cgeo.end(), sortCryoCRM);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRM::SortTPCs(std::vector<geo::TPCGeo>  & tgeo) const
  {
    std::sort(tgeo.begin(), tgeo.end(), sortTPCCRM);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRM::SortPlanes(std::vector<geo::PlaneGeo> & pgeo,
                                           geo::DriftDirection_t  const driftDir) const
  {
    // sort the planes to increase in drift direction
    // The drift direction has to be set before this method is called.  It is set when
    // the CryostatGeo objects are sorted by the CryostatGeo::SortSubVolumes method
    if     (driftDir == geo::kPosX) std::sort(pgeo.rbegin(), pgeo.rend(), sortPlaneCRM);
    else if(driftDir == geo::kNegX) std::sort(pgeo.begin(),  pgeo.end(),  sortPlaneCRM);
    else if(driftDir == geo::kUnknownDrift)
      throw cet::exception("TPCGeo") << "Drift direction is unknown, can't sort the planes\n";
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRM::SortWires(std::vector<geo::WireGeo> & wgeo) const
  {
    std::sort(wgeo.begin(), wgeo.end(), sortWireCRM);
  }

  //----------------------------------------------------------------------------
 void GeoObjectSorterCRM::SortOpDets         (std::vector<geo::OpDetGeo> & opdet) const {
   std::sort(opdet.begin(), opdet.end(), sortorderOpDet);
 }

}
