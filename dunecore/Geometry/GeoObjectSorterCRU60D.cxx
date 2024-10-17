////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorterCRU60Dx.cxx
/// \brief Interface to algorithm class for sorting VD CRUs of geo::XXXGeo objects
///        this targets the final 60D anode geometry
///
/// \version $Id:  $
/// \author vgalymov@ipnl.in2p3.fr
////////////////////////////////////////////////////////////////////////

#include "dunecore/Geometry/GeoObjectSorterCRU60D.h"
#include "dunecore/Geometry/Comparators.h"
#include "larcorealg/Geometry/CryostatGeo.h"
#include "larcorealg/Geometry/TPCGeo.h"

#include "canvas/Utilities/Exception.h"
#include "fhiclcpp/ParameterSet.h"

#include <cmath> // std::abs()
#include <utility>

namespace {
  // Tolerance when comparing distances in geometry:
  static constexpr double DistanceTol = 0.001; // cm

  auto element(geo::Point_t const& point, geo::Coordinate const coord)
  {
    switch (coord) {
    case geo::Coordinate::X: return point.X();
    case geo::Coordinate::Y: return point.Y();
    case geo::Coordinate::Z: return point.Z();
    }
    throw art::Exception{art::errors::LogicError}
      << "Unsupported coordinate provided for three-dimensional point.";
  }

    //----------------------------------------------------------------------------
    // Define sort order for TPC volumes (CRU60D) in VD configuration
  bool compareTPC(geo::TPCGeo const& t1, geo::TPCGeo const& t2, geo::Coordinate const dc)
    {
      auto const xyz1 = t1.GetCenter();
      auto const xyz2 = t2.GetCenter();

      // sort TPCs in drift volumes
      auto const [d1, d2] = std::make_pair(element(xyz1, dc), element(xyz2, dc));
      if(std::abs(d1 - d2) > DistanceTol)
        return d1 < d2;

      // First sort all TPCs into same-z groups
      if(std::abs(xyz1.Z()-xyz2.Z()) > DistanceTol)
        return xyz1.Z() < xyz2.Z();

      // Within a same-z group, sort TPCs into same-y/x groups
      if (dc == geo::Coordinate::X) return xyz1.Y() < xyz2.Y();
      return xyz1.X() > xyz2.X();
    }

    // Sort TPC for ProtoDUNE VD
  bool compareTPCPDVD(geo::TPCGeo const& t1, geo::TPCGeo const& t2, geo::Coordinate const dc)
    {
      auto const xyz1 = t1.GetCenter();
      auto const xyz2 = t2.GetCenter();

      // sort TPCs in drift volumes
      auto const [d1, d2] = std::make_pair(element(xyz1, dc), element(xyz2, dc));
      if(std::abs(d1 - d2) > DistanceTol)
        return d1 < d2;

    if (dc == geo::Coordinate::X) {
        if (xyz1.Y() * xyz2.Y() < 0)
          return xyz1.Y() < xyz2.Y();
        else {
          if (std::abs(xyz1.Z() - xyz2.Z()) > DistanceTol )
            return xyz1.Z() < xyz2.Z();
          return xyz1.Y() < xyz2.Y();
        }
      }
      else {
        if (xyz1.X() * xyz2.X() < 0)
          return xyz1.X() > xyz2.X();
        else {
          if (std::abs(xyz1.Z() - xyz2.Z()) > DistanceTol )
            return xyz1.Z() < xyz2.Z();
          return xyz1.X() > xyz2.X();
        }
      }
    }

} // anon.namespace

namespace geo {

  //----------------------------------------------------------------------------
  GeoObjectSorterCRU60D::GeoObjectSorterCRU60D(fhicl::ParameterSet const& pset)
    : fSortTPCPDVD(pset.get<bool>("SortTPCPDVD", false)){}

  //----------------------------------------------------------------------------
  bool GeoObjectSorterCRU60D::compareCryostats(CryostatGeo const& c1, CryostatGeo const& c2) const
  {
    geo::CryostatGeo::LocalPoint_t const local{};
    auto const xyz1 = c1.toWorldCoords(local);
    auto const xyz2 = c2.toWorldCoords(local);

    return xyz1.X() < xyz2.X();
  }

  //----------------------------------------------------------------------------
  bool GeoObjectSorterCRU60D::compareTPCs(TPCGeo const& t1, TPCGeo const& t2) const
  {
    auto const dc = t1.DriftAxisWithSign().coordinate;
    return fSortTPCPDVD ? compareTPCPDVD(t1, t2, dc) : compareTPC(t1, t2, dc);
  }

  //----------------------------------------------------------------------------
  bool GeoObjectSorterCRU60D::compareOpDets(OpDetGeo const& t1, OpDetGeo const& t2) const
  {
    return compareDecreasingXZY(t1.GetCenter(), t2.GetCenter());
 }

}
