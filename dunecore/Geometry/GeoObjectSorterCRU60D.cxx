////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterCRU60Dx.cxx
/// \brief Interface to algorithm class for sorting VD CRUs of geo::XXXGeo objects
///        this targets the final 60D anode geometry
///
/// \version $Id:  $
/// \author vgalymov@ipnl.in2p3.fr
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/GeoObjectSorterCRU60D.h"
#include "dunecore/Geometry/OpDetSorter.h"
#include "larcorealg/Geometry/AuxDetGeo.h"
#include "larcorealg/Geometry/AuxDetSensitiveGeo.h"
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/TPCGeo.h"
#include "larcorealg/Geometry/PlaneGeo.h"
#include "larcorealg/Geometry/WireGeo.h"

#include "canvas/Utilities/Exception.h"
#include "messagefacility/MessageLogger/MessageLogger.h"
#include "fhiclcpp/ParameterSet.h"

#include <array>
#include <string>
#include <cmath> // std::abs()
#include <utility>

using std::cout;
using std::endl;


namespace {
  // Tolerance when comparing distances in geometry:
  static constexpr double DistanceTol = 0.001; // cm

  auto element(geo::Point_t const& point, short int i)
  {
    switch (std::abs(i)) {
    case 0: return point.X();
    case 1: return point.Y();
    case 2: return point.Z();
    }
    throw art::Exception{art::errors::LogicError}
      << "Unsupported index provided (" << i << ") for three-dimensional point.";
  }

} // local namespace

// comparison functions for sorting various geo objects
namespace geo {

  namespace CRU60D {
    short int TPCDriftAxis = 0;

    short int getDriftCoord(){
      if( TPCDriftAxis == 0 ){
        MF_LOG_WARNING("geo::CRU60D::getDriftCoord") <<
          " Cannot retrieve drift coordinate. Defaulting to X axis";
        return 0;
      }

      short int axis = TPCDriftAxis - 1;
      if( axis >= 2 ){
         throw cet::exception("geo::CRU60D::getDriftCoord")
           << "Drift coordinate index '" << axis <<"' is bad \n";
      }

      return axis;
    }


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
    // Define sort order for TPC volumes (CRU60D) in VD configuration
    static bool sortTPC(const TPCGeo& t1, const TPCGeo& t2)
    {
      auto const xyz1 = t1.GetCenter();
      auto const xyz2 = t2.GetCenter();

      // try to get drift coord index
      short int dc = geo::CRU60D::getDriftCoord();


      // sort TPCs in drift volumes
      auto const [d1, d2] = std::make_pair(element(xyz1, dc), element(xyz2, dc));
      if(std::abs(d1 - d2) > DistanceTol)
        return d1 < d2;

      // First sort all TPCs into same-z groups
      if(std::abs(xyz1.Z()-xyz2.Z()) > DistanceTol)
        return xyz1.Z() < xyz2.Z();

      // Within a same-z group, sort TPCs into same-y/x groups
      int other = (dc == 0)?1:0;
      if (other==1) return xyz1.Y() < xyz2.Y();
      else if (other==0) return xyz1.X() > xyz2.X();
      else {throw cet::exception("TPCGeo") << "Drift direction detected is non-X and non-Y.\n";}
    }

    // Sort TPC for ProtoDUNE VD
    static bool sortTPCPDVD(const TPCGeo& t1, const TPCGeo& t2)
    {
      auto const xyz1 = t1.GetCenter();
      auto const xyz2 = t2.GetCenter();

      // try to get drift coord index
      short int dc = geo::CRU60D::getDriftCoord();


      // sort TPCs in drift volumes
      auto const [d1, d2] = std::make_pair(element(xyz1, dc), element(xyz2, dc));
      if(std::abs(d1 - d2) > DistanceTol)
        return d1 < d2;

      if (xyz1.Y() * xyz2.Y() < 0)
        return xyz1.Y() < xyz2.Y();
      else {
        if (std::abs(xyz1.Z() - xyz2.Z()) > DistanceTol )
          return xyz1.Z() < xyz2.Z();
        return xyz1.Y() < xyz2.Y();
      }
    }


    //----------------------------------------------------------------------------
    // Define sort order for planes in VD configuration
    static bool sortPlane(const PlaneGeo& p1, const PlaneGeo& p2)
    {
      auto const xyz1 = p1.GetBoxCenter();
      auto const xyz2 = p2.GetBoxCenter();

      // try to get drift coord index
      short int dc = geo::CRU60D::getDriftCoord();

      // drift direction is negative, plane number increases in drift direction
      return element(xyz1, dc) > element(xyz2, dc);
    }


    //----------------------------------------------------------------------------
    bool sortWireDX(WireGeo const& w1, WireGeo const& w2){ // X is drift coordinate
      // wire sorting algorithm

      //  w1 geo info
      auto center1 = w1.GetCenter();
      auto start1  = w1.GetStart();
      auto end1    = w1.GetEnd();
      auto Delta   = end1-start1;
      //double dx1   = Delta.X();
      double dy1   = Delta.Y();
      double dz1   = Delta.Z();
      double thtz  = w1.ThetaZ();

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

      //cout<<"w1 " << w1.WireInfo("  ", 3)
      //<<" half length " << w1.HalfL()
      //<<" thetaZ = "<<thtz<<endl;

      // u-view
      if( thtz > 1.57 ) {

        // wires at angle with same z center
        if( CheckTol( center2.Z() - center1.Z() ) ){
          if( dz1 < 0 ){ dy1 = -dy1; } // always compare here upstream - downstream ends
          if( dy1 < 0 ){ return (center1.Y() < center2.Y()); }
          if( dy1 > 0 ){ return (center1.Y() > center2.Y()); }
        }

        // otherwise sorted in z
        return ( center1.Z() < center2.Z() );
      } // u view

      // v view
      // wires at angle with same z center
      if( CheckTol( center2.Z() - center1.Z() ) ){
        if( dz1 < 0 ){ dy1 = -dy1; } // always compare here upstream - downstream ends
        if( dy1 < 0 ){ return (center1.Y() > center2.Y()); }
        if( dy1 > 0 ){ return (center1.Y() < center2.Y()); }
      }

      // otherwise sorted in -z
      return ( center1.Z() > center2.Z() );
    }

    //
    bool sortWireDY(WireGeo const& w1, WireGeo const& w2){ // Y is drift coordinate
      // wire sorting algorithm

      //  w1 geo info
      auto center1 = w1.GetCenter();
      auto start1  = w1.GetStart();
      auto end1    = w1.GetEnd();
      auto Delta   = end1-start1;
      double dx1   = Delta.X();
      double dz1   = Delta.Z();
      double thtz  = w1.ThetaZ();

      // w2 geo info
      auto center2 = w2.GetCenter();

      auto CheckTol = [](double val, double tol = 1.E-4){
        return (std::abs( val ) < tol);
      };

      if( CheckTol(dz1) ){ // wires perpendicular to z axis
        return (center1.Z() < center2.Z());
      }

      if( CheckTol(dx1) ){ // wires perpendicular to x axis
        return (center1.X() < center2.X());
      }

      //cout<<"w1 " << w1.WireInfo("  ", 3)
      //<<" half length " << w1.HalfL()
      //<<" thetaZ = "<<thtz<<endl;

      // u-view
      if( thtz > 1.57 ) {

        // wires at angle with same z center
        if( CheckTol( center2.Z() - center1.Z() ) ){
          if( dz1 < 0 ){ dx1 = -dx1; } // always compare here upstream - downstream ends
          if( dx1 < 0 ){ return (center1.X() < center2.X()); }
          if( dx1 > 0 ){ return (center1.X() > center2.X()); }
        }

        // otherwise sorted in z
        return ( center1.Z() < center2.Z() );
      } // u view

      // v view
      // wires at angle with same z center
      if( CheckTol( center2.Z() - center1.Z() ) ){
        if( dz1 < 0 ){ dx1 = -dx1; } // always compare here upstream - downstream ends
        if( dx1 < 0 ){ return (center1.X() > center2.X()); }
        if( dx1 > 0 ){ return (center1.X() < center2.X()); }
      }

      // otherwise sorted in -z
      return ( center1.Z() > center2.Z() );
    }

    bool sortWire(WireGeo const& w1, WireGeo const& w2){
      short int dc = geo::CRU60D::getDriftCoord();
      if( dc == 1 ) return sortWireDY( w1, w2 );
      return sortWireDX( w1, w2 );
    }

  } // namespace geo::CRU60D

  //----------------------------------------------------------------------------
  GeoObjectSorterCRU60D::GeoObjectSorterCRU60D(fhicl::ParameterSet const& pset)
    : fSortTPCPDVD(pset.get<bool>("SortTPCPDVD", false)){}

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU60D::SortAuxDets(std::vector<geo::AuxDetGeo> & adgeo) const
  {
    std::sort(adgeo.begin(), adgeo.end(), CRU60D::sortAuxDet);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU60D::SortAuxDetSensitive(std::vector<geo::AuxDetSensitiveGeo> & adsgeo) const
  {
    std::sort(adsgeo.begin(), adsgeo.end(), CRU60D::sortAuxDetSensitive);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU60D::SortCryostats(std::vector<geo::CryostatGeo> & cgeo) const
  {
    std::sort(cgeo.begin(), cgeo.end(), CRU60D::sortCryo);
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU60D::SortTPCs(std::vector<geo::TPCGeo>  & tgeo) const
  {
    // attempt to get TPC drift direction: 1 - X, 2 - Y, 3 - Z
    if( !geo::CRU60D::TPCDriftAxis ){
      geo::CRU60D::TPCDriftAxis = std::abs((*tgeo.begin()).DetectDriftDirection());
      MF_LOG_DEBUG("GeoObjectSorterCRU60D")
        <<" Retrieved drift axis "<<geo::CRU60D::TPCDriftAxis;
    }
    if (fSortTPCPDVD) std::sort(tgeo.begin(), tgeo.end(), CRU60D::sortTPCPDVD);
    else              std::sort(tgeo.begin(), tgeo.end(), CRU60D::sortTPC);

  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU60D::SortPlanes(std::vector<geo::PlaneGeo> & pgeo,
                                           geo::DriftDirection_t  const driftDir) const
  {
    // sort the planes to increase in drift direction
    // The drift direction has to be set before this method is called.  It is set when
    // the CryostatGeo objects are sorted by the CryostatGeo::SortSubVolumes method
    if     (driftDir == geo::kPosX) std::sort(pgeo.rbegin(), pgeo.rend(), CRU60D::sortPlane);
    else if(driftDir == geo::kNegX) std::sort(pgeo.begin(),  pgeo.end(),  CRU60D::sortPlane);
    else if(driftDir == geo::kUnknownDrift)
      throw cet::exception("TPCGeo") << "Drift direction is unknown, can't sort the planes\n";
  }

  //----------------------------------------------------------------------------
  void GeoObjectSorterCRU60D::SortWires(std::vector<geo::WireGeo> & wgeo) const
  {
    std::sort(wgeo.begin(), wgeo.end(), CRU60D::sortWire);
  }

  //----------------------------------------------------------------------------
 void GeoObjectSorterCRU60D::SortOpDets         (std::vector<geo::OpDetGeo> & opdet) const {
   std::sort(opdet.begin(), opdet.end(), sortorderOpDet);
 }

}
