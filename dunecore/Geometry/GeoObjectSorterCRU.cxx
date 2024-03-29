////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterCRU.cxx
/// \brief Interface to algorithm class for sorting VD CRUs of geo::XXXGeo objects
///        The sorting makes the assumptions on the drift direction along X axis
///
/// \version $Id:  $
/// \author vgalymov@ipnl.in2p3.fr
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/GeoObjectSorterCRU.h"
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

using std::cout;
using std::endl;

// comparison functions for sorting various geo objects
namespace geo { 
  
  namespace CRU {
    //----------------------------------------------------------------------------
    // Define sort order for auxdet in VD configuration
    static bool sortAuxDet(const AuxDetGeo& ad1, const AuxDetGeo& ad2)
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
    // Define sort order for auxsensitve det in VD configuration
    static bool sortAuxDetSensitive(const AuxDetSensitiveGeo& ad1, const AuxDetSensitiveGeo& ad2)
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
    // Define sort order for cryostats in VD configuration
    static bool sortCryo(const CryostatGeo& c1, const CryostatGeo& c2)
    {
      geo::CryostatGeo::LocalPoint_t const local{};
      auto const xyz1 = c1.toWorldCoords(local);
      auto const xyz2 = c2.toWorldCoords(local);

      return xyz1.X() < xyz2.X();
    }


    //----------------------------------------------------------------------------
    // Define sort order for tpcs (CRUs) in VD configuration
    static bool sortTPC(const TPCGeo& t1, const TPCGeo& t2)
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
    // Define sort order for planes in VD configuration
    static bool sortPlane(const PlaneGeo& p1, const PlaneGeo& p2)
    {
      auto const xyz1 = p1.GetBoxCenter();
      auto const xyz2 = p2.GetBoxCenter();

      // drift direction is negative, plane number increases in drift direction
      return xyz1.X() > xyz2.X();
    }


    //----------------------------------------------------------------------------
    bool sortWire(WireGeo const& w1, WireGeo const& w2){
      // wire sorting algorithm
      // z_low -> z_high
      // for same-z group 
      //  the sorting either from bottom (y) left (z) corner up for strip angles > pi/2
      //  and horizontal wires
      //  or from top corner to bottom otherwise
      //  we assume all wires in the plane are parallel

      //  w1 geo info
      auto center1 = w1.GetCenter();
      auto start1  = w1.GetStart();
      auto end1    = w1.GetEnd();
      auto Delta   = end1-start1;
      //double dx1   = Delta.X();
      double dy1   = Delta.Y();
      double dz1   = Delta.Z();
      
      // w2 geo info
      auto center2 = w2.GetCenter();
      
      auto CheckTol = [](double val, double tol = 1.E-4){ 
	return (std::abs( val ) < tol); 
      };
      
      if( CheckTol(dz1) ){ // wires perpendicular to z axis
	return (center1.Z() < center2.Z());
      }
      
      if( CheckTol(dy1) ){ // wires perpendicular to y axis
	return (center1.Y() < center2.Y());
      }
      
      // wires at angle with same z center
      if( CheckTol( center2.Z() - center1.Z() ) ){
	if( dz1 < 0 ){ dy1 = -dy1; } // always compare here upstream - downstream ends
	if( dy1 < 0 ){ return (center1.Y() < center2.Y()); }
	if( dy1 > 0 ){ return (center1.Y() > center2.Y()); }
      }

      // otherwise sorted in z
      return ( center1.Z() < center2.Z() );
    }

  } // namespace geo::CRU

  //----------------------------------------------------------------------------
  GeoObjectSorterCRU::GeoObjectSorterCRU(fhicl::ParameterSet const&)
  {}

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU::SortAuxDets(std::vector<geo::AuxDetGeo> & adgeo) const
  {
    std::sort(adgeo.begin(), adgeo.end(), CRU::sortAuxDet);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU::SortAuxDetSensitive(std::vector<geo::AuxDetSensitiveGeo> & adsgeo) const
  {
    std::sort(adsgeo.begin(), adsgeo.end(), CRU::sortAuxDetSensitive);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU::SortCryostats(std::vector<geo::CryostatGeo> & cgeo) const
  {
    std::sort(cgeo.begin(), cgeo.end(), CRU::sortCryo);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU::SortTPCs(std::vector<geo::TPCGeo>  & tgeo) const
  {
    std::sort(tgeo.begin(), tgeo.end(), CRU::sortTPC);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU::SortPlanes(std::vector<geo::PlaneGeo> & pgeo,
                                           geo::DriftDirection_t  const driftDir) const
  {
    // sort the planes to increase in drift direction
    // The drift direction has to be set before this method is called.  It is set when
    // the CryostatGeo objects are sorted by the CryostatGeo::SortSubVolumes method
    if     (driftDir == geo::kPosX) std::sort(pgeo.rbegin(), pgeo.rend(), CRU::sortPlane);
    else if(driftDir == geo::kNegX) std::sort(pgeo.begin(),  pgeo.end(),  CRU::sortPlane);
    else if(driftDir == geo::kUnknownDrift)
      throw cet::exception("TPCGeo") << "Drift direction is unknown, can't sort the planes\n";
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU::SortWires(std::vector<geo::WireGeo> & wgeo) const
  {
    std::sort(wgeo.begin(), wgeo.end(), CRU::sortWire);
  }

  //----------------------------------------------------------------------------
 void GeoObjectSorterCRU::SortOpDets         (std::vector<geo::OpDetGeo> & opdet) const {
   std::sort(opdet.begin(), opdet.end(), sortorderOpDet);
 }

}
