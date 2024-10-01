///////////////////////////////////////////////////////////////////////////////////////////////////
// Class:       FDHDChannelMapService
// Module type: service
// File:        FDHDChannelMapService_service.cc
// Author:      Tom Junk, August 2022
//
// Implementation of hardware-offline channel mapping for the FD-HD module 1 detector.  Read two files,
// a channel-map file with two APAs worth of channel mapping information:  upright and inverted, and
// a crate-map file.
// This service calls methods in FDHDChannelMapSP.cxx, the service provider.  This service is meant to
// satisfy the framework interface, while the service provider does the actual work. 
///////////////////////////////////////////////////////////////////////////////////////////////////

#include "FDHDChannelMapService.h"
#include "messagefacility/MessageLogger/MessageLogger.h"

dune::FDHDChannelMapService::FDHDChannelMapService(fhicl::ParameterSet const& pset) {

  std::string wireReadoutFile = pset.get<std::string>("ChannelMapFile");
  std::string crateMapFile = pset.get<std::string>("CrateMapFile");

  std::string chanmapfullname;
  std::string cratemapfullname;
  cet::search_path sp("FW_SEARCH_PATH");
  sp.find_file(wireReadoutFile, chanmapfullname);
  sp.find_file(crateMapFile, cratemapfullname);

  if (chanmapfullname.empty()) {
    throw cet::exception("FDHDChannelMapService") << "Input channel map file " << wireReadoutFile << " not found" << std::endl;
  }
  if (cratemapfullname.empty()) {
    throw cet::exception("FDHDChannelMapService") << "Input crate map file " << crateMapFile << " not found" << std::endl;
  }
  
  MF_LOG_INFO("FDHDChannelMapService") << "Building FDHD wiremap from file " << wireReadoutFile << " and crate map: " << crateMapFile << std::endl;

  fHDChanMap.ReadMapFromFiles(chanmapfullname,cratemapfullname);
}

dune::FDHDChannelMapService::FDHDChannelMapService(fhicl::ParameterSet const& pset, art::ActivityRegistry&) : FDHDChannelMapService(pset) {
}

dune::FDHDChannelMapSP::HDChanInfo_t dune::FDHDChannelMapService::GetChanInfoFromWIBElements(
    unsigned int crate,
    unsigned int slot,
    unsigned int link,
    unsigned int wibframechan ) const {

  return fHDChanMap.GetChanInfoFromWIBElements(crate,slot,link,wibframechan);
}


dune::FDHDChannelMapSP::HDChanInfo_t dune::FDHDChannelMapService::GetChanInfoFromOfflChan(unsigned int offlineChannel) const {

  return fHDChanMap.GetChanInfoFromOfflChan(offlineChannel);

}


DEFINE_ART_SERVICE(dune::FDHDChannelMapService)
