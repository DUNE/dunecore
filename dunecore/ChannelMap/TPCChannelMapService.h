///////////////////////////////////////////////////////////////////////////////////////////////////
// Class:       TPCChannelMapService
// Module type: service
// File:        TPCChannelMapService.h
// Author:      Tom Junk, January 2025
//
// Meant to cover cases with HD and VD (BDE and TDE) which use the DUNE-DAQ v4.4.0 DAQEth header
// detdataformats/DAQEthHeader.hpp
///////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef TPCChannelMapService_H
#define TPCChannelMapService_H

#include "art/Framework/Core/ModuleMacros.h"
#include "art/Framework/Services/Registry/ServiceMacros.h"

#include "TPCChannelMapSP.h"

namespace dune {
  class TPCChannelMapService;
}

class dune::TPCChannelMapService {

public:
  TPCChannelMapService(fhicl::ParameterSet const& pset);
  TPCChannelMapService(fhicl::ParameterSet const& pset, art::ActivityRegistry&);

  dune::TPCChannelMapSP::TPCChanInfo_t GetChanInfoFromElectronicsIDs(unsigned int detid,
                                                                     unsigned int crate,
                                                                     unsigned int slot,
                                                                     unsigned int stream,
                                                                     unsigned int streamchan) const;

  dune::TPCChannelMapSP::TPCChanInfo_t GetChanInfoFromOfflChan(unsigned int offlchan) const;
  
  unsigned int GetNChannels() { return fTPCChanMap.GetNChannels(); };

  // crate to substitute in case the crate number is not understood.
  
  void SetSubstituteCrate(unsigned int sc) { fTPCChanMap.SetSubstituteCrate(sc); }

  unsigned int GetSubstituteCrate() { return fTPCChanMap.GetSubstituteCrate(); }
  
private:
  dune::TPCChannelMapSP fTPCChanMap;
};

DECLARE_ART_SERVICE(dune::TPCChannelMapService, LEGACY)

#endif
