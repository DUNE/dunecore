#include "dunecore/Geometry/WireReadoutSorterCRU.h"
#include "larcorealg/Geometry/WireGeo.h"

namespace {
  constexpr double tolerance = 1.e-4;
  auto check_tolerance = [](double val){
    return std::abs( val ) < tolerance;
  };
}

bool geo::WireReadoutSorterCRU::compareWires(geo::WireGeo const& w1,
                                             geo::WireGeo const& w2) const
{
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

  if( check_tolerance(dz1) ){ // wires perpendicular to z axis
    return center1.Z() < center2.Z();
  }

  if( check_tolerance(dy1) ){ // wires perpendicular to y axis
    return center1.Y() < center2.Y();
  }

  // wires at angle with same z center
  if( check_tolerance( center2.Z() - center1.Z() ) ){
    if( dz1 < 0 ){ dy1 = -dy1; } // always compare here upstream - downstream ends
    if( dy1 < 0 ){ return center1.Y() < center2.Y(); }
    if( dy1 > 0 ){ return center1.Y() > center2.Y(); }
  }

  // otherwise sorted in z
  return center1.Z() < center2.Z();
}
