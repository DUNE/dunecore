#ifndef GEO_COMPARATORS_H
#define GEO_COMPARATORS_H

#include "larcoreobj/SimpleTypesAndConstants/geo_vectors.h"

namespace geo {
  // First compare Y coordinates, then Z, then X (all increasing).
  bool compareIncreasingYZX(Point_t p1, Point_t p2);

  // First compare Z coordinates, then Y, then X (all increasing).
  bool compareIncreasingZYX(Point_t p1, Point_t p2);

  // First compare X coordinates, then Z, then Y (all decreasing).
  bool compareDecreasingXZY(Point_t p1, Point_t p2);
}

#endif // GEO_COMPARATORS_H
