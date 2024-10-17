#include "dunecore/Geometry/Comparators.h"

bool geo::compareIncreasingYZX(Point_t const p1, Point_t const p2)
{
  if (p1.Y() != p2.Y()) return p1.Y() < p2.Y();
  if (p1.Z() != p2.Z()) return p1.Z() < p2.Z();
  return p1.X() < p2.X();
}

bool geo::compareIncreasingZYX(Point_t const p1, Point_t const p2)
{
  if (p1.Z() != p2.Z()) return p1.Z() < p2.Z();
  if (p1.Y() != p2.Y()) return p1.Y() < p2.Y();
  return p1.X() < p2.X();
}

bool geo::compareDecreasingXZY(Point_t const p1, Point_t const p2)
{
  if (p1.X() != p2.X()) return p1.X() > p2.X();
  if (p1.Z() != p2.Z()) return p1.Z() > p2.Z();
  return p1.Y() > p2.Y();
}
