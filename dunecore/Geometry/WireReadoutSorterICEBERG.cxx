#include "dunecore/Geometry/WireReadoutSorterICEBERG.h"
#include "larcorealg/Geometry/WireGeo.h"

//----------------------------------------------------------------------------
bool geo::WireReadoutSorterICEBERG::compareWires(WireGeo const& w1, WireGeo const& w2) const
{
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
