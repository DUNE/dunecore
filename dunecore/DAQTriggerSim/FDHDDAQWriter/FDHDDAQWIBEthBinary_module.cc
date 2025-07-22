////////////////////////////////////////////////////////////////////////
// Class:       FDHDDAQWIBEthBinary
// Plugin Type: analyzer (Unknown Unknown)
// File:        FDHDDAQWIBEthBinary_module.cc
//
//   Module to emulate DAQ-formatted writing of raw::RawDigits in 
//     HDF5 format
// Generated at Fri Aug 19 16:42:07 2022 by Thomas Junk using cetskelgen
// from  version .
////////////////////////////////////////////////////////////////////////

#include "art/Framework/Core/EDAnalyzer.h"
#include "art/Framework/Core/ModuleMacros.h"
#include "art/Framework/Principal/Event.h"
#include "art/Framework/Principal/Handle.h"
#include "art/Framework/Principal/Run.h"
#include "art/Framework/Principal/SubRun.h"
#include "canvas/Utilities/InputTag.h"
#include "fhiclcpp/ParameterSet.h"
#include "messagefacility/MessageLogger/MessageLogger.h"

#include <hdf5.h>
#include <iostream>
#include <string>
#include <sstream>
#include <algorithm>
#include <ios>
#include <iomanip>
#include <vector>
#include <unordered_map>
#include "detdataformats/wibeth/WIBEthFrame.hpp"
#include "lardataobj/RawData/raw.h"
#include "lardataobj/RawData/RawDigit.h"
#include "dunecore/ChannelMap/TPCChannelMapService.h"

class FDHDDAQWIBEthBinary : public art::EDAnalyzer {
public:
  explicit FDHDDAQWIBEthBinary(fhicl::ParameterSet const& p);

  // Plugins should not be copied or assigned.
  FDHDDAQWIBEthBinary(FDHDDAQWIBEthBinary const&) = delete;
  FDHDDAQWIBEthBinary(FDHDDAQWIBEthBinary&&) = delete;
  FDHDDAQWIBEthBinary& operator=(FDHDDAQWIBEthBinary const&) = delete;
  FDHDDAQWIBEthBinary& operator=(FDHDDAQWIBEthBinary&&) = delete;

  void analyze(art::Event const& e) override;

private:

  std::string fOutfilenameBase;
  std::string fRawDigitLabel;
  int fCollectionPedestalOffset;
  int fInductionPedestalOffset;
};


FDHDDAQWIBEthBinary::FDHDDAQWIBEthBinary(fhicl::ParameterSet const& p)
  : EDAnalyzer{p}  // ,
// More initializers here.
{
  fOutfilenameBase = p.get<std::string>("filename","fdhdwibethbinary");
  fRawDigitLabel = p.get<std::string>("rawdigitlabel","tpcrawdecoder:daq");
  fCollectionPedestalOffset = p.get<int>("CollectionPedestalOffset",900);
  fInductionPedestalOffset = p.get<int>("InductionPedestalOffset",2000);
}

void FDHDDAQWIBEthBinary::analyze(art::Event const& e)
{
  art::ServiceHandle<dune::TPCChannelMapService> electronicsMap;

  auto runno = e.run();
  auto subrun = e.subRun();
  auto evtno = e.event();

  bool warnedNegative = false;  // warn just once per event

// construct output filename from fOutfilenameBase_run<nnnnnn>_sr<nnn>_event<nnnnnn>.dat

  std::string trgname = "_run";
  std::ostringstream ofm1;
  ofm1 << fOutfilenameBase << "_run" << std::internal << std::setfill('0') << std::setw(6) << runno;
  ofm1 << "_sr" << std::internal << std::setfill('0') << std::setw(3) << subrun;
  ofm1 << "_event" << std::internal << std::setfill('0') << std::setw(6) << evtno << ".dat";
  std::string outputfilename = ofm1.str();
  FILE *ofile = fopen(outputfilename.c_str(),"w");

  // this will throw an exception if the raw digits cannot be found.

  auto const& RawDigits = e.getProduct< std::vector<raw::RawDigit> >(fRawDigitLabel);

  // need a map of indices to raw digits -- does not need to be sorted
  // check in the same loop that all raw digits have the same number of samples

  std::unordered_map<uint32_t,uint32_t> rdmap;
  size_t nSamples = 0;
  for (uint32_t iptn=0; iptn<RawDigits.size(); ++iptn)
    {
      rdmap[RawDigits[iptn].Channel()] = iptn;
      size_t nSc = RawDigits[iptn].Samples();
      if (nSamples == 0)
	{
	  nSamples = nSc;
	}
      if (nSamples != nSc)
	{
	  throw cet::exception("FDHDDAQWIBEthBinary") << "raw digits have different numbers of samples: " 
						     << nSamples << " " <<  nSc;
	}
    }
  std::vector<short> uncompressed(nSamples);

// WIBEth frames save 64 channels' worth of data in 64 time samples for each frame
// hard-code these for now.  dunedaq::fddetdataformats::WIBEthFrame::s_num_channels
// dunedaq::fddetdataformats::WIBEthFrame::s_time_samples_per_frame  are both 64

// Loop over the detector components -- if we do not have all the channels' raw digits to make a 64-channel WIB frame,
// just skip making it.

  uint32_t chanlist[64];  // a list of channel IDs to go into the frame
  int planelist[64];      // which plane each of these channels is in
  
  for (int crate=1; crate<151; ++crate)
    {
      for (int slot=0; slot<5; ++slot)
	{
	  for (int streamindex=0; streamindex<8; ++streamindex)
	    {
	      // make a list of raw digit indices for the 64 channels that go into this stream's frames
	      int stream = streamindex < 4 ? streamindex : streamindex+60;    // 0, 1, 2, 3, 64, 65, 66, 67
	      int det_id = 3;  // HD_TPC
	      bool skip=false;
	      for (int streamchan=0; streamchan<64; ++streamchan)
		{
		  auto cinfo = electronicsMap->GetChanInfoFromElectronicsIDs(det_id,crate,slot,stream,streamchan);
		  if (!cinfo.valid)  // shouldn't happen -- map should have everything we can loop over
		    {
		      throw cet::exception("FDHDDAQWIBEthBinary") << "electronics map does not have " << det_id << " " << crate << " " << slot << " " << stream << " " << streamchan;
		    }
		  auto cmi = rdmap.find(cinfo.offlchan);
		  if (cmi == rdmap.end())  // MC may not have all channels.  Skip entire stream if a channel in it is missing
		    {
		      skip = true;
		      break;
		    }
		  chanlist[streamchan] = cmi->second;   // raw digit index
		  planelist[streamchan] = cinfo.plane;
		} // end loop over stream chan to fill chanlist
	      if (skip) continue;  // didn't find all the channels we need to make this frame
	      
	      dunedaq::fddetdataformats::WIBEthFrame frame;
	      std::vector<std::vector<short>> uncompressed(64, std::vector<short>(nSamples));
	      for (int streamchan=0; streamchan<64; ++streamchan)
		{
		  int ch = chanlist[streamchan];
		  int pedestal = (int) (RawDigits[ch].GetPedestal() + 0.5); // nearest integer
		  raw::Uncompress(RawDigits[ch].ADCs(),uncompressed.at(streamchan),pedestal,RawDigits[ch].Compression());
		}

	      int iseq = 0;
	      for (size_t isample=0; isample<nSamples; ++isample)
		{
		  int isf = isample % 64;
		  for (int streamchan=0; streamchan<64; ++streamchan)
		    {
		      int d = uncompressed.at(streamchan).at(isample);
		      int pedestaloffset = (planelist[streamchan] == 2) ? fCollectionPedestalOffset : fInductionPedestalOffset;
		      d += pedestaloffset;
		      if (d<0)
			{
			  d = 0;
			  if (!warnedNegative)
			    {
			      MF_LOG_WARNING("FDHDDAQWIBEthBinary_module") << "Negative ADC value in raw::RawDigit.  Setting to zero to put in WIB frame\n";
			      warnedNegative = true;
			    }
			}
		      uint16_t d16 = d & 0xFFFF;
		      frame.set_adc(streamchan,isf,d16);
		    }
		  
		  if ( (isample+1) % 64 == 0)
		    {
		      frame.daq_header.det_id = det_id;
		      frame.daq_header.crate_id = crate;
		      frame.daq_header.slot_id = slot;
		      frame.daq_header.stream_id = stream;
		      frame.daq_header.seq_id = iseq;
		      frame.daq_header.block_length = 899;
		      frame.daq_header.timestamp = iseq*2048;
		      // maybe some better values here for WIBEthHeader.
		      frame.header.colddata_timestamp_0 = iseq*2048;
		      frame.header.pad_0 = 0;
		      frame.header.colddata_timestamp_1 = 0;
		      frame.header.pad_1 = 0;
		      frame.header.cd = 0;
		      frame.header.crc_err = 0;
		      frame.header.link_valid = 1;
		      frame.header.lol = 0;
		      frame.header.wib_sync = 1;
		      frame.header.femb_sync = 1;
		      frame.header.pulser = 0;
		      frame.header.calibration = 0;
		      frame.header.ready = 1;
		      frame.header.context = 0;
		      frame.header.version = 0;
		      frame.header.channel = 0;
		      frame.header.extra_data = 0;
		      fwrite(&frame, sizeof(frame), 1, ofile);
		      ++iseq;
		    }
		}
	      
	    } // end loop over stream index
	} // end loop over slots
    } // end loop over crates
  fclose(ofile);
} // end analyze method

DEFINE_ART_MODULE(FDHDDAQWIBEthBinary)
