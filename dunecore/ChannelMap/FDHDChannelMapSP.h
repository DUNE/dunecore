///////////////////////////////////////////////////////////////////////////////////////////////////
// Class:       FDHDChannelMapSP
// Module type: algorithm
// File:        FDHDChannelMapSP.h
// Author:      Tom Junk, August 2022
//
// Implementation of hardware-offline channel mapping reading from a file.
// art-independent class  
// The SP in the class and file anme means "Service Provider"
// DUNE Far Detector Module 1 Horizontal Drift APA wire to offline channel map
///////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef FDHDChannelMapSP_H
#define FDHDChannelMapSP_H

#include <unordered_map>
#include <vector>
#include <string>
#include <stdexcept>

namespace dune {
  class FDHDChannelMapSP;
}

class dune::FDHDChannelMapSP {

public:

  typedef struct HDChanInfo {
    unsigned int offlchan;        // in gdml and channel sorting convention
    unsigned int crate;           // crate number
    std::string APAName;          // Descriptive APA name
    unsigned int upright;         // 0 for inverted, 1 for upright
    unsigned int wib;             // 1, 2, 3, 4 or 5  (slot number +1?)
    unsigned int link;            // link identifier: 0 or 1
    unsigned int femb_on_link;    // which of two FEMBs in the WIB frame this FEMB is:  0 or 1
    unsigned int cebchan;         // cold electronics channel on FEMB:  0 to 127
    unsigned int plane;           // 0: U,  1: V,  2: X
    unsigned int chan_in_plane;   // which channel this is in the plane in the FEMB:  0:39 for U and V, 0:47 for X
    unsigned int femb;            // which FEMB on an APA -- 1 to 20
    unsigned int asic;            // ASIC:   1 to 8
    unsigned int asicchan;        // ASIC channel:  0 to 15
    unsigned int wibframechan;    // channel index in WIB frame (used with get_adc in detdataformats/WIB2Frame.hh).  0:255
    bool valid;          // true if valid, false if not
  } HDChanInfo_t;

  FDHDChannelMapSP();  // constructor

  // initialize:  read map from two files, one containing two APAs worth of channel mapping (inverted and upright),
  // and the other containing a crate and APA name listing.

  void ReadMapFromFiles(const std::string &chanlist, const std::string &cratelist);

  // TPC channel map accessors

  // Map instrumentation numbers (crate:slot:link:FEMB:plane) to offline channel number.  FEMB is 0 or 1 and indexes the FEMB in the WIB frame.
  // plane = 0 for U, 1 for V and 2 for X

  HDChanInfo_t GetChanInfoFromWIBElements(
   unsigned int crate,
   unsigned int slot,
   unsigned int link,
   unsigned int wibframechan) const;

  HDChanInfo_t GetChanInfoFromOfflChan(unsigned int offlchan) const;

  unsigned int getNChans() { return fNChans; }

private:

  const unsigned int fNAPAs = 150;
  const unsigned int fNChans = 2560*fNAPAs;

  // maps of crate numbers and APAs.  These are maps so we do not have to assume that
  // crates are numbered consecutively or the numbering scheme may start at an unusual number.

  std::unordered_map<unsigned int, std::string>   fAPANameFromCrate;  
  std::unordered_map<unsigned int, unsigned int>  fUprightFromCrate; // 0: inverted;  1: upright
  std::unordered_map<unsigned int, unsigned int>  fCrateFromTPCSet;
  std::unordered_map<unsigned int, unsigned int>  fTPCSetFromCrate;

  // map of crate, slot, link, femb_on_link, plane, chan to channel info struct
  // This is only for two APAs, one upright, and one inverted

  std::unordered_map<unsigned int,   // upright
    std::unordered_map<unsigned int, // wib
    std::unordered_map<unsigned int, // link
    std::unordered_map<unsigned int, // wibframechan
    HDChanInfo_t > > > > DetToChanInfo;

  // maps of chan info indexed by offline channel number modulo 2560, for one APA each

  std::unordered_map<unsigned int, HDChanInfo_t> OfflToChanInfo_Inverted;
  std::unordered_map<unsigned int, HDChanInfo_t> OfflToChanInfo_Upright;

  //-----------------------------------------------

  void check_offline_channel(unsigned int offlineChannel) const
  {
  if (offlineChannel >= fNChans)
    {      
      throw std::range_error("FDHDChannelMapSP offline Channel out of range"); 
    }
  };

};


#endif
