// GeoRopChannelGroupService.h

// David Adams
// October 2016
//
// ROP channel groups extracted from larsoft geometry.

#ifndef GeoRopChannelGroupService_H
#define GeoRopChannelGroupService_H

#include "dunecore/DuneInterface/Service/ChannelGroupService.h"
#include "art/Framework/Services/Registry/ServiceHandle.h"
#include "larcore/Geometry/Geometry.h"
#include "larcore/Geometry/WireReadout.h"

class GeoRopChannelGroupService : public ChannelGroupService {

public:

  // Ctor.
  GeoRopChannelGroupService(fhicl::ParameterSet const& pset);

  // Dtor.
  ~GeoRopChannelGroupService() =default;

  // Return the # groups.
  Index size() const;

  // Return a group name.
  Name name(Index igrp) const;

  // Return a group.
  const ChannelVector& channels(Index igrp) const;

  // Print parameters.
  std::ostream& print(std::ostream& out =std::cout, std::string prefix ="") const;

private:

  typedef std::vector<Name> NameVector;
  typedef std::vector<ChannelVector> ChannelVectorVector;
 
  art::ServiceHandle<geo::Geometry> m_geometry;
  geo::WireReadoutGeom const* m_wireReadout = &art::ServiceHandle<geo::WireReadout>()->Get();

  Index m_size;
  NameVector m_names;
  ChannelVectorVector m_chanvecs;

};

DECLARE_ART_SERVICE_INTERFACE_IMPL(GeoRopChannelGroupService, ChannelGroupService, LEGACY)

#endif
