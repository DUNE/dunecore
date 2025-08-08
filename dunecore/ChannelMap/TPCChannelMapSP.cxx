///////////////////////////////////////////////////////////////////////////////////////////////////
// Class:       TPCChannelMapSP
// Module type: standalone algorithm
// File:        TPCChannelMapSP.cxx
// Author:      Tom Junk, Jan 2025
//
// Implementation of hardware-offline channel mapping reading from a file.
///////////////////////////////////////////////////////////////////////////////////////////////////

#include "TPCChannelMapSP.h"

#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>

dune::TPCChannelMapSP::TPCChannelMapSP() {
  fSubstituteCrate = 1;
  fNChans = 0;
}

void dune::TPCChannelMapSP::ReadMapFromFile(std::string& fullname)
{
  fNChans = 0;
  
  std::ifstream inFile(fullname, std::ios::in);
  std::string line;

  while (std::getline(inFile, line)) {
    std::stringstream linestream(line);

    TPCChanInfo_t chanInfo;
    linestream >>
      chanInfo.offlchan >>
      chanInfo.detid >>
      chanInfo.detelement >>
      chanInfo.crate >>
      chanInfo.slot >>
      chanInfo.stream >>
      chanInfo.streamchan >>
      chanInfo.plane >>
      chanInfo.chan_in_plane >>
      chanInfo.femb >>
      chanInfo.asic >> 
      chanInfo.asicchan;

    chanInfo.valid = true;
    ++fNChans;

    // fill maps.

    check_offline_channel(chanInfo.offlchan);

    auto hashval = make_hash(chanInfo.detid,chanInfo.crate,chanInfo.slot,chanInfo.stream,chanInfo.streamchan);
    if ( DetToChanInfo.find(hashval) != DetToChanInfo.end() ){
      std::cout << "TPCChannelMapSP: duplicate electronics channel found.  detid, crate, slot, stream, streamchan: " <<
	chanInfo.detid << " " <<
	chanInfo.crate << " " <<
	chanInfo.slot << " " <<
	chanInfo.stream << " " <<
	chanInfo.streamchan << std::endl;
      throw std::range_error("Duplicate Electronics ID");
    }
    DetToChanInfo[hashval] = chanInfo;

    if ( OfflToChanInfo.find(chanInfo.offlchan) != OfflToChanInfo.end() ) {
      std::cout << "TPCChannelMapSP: duplicate offline channel found: " <<
	chanInfo.offlchan << std::endl;
      throw std::range_error("Duplicate Offline TPC Channel ID");      
    }
    OfflToChanInfo[chanInfo.offlchan] = chanInfo;
  }
  inFile.close();
}

dune::TPCChannelMapSP::TPCChanInfo_t dune::TPCChannelMapSP::GetChanInfoFromElectronicsIDs(
                                                                                          unsigned int detid,
                                                                                          unsigned int crate,
                                                                                          unsigned int slot,
                                                                                          unsigned int stream,
                                                                                          unsigned int streamchan) const
{
  size_t h = make_hash(detid,crate,slot,stream,streamchan);
  auto ret = DetToChanInfo.find(h); 
  if (ret == DetToChanInfo.end())
    {
      h = make_hash(detid,fSubstituteCrate,slot,stream,streamchan);
      ret = DetToChanInfo.find(h);
      if (ret == DetToChanInfo.end())
	{
          TPCChanInfo_t badInfo = {};
          badInfo.valid = false;
          return badInfo;
	}
    }
  return ret->second;
}

dune::TPCChannelMapSP::TPCChanInfo_t dune::TPCChannelMapSP::GetChanInfoFromOfflChan(
                                                                                    unsigned int offlineChannel) const
{
  auto ci = OfflToChanInfo.find(offlineChannel);
  if (ci == OfflToChanInfo.end()) {
    TPCChanInfo_t badInfo = {};
    badInfo.valid = false;
    return badInfo;
  }
  return ci->second;
}

size_t dune::TPCChannelMapSP::make_hash( unsigned int detid,   //6 bits
                  unsigned int crate,   //10 bits
                  unsigned int slot,    //4 bits
                  unsigned int stream,  //8 bits
                  unsigned int streamch //12 bits
					 ) const
{
  size_t hashval = (((size_t)detid & 0x3f)<<34);
  hashval ^=((crate & 0x3ff)<<24);
  hashval ^=((slot & 0xf)<<20);
  hashval ^=((stream & 0xff)<<12);
  hashval ^=(streamch & 0xfff);
  return hashval;
}
