#ifndef GEO_OPDETSORTER_H
#define GEO_OPDETSORTER_H


#include "larcorealg/Geometry/OpDetGeo.h"

namespace geo {

  //----------------------------------------------------------------------------
  inline bool sortorderOpDet(const OpDetGeo& t1, const OpDetGeo& t2)
  {
    auto const xyz1 = t1.GetCenter();
    auto const xyz2 = t2.GetCenter();

    if(xyz1.X()!=xyz2.X())
      return xyz1.X()>xyz2.X();
    else if(xyz1.Z()!=xyz2.Z())
      return xyz1.Z()>xyz2.Z();
    else
    return xyz1.Y()>xyz2.Y();
  }

}
#endif // GEO_OPDETSORTER_H
