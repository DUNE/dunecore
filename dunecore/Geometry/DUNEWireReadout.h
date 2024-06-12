/**
 * @file   StandardGeometryHelper.h
 * @brief  Geometry helper service for DUNE geometries
 * @author rs@fnal.gov
 *
 * Handles DUNE-specific information for the generic Geometry service
 * within LArSoft. Derived from the WireReadout class.
 */

// Modified Oct 2016 by David Adams.
// Add param ChannelMapClass to explicitly specify the mapping class.

#ifndef DUNE_ExptGeoHelperInterface_h
#define DUNE_ExptGeoHelperInterface_h

#include "larcore/Geometry/WireReadout.h"
#include "larcorealg/Geometry/WireReadoutGeom.h"

#include <memory>

// Declaration
//
namespace dune {

class DUNEWireReadout : public geo::WireReadout {
public:

  explicit DUNEWireReadout(fhicl::ParameterSet const& pset);

private:

  geo::WireReadoutGeom const& wireReadoutGeom() const { return *fWireReadout; }

  std::unique_ptr<geo::WireReadoutGeom> fWireReadout;
};

}  // end dune namespace

DECLARE_ART_SERVICE_INTERFACE_IMPL(dune::DUNEWireReadout,
                                   geo::WireReadout,
                                   SHARED)

#endif // DUNE_ExptGeoHelperInterface_h
