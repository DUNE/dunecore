///////////////////////////////////////////////////////////////////////////////////////////////////
// Class:       TPCChannelMapService
// Module type: service
// File:        TPCChannelMapService_service.cc
// Author:      Tom Junk, January 2025
//
// Implementation of hardware-offline channel mapping reading from a file.
///////////////////////////////////////////////////////////////////////////////////////////////////

#include "TPCChannelMapService.h"
#include "messagefacility/MessageLogger/MessageLogger.h"

dune::TPCChannelMapService::TPCChannelMapService(fhicl::ParameterSet const& pset)
{

  std::string wireReadoutFile = pset.get<std::string>("FileName");

  std::string fullname;
  cet::search_path sp("FW_SEARCH_PATH");
  sp.find_file(wireReadoutFile, fullname);

  if (fullname.empty()) {
    std::cout << "Input file " << wireReadoutFile << " not found" << std::endl;
    throw cet::exception("File not found");
  }
  else
    std::cout << "TPC Channel Map: Building TPC wiremap from file " << wireReadoutFile
              << std::endl;

  fTPCChanMap.ReadMapFromFile(fullname);
}

dune::TPCChannelMapService::TPCChannelMapService(fhicl::ParameterSet const& pset,
                                                 art::ActivityRegistry&)
  : TPCChannelMapService(pset)
{}

dune::TPCChannelMapSP::TPCChanInfo_t dune::TPCChannelMapService::GetChanInfoFromElectronicsIDs(unsigned int detid,
                                                                                              unsigned int crate,
                                                                                              unsigned int slot,
                                                                                              unsigned int stream,
                                                                                              unsigned int streamchan) const
{

  return fTPCChanMap.GetChanInfoFromElectronicsIDs(detid, crate, slot, stream, streamchan);
}

dune::TPCChannelMapSP::TPCChanInfo_t dune::TPCChannelMapService::GetChanInfoFromOfflChan(unsigned int offlineChannel) const
{
  return fTPCChanMap.GetChanInfoFromOfflChan(offlineChannel);
}

DEFINE_ART_SERVICE(dune::TPCChannelMapService)
