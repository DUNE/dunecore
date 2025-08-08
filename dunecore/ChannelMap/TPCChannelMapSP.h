///////////////////////////////////////////////////////////////////////////////////////////////////
// Class:       TPCChannelMapSP
// Module type: algorithm
// File:        TPCChannelMapSP.h
// Author:      Tom Junk, Jan 2025
//
// Meant to cover cases with HD and VD (BDE and TDE) which use the DUNE-DAQ v4.4.0 DAQEth header
// detdataformats/DAQEthHeader.hpp
///////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef TPCChannelMapSP_H
#define TPCChannelMapSP_H

#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

namespace dune {
  class TPCChannelMapSP;
}

class dune::TPCChannelMapSP {

public:
  typedef struct TPCChanInfo {
    unsigned int offlchan;      // in gdml and channel sorting convention
    unsigned int detid;         // from detdatformats/DetID.hpp.   Map key
    unsigned int detelement;    // CRP number for Vertical Drift or APA number for Horizontal Drift
    unsigned int crate;         // crate number   Map key
    unsigned int slot;          // slot in crate (WIB for BDE and HD, card for TDE)   Map key
    unsigned int stream;        // Hermes stream for BDE and HD, 0 for TDE   Map key
    unsigned int streamchan;    // channel in the stream.  Usually 0:63   Map key
    unsigned int plane;         // 0: U,  1: V,  2: X      For info only
    unsigned int chan_in_plane; // which channel this is in the plane   For info only
    unsigned int femb;          // which FEMB      For info only
    unsigned int asic;          // ASIC            For info only
    unsigned int asicchan;      // ASIC channel    For info only
    bool valid;                 // true if valid, false if not  -- if map lookup fails, this is false
  } TPCChanInfo_t;

  TPCChannelMapSP(); // constructor

  // initialize:  read map from file

  void ReadMapFromFile(std::string& fullname);

  // TPC channel map accessors

  // Map instrumentation numbers (detid:crate:slot:stream:streamchan) to offline channel number.  

  TPCChanInfo_t GetChanInfoFromElectronicsIDs(unsigned int detid,
                                              unsigned int crate,
                                              unsigned int slot,
                                              unsigned int stream,
                                              unsigned int streamchan) const;

  TPCChanInfo_t GetChanInfoFromOfflChan(unsigned int offlchan) const;

  unsigned int GetNChannels() { return fNChans; };

  // crate to substitute in case the crate number is not understood.
  
  void SetSubstituteCrate(unsigned int sc) { fSubstituteCrate = sc; }

  unsigned int GetSubstituteCrate() { return fSubstituteCrate; }

private:
  unsigned int fNChans;                 // summed over the detector
  unsigned int fSubstituteCrate;        // crate to substitute in case crate is not understood.
  // this is meant for re-using a channel map for a coldbox for example

  // map of detid, crate, slot, stream, streamchan to channel info struct

  std::unordered_map<size_t, TPCChanInfo_t>  DetToChanInfo;   // just one key, a hash of the five keys (see make_hash)

  // map of chan info indexed by offline channel number

  std::unordered_map<unsigned int, TPCChanInfo_t> OfflToChanInfo;

  //-----------------------------------------------

  void check_offline_channel(unsigned int offlineChannel) const
  {
    // do nothing as channels may not be densely spaced in offline channel number.
  };

  size_t make_hash( unsigned int detid,   //6 bits
                  unsigned int crate,   //10 bits
                  unsigned int slot,    //4 bits
                  unsigned int stream,  //8 bits
                  unsigned int streamch //12 bits
                  ) const;
};

#endif
