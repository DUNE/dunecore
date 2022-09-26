///////////////////////////////////////////////////////////////////////////////////////////////////
// Class:       FDHDChannelMapSP
// Module type: standalone algorithm
// File:        FDHDChannelMapSP.cxx
// Author:      Tom Junk, August 2022
//
// Implementation of hardware-offline channel mapping reading from two files, one containing
// the channel maps for two APAs (inverted and upright), and one containing the crate numbering
// scheme.
//
// The SP in the class and file name means "Service Provider"
///////////////////////////////////////////////////////////////////////////////////////////////////

#include "FDHDChannelMapSP.h"

#include <iostream>
#include <fstream>
#include <sstream>
#include <stdlib.h>

// so far, nothing needs to be done in the constructor

dune::FDHDChannelMapSP::FDHDChannelMapSP()
{
}

void dune::FDHDChannelMapSP::ReadMapFromFiles(const std::string &chanmapfile, const std::string &cratemapfile)
{
  std::ifstream inFile(chanmapfile, std::ios::in);
  std::string line;

  while (std::getline(inFile,line)) {
    std::stringstream linestream(line);

    HDChanInfo_t chanInfo;
    linestream 
      >> chanInfo.offlchan 
      >> chanInfo.upright
      >> chanInfo.wib 
      >> chanInfo.link 
      >> chanInfo.femb_on_link 
      >> chanInfo.cebchan 
      >> chanInfo.plane 
      >> chanInfo.chan_in_plane 
      >> chanInfo.femb 
      >> chanInfo.asic 
      >> chanInfo.asicchan
      >> chanInfo.wibframechan; 

    // internal information lacks crate number and APA name because it is meant to
    // be generic for all APAs.

    chanInfo.crate = 0;
    chanInfo.APAName = "";

    // fill maps.

    check_offline_channel(chanInfo.offlchan);

    DetToChanInfo[chanInfo.upright][chanInfo.wib][chanInfo.link][chanInfo.wibframechan] = chanInfo;
    if (chanInfo.upright)
      {
        OfflToChanInfo_Upright[chanInfo.offlchan] = chanInfo;
      }
    else
      {
        OfflToChanInfo_Inverted[chanInfo.offlchan] = chanInfo;
      }
  }
  inFile.close();

  std::ifstream inFile2(cratemapfile, std::ios::in);
  while (std::getline(inFile2,line)) {
    std::string apaname;
    unsigned int cratenum;
    std::stringstream linestream(line);
    linestream >> cratenum >> apaname;
    if (fAPANameFromCrate.find(cratenum) != fAPANameFromCrate.end())
      {
	throw std::invalid_argument("FDHDChannelMapSP: Duplicate crate number in cratemap file\n"); 
      }
    fAPANameFromCrate[cratenum] = apaname;
  }
  inFile2.close();

  // fill maps of crates and TPCSets

  for (auto &ani : fAPANameFromCrate )
    {
      auto crate = ani.first;
      std::string &aname = ani.second;
      unsigned int upright=0;
      if (aname.find('U') != std::string::npos)
	{
	  upright = 1;
	}
      fUprightFromCrate[crate] = upright;

      unsigned int TPCSet = 0;
      std::string columnstring = aname.substr(5,2);
      unsigned int column = atoi(columnstring.c_str());
      unsigned int nms = 0;   //   0=north, 1=middle,  2=south
      if (aname.find('N') != std::string::npos) nms = 0;
      if (aname.find('M') != std::string::npos) nms = 1;
      if (aname.find('S') != std::string::npos) nms = 2;

      TPCSet = 6*(column - 1) + 3*upright + nms;
      fCrateFromTPCSet[TPCSet] = crate;
      fTPCSetFromCrate[crate] = TPCSet;
    }
}

dune::FDHDChannelMapSP::HDChanInfo_t dune::FDHDChannelMapSP::GetChanInfoFromWIBElements(
    unsigned int crate,
    unsigned int slot,
    unsigned int link,
    unsigned int wibframechan ) const {

  unsigned int wib = slot + 1;

  HDChanInfo_t badInfo = {};
  badInfo.valid = false;

// ununderstood crates are mapped to the first crate in the APA name map

  auto scrate = crate;   // substitute crate
  auto upri = fUprightFromCrate.find(crate);
  if (upri == fUprightFromCrate.end())
    {
      scrate = fAPANameFromCrate.begin()->first;  
    }
  auto upright = upri->second;
  auto TPCSi = fTPCSetFromCrate.find(scrate);
  if (TPCSi == fTPCSetFromCrate.end())
    {
      throw std::invalid_argument("FDHDChannelMapSP: Logic error in TPCSet from crate\n");
    }
  auto tpcset = TPCSi->second;

  auto fm1 = DetToChanInfo.find(upright);  // this should never fail as we have a substitute crate
  auto& m1 = fm1->second;

  auto fm2 = m1.find(wib);
  if (fm2 == m1.end()) return badInfo;
  auto& m2 = fm2->second;

  auto fm3 = m2.find(link);
  if (fm3 == m2.end()) return badInfo;
  auto& m3 = fm3->second;

  auto fm4 = m3.find(wibframechan);
  if (fm4 == m3.end()) return badInfo;

  auto outputinfo = fm4->second;
  outputinfo.offlchan += tpcset * 2560;
  outputinfo.crate = scrate;
  auto aci = fAPANameFromCrate.find(scrate);
  outputinfo.APAName = aci->second;
  outputinfo.upright = upright;

  return outputinfo;

}


dune::FDHDChannelMapSP::HDChanInfo_t dune::FDHDChannelMapSP::GetChanInfoFromOfflChan(unsigned int offlineChannel) const {

  check_offline_channel(offlineChannel);

  HDChanInfo_t outputinfo;
  HDChanInfo_t internalinfo;

  unsigned int tpcset = offlineChannel / 2560;
  auto ci = fCrateFromTPCSet.find(tpcset);
  unsigned int crate = ci->second;
  auto ui = fUprightFromCrate.find(crate);
  unsigned int upright = ui->second;
  if (upright)
    {
       auto ci = OfflToChanInfo_Upright.find(offlineChannel % 2560);
       internalinfo = ci->second;
    }
  else
    {
       auto ci = OfflToChanInfo_Inverted.find(offlineChannel % 2560);
       internalinfo = ci->second;
    }

  outputinfo.offlchan = offlineChannel;
  outputinfo.crate = crate;
  auto aci = fAPANameFromCrate.find(crate);
  outputinfo.APAName = aci->second;
  outputinfo.upright = upright;
  outputinfo.wib = internalinfo.wib;
  outputinfo.link = internalinfo.link;
  outputinfo.femb_on_link = internalinfo.femb_on_link;
  outputinfo.cebchan = internalinfo.cebchan;
  outputinfo.plane = internalinfo.plane;
  outputinfo.chan_in_plane = internalinfo.chan_in_plane;
  outputinfo.femb = internalinfo.femb;
  outputinfo.asic = internalinfo.asic;
  outputinfo.asicchan = internalinfo.asicchan;
  outputinfo.wibframechan = internalinfo.wibframechan;
  outputinfo.valid = true;

  return outputinfo;
}
