////////////////////////////////////////////////////////////////////////
/// \file  GeoObjectSorter35.h
/// \brief Interface to algorithm class for standard sorting of geo::XXXGeo objects
///
/// \version $Id:  $
/// \author  brebel@fnal.gov
////////////////////////////////////////////////////////////////////////
#ifndef GEO_AUXDETGEOOBJECTSORTER35_H
#define GEO_AUXDETGEOOBJECTSORTER35_H

#include "fhiclcpp/fwd.h"
#include "larcorealg/Geometry/AuxDetGeoObjectSorter.h"

namespace geo{

  class AuxDetGeoObjectSorter35 : public AuxDetGeoObjectSorter {
  public:
    explicit AuxDetGeoObjectSorter35(fhicl::ParameterSet const&);

  private:
    bool compareAuxDets(AuxDetGeo const& ad1, AuxDetGeo const& ad2) const override;
    bool compareAuxDetSensitives(AuxDetSensitiveGeo const& ad1,
                                 AuxDetSensitiveGeo const& ad2) const override;
  };

}

#endif // GEO_AUXDETGEOOBJECTSORTER35_H
