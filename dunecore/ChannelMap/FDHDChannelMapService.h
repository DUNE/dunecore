///////////////////////////////////////////////////////////////////////////////////////////////////
// Class:       FDHDChannelMapService
// Module type: service
// File:        FDHDChannelMapService.h
// Author:      Tom Junk, August 2022
//
// Implementation of hardware-offline channel mapping for the FD-HD module 1 detector.  Read two files,
// a channel-map file with two APAs worth of channel mapping information:  upright and inverted, and
// a crate-map file.
// This service calls methods in FDHDChannelMapSP.cxx, the service provider.  This service is meant to
// satisfy the frameork interface, while the service provider 
///////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef FDHDChannelMapService_H
#define FDHDChannelMapService_H

#include "art/Framework/Core/ModuleMacros.h"
#include "art/Framework/Services/Registry/ServiceMacros.h"

#include "FDHDChannelMapSP.h"

namespace dune {
  class FDHDChannelMapService;
}

class dune::FDHDChannelMapService {

public:

  FDHDChannelMapService(fhicl::ParameterSet const& pset);
  FDHDChannelMapService(fhicl::ParameterSet const& pset, art::ActivityRegistry&);

  dune::FDHDChannelMapSP::HDChanInfo_t GetChanInfoFromWIBElements(
   unsigned int crate,
   unsigned int slot,
   unsigned int link,
   unsigned int wibframechan) const;

  dune::FDHDChannelMapSP::HDChanInfo_t GetChanInfoFromOfflChan(unsigned int offlchan) const;

  unsigned int getNChans() { return fHDChanMap.getNChans(); }

private:

  dune::FDHDChannelMapSP fHDChanMap;

};

DECLARE_ART_SERVICE(dune::FDHDChannelMapService, LEGACY)

#endif
