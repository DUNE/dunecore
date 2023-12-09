#include "dunecore/Geometry/AuxDetGeoObjectSorter35.h"
#include "larcorealg/Geometry/AuxDetGeo.h"
#include "larcorealg/Geometry/AuxDetSensitiveGeo.h"

#include <cmath> // for std::abs

namespace geo{

  AuxDetGeoObjectSorter35::AuxDetGeoObjectSorter35(fhicl::ParameterSet const&)
  {}

  bool AuxDetGeoObjectSorter35::compareAuxDets(AuxDetGeo const& ad1, AuxDetGeo const& ad2) const
  {
    auto const xyz1 = ad1.GetCenter();
    auto const xyz2 = ad2.GetCenter();

    // AuxDet groups in 35t may have a couple-cm difference in vertical pos
    // Adjusting for this messes up sorting between the top layers of AuxDets
    float VertEps(0);
    if     ( strncmp( (ad1.TotalVolume())->GetName(), "volAuxDetTrap", 13) == 0 ) VertEps = 13;
    else if( strncmp( (ad1.TotalVolume())->GetName(), "volAuxDetBox",  12) == 0 ) VertEps = 1;

    // First sort all AuxDets into same-y groups
    if( xyz1.Y() < xyz2.Y() && xyz2.Y()-xyz1.Y() >= VertEps ) return true;

    // Within a same-y group, sort AuxDets into same-x groups
    if( std::abs(xyz2.Y()-xyz1.Y()) < VertEps && xyz1.X() < xyz2.X()) return true;

    // Within a same-x, same-y group, sort AuxDets according to z
    if(xyz1.X() == xyz2.X() && std::abs(xyz2.Y()-xyz1.Y()) < VertEps && xyz1.Z() < xyz2.Z()) return true;

    // none of those are true, so return false
    return false;
  }

  //----------------------------------------------------------------------------
  bool AuxDetGeoObjectSorter35::compareAuxDetSensitives(AuxDetSensitiveGeo const& ad1,
                                                        AuxDetSensitiveGeo const& ad2) const
  {
    auto const xyz1 = ad1.GetCenter();
    auto const xyz2 = ad2.GetCenter();

    // AuxDet groups in 35t may have a couple-cm difference in vertical pos
    // Adjusting for this messes up sorting between the top layers of AuxDets
    float VertEps(0);
    if     ( strncmp( (ad1.TotalVolume())->GetName(), "volAuxDetTrapSensitive", 22) == 0 ) VertEps = 13;
    else if( strncmp( (ad1.TotalVolume())->GetName(), "volAuxDetBoxSensitive",  21) == 0 ) VertEps = 1;

    // First sort all AuxDets into same-y groups
    if( xyz1.Y() < xyz2.Y() && xyz2.Y()-xyz1.Y() >= VertEps ) return true;

    // Within a same-y group, sort AuxDets into same-x groups
    if( std::abs(xyz2.Y()-xyz1.Y()) < VertEps && xyz1.X() < xyz2.X()) return true;

    // Within a same-x, same-y group, sort AuxDets according to z
    if(xyz1.X() == xyz2.X() && std::abs(xyz2.Y()-xyz1.Y()) < VertEps && xyz1.Z() < xyz2.Z()) return true;

    // none of those are true, so return false
    return false;
  }

}
