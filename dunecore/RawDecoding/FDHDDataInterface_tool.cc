#include "FDHDDataInterface.h"

#include <hdf5.h>
#include <iostream>
#include <list>
#include <set>
#include <sstream>
#include <cstring>
#include <string>
#include "TMath.h"
#include "TString.h"

#include "art/Framework/Services/Registry/ServiceHandle.h"
#include "messagefacility/MessageLogger/MessageLogger.h"
#include "dunecore/DuneObj/DUNEHDF5FileInfo.h"
#include "dunecore/HDF5Utils/HDF5Utils.h"
#include "detdataformats/wib2/WIB2Frame.hpp"
#include "dunecore/ChannelMap/FDHDChannelMapService.h"

FDHDDataInterface::FDHDDataInterface(fhicl::ParameterSet const& p)
  : fFileInfoLabel(p.get<std::string>("FileInfoLabel", "daq")),
    fMaxChan(p.get<int>("MaxChan",1000000)),
    fDefaultCrate(p.get<unsigned int>("DefaultCrate", 1)),
    fDebugLevel(p.get<int>("DebugLevel",0))
{
}


// wrapper for backward compatibility.  Return data for all APA's represented 
// in the fragments on these labels
int FDHDDataInterface::retrieveData(art::Event &evt,
                                    std::string inputLabel,
                                    std::vector<raw::RawDigit> &raw_digits,
                                    std::vector<raw::RDTimeStamp> &rd_timestamps,
                                    std::vector<raw::RDStatus> &rdstatuses)
{
  return 0;
}


int FDHDDataInterface::retrieveDataForSpecifiedAPAs(art::Event &evt,
                                                    std::vector<raw::RawDigit> &raw_digits,
                                                    std::vector<raw::RDTimeStamp> &rd_timestamps,
                                                    std::vector<raw::RDStatus> &rdstatuses,
                                                    std::vector<int> &apalist)
{
  using namespace dune::HDF5Utils;
  auto infoHandle = evt.getHandle<raw::DUNEHDF5FileInfo>(fFileInfoLabel);
  const std::string & toplevel_groupname = infoHandle->GetEventGroupName();
  const std::string & file_name = infoHandle->GetFileName();
  hid_t file_id = infoHandle->GetHDF5FileHandle();
  hid_t the_group = getGroupFromPath(file_id, toplevel_groupname);

  if (fDebugLevel > 0)
    {
      std::cout << "FDHDDataInterface : " << "HDF5 FileName: " << file_name << std::endl;
      std::cout << "FDHDDataInterface :" << "Top-Level Group Name: " << toplevel_groupname << std::endl;
    }

  if (fDebugLevel > 0)
    {
      std::cout << "FDHDDataInterface : " <<  "Retrieving Data for " << apalist.size() << " APAs " << std::endl;
    }

  for (const int & i : apalist)
    {
      int apano = i;
      if (fDebugLevel > 0)
        {
          std::cout << "FDHDDataInterface :" << "apano: " << i << std::endl;
        }

      getFragmentsForEvent(the_group, raw_digits, rd_timestamps, apano);

      //Currently putting in dummy values for the RD Statuses
      rdstatuses.clear();
      rdstatuses.emplace_back(false, false, 0);
    }

  return 0;
}


// get data for a specific label, but only return those raw digits that correspond to APA's on the list
// not implemented anymore -- we don't have module labels in the HDF5 files

int FDHDDataInterface::retrieveDataAPAListWithLabels( art::Event &evt,
                                                      std::string inputLabel,
                                                      std::vector<raw::RawDigit> &raw_digits,
                                                      std::vector<raw::RDTimeStamp> &rd_timestamps,
                                                      std::vector<raw::RDStatus> &rdstatuses,
                                                      std::vector<int> &apalist)
{
  return 0;
}


// This is designed to read 1APA/CRU The function uses "apano", handed by DataPrep,
// as an argument.

void FDHDDataInterface::getFragmentsForEvent(hid_t the_group, RawDigits& raw_digits, RDTimeStamps &timestamps, int apano)
{
  using namespace dune::HDF5Utils;
  using dunedaq::fddetdataformats::WIB2Frame;

  art::ServiceHandle<dune::FDHDChannelMapService> wireReadout;

  std::deque<std::string> det_types
    = getMidLevelGroupNames(the_group);
  
  for (const auto & det : det_types)
    {
      if (det != "TPC") continue;
      
      if (fDebugLevel > 0)
        {
          std::cout << logname  << " Detector type:  " << det << std::endl;
        }
      hid_t geoGroup = getGroupFromPath(the_group, det);
      std::deque<std::string> apaNames
        = getMidLevelGroupNames(geoGroup);
      
      if (fDebugLevel > 0)
        {
          std::cout << logname << " Size of apaNames: " << apaNames.size() << std::endl;
          std::cout << logname << " " << "apaNames[0]: "  << apaNames[0] << std::endl;
        }

      for (const auto & apaname : apaNames)
        {
	  // assume the APA group name is of the form APAnnn

	  int input_apa = atoi(apaname.substr(3,3).c_str());
	  if (input_apa != apano) continue;

          hid_t linkGroup = getGroupFromPath(geoGroup, apaname);
          std::deque<std::string> linkNames = getMidLevelGroupNames(linkGroup);

          for (const auto & t : linkNames)
            {
              // link below is calculated from the HDF5 group name. However,later a link is calculated from 
              // WIBFrameHeader and used in the rest of the code.
              unsigned int link = atoi(t.substr(4,2).c_str());
              hid_t dataset = H5Dopen(linkGroup, t.data(), H5P_DEFAULT);
              hsize_t ds_size = H5Dget_storage_size(dataset);
              if (ds_size <= sizeof(FragmentHeader)) continue; //Too small

              std::vector<char> ds_data(ds_size);
              H5Dread(dataset, H5T_STD_I8LE, H5S_ALL, H5S_ALL, H5P_DEFAULT, ds_data.data());
              H5Dclose(dataset);

              //Each fragment is a collection of WIB Frames
              Fragment frag(&ds_data[0], Fragment::BufferAdoptionMode::kReadOnlyMode);
              size_t n_frames = (ds_size - sizeof(FragmentHeader))/sizeof(WIB2Frame);
              if (fDebugLevel > 0)
                {
                  std::cout << "n_frames calc.: " << ds_size << " " << sizeof(FragmentHeader) << " " << sizeof(WIB2Frame) << " " << n_frames << std::endl;
                }
              std::vector<raw::RawDigit::ADCvector_t> adc_vectors(256);
              unsigned int slot = 0, link_from_frameheader = 0, crate = 0;
          
              for (size_t i = 0; i < n_frames; ++i)
                {
                  // dump WIB frames in hex
                  //std::cout << "Frame number: " << i << std::endl;
                  // size_t wfs32 = sizeof(WIB2Frame)/4;
                  //uint32_t *fdp = reinterpret_cast<uint32_t*>(static_cast<uint8_t*>(frag.get_data()) + i*sizeof(WIB2Frame));
                  //std::cout << std::dec;
                  //for (size_t iwdt = 0; iwdt < 1; iwdt++)  // dumps just the first 32 bits.  use wfs32 if you want them all
                  //{
                  //  std::cout << iwdt << " : 10987654321098765432109876543210" << std::endl;
                  //  std::cout << iwdt << " : " << std::bitset<32>{fdp[iwdt]} << std::endl;
                  //}
                  //std::cout << std::dec;

                  auto frame = reinterpret_cast<WIB2Frame*>(static_cast<uint8_t*>(frag.get_data()) + i*sizeof(WIB2Frame));
                  for (size_t j = 0; j < adc_vectors.size(); ++j)
                    {
                      adc_vectors[j].push_back(frame->get_adc(j));
                    }
              
                  if (i == 0)
                    {
                      crate = frame->header.crate;
                      slot = frame->header.slot;
                      link_from_frameheader = frame->header.link;
                    }
                }
              if (fDebugLevel > 0)
                {
                  std::cout << logname << ": crate, slot, link(HDF5 group), link(WIB Header): "  << crate << ", " << slot << ", " << link << ", " << link_from_frameheader << std::endl;
                }

              for (size_t iChan = 0; iChan < 256; ++iChan)
                {
                  const raw::RawDigit::ADCvector_t & v_adc = adc_vectors[iChan];

                  uint32_t slotloc = slot;
                  slotloc &= 0x7;

                  auto hdchaninfo = wireReadout->GetChanInfoFromWIBElements (crate, slotloc, link_from_frameheader, iChan); 
                  unsigned int offline_chan = hdchaninfo.offlchan;

                  if (offline_chan > fMaxChan) continue;

                  raw::RDTimeStamp rd_ts(frag.get_trigger_timestamp(), offline_chan);
                  timestamps.push_back(rd_ts);

                  float median = 0., sigma = 0.;
                  getMedianSigma(v_adc, median, sigma);
                  raw::RawDigit rd(offline_chan, v_adc.size(), v_adc);
                  rd.SetPedestal(median, sigma);
                  raw_digits.push_back(rd);
                }

            }
          H5Gclose(linkGroup);
        }
    }
}

void FDHDDataInterface::getMedianSigma(const raw::RawDigit::ADCvector_t &v_adc, float &median,
                                       float &sigma) {
  size_t asiz = v_adc.size();
  int imed=0;
  if (asiz == 0) {
    median = 0;
    sigma = 0;
  }
  else {
    // the RMS includes tails from bad samples and signals and may not be the best RMS calc.

    imed = TMath::Median(asiz,v_adc.data()) + 0.01;  // add an offset to make sure the floor gets the right integer
    median = imed;
    sigma = TMath::RMS(asiz,v_adc.data());
    
    // add in a correction suggested by David Adams, May 6, 2019
    
    size_t s1 = 0;
    size_t sm = 0;
    for (size_t i = 0; i < asiz; ++i) {
      if (v_adc.at(i) < imed) s1++;
      if (v_adc.at(i) == imed) sm++;
    }
    if (sm > 0) {
      float mcorr = (-0.5 + (0.5*(float) asiz - (float) s1)/ ((float) sm) );
      if (fDebugLevel > 0)
        {
          if (std::abs(mcorr)>1.0) std::cout << "mcorr: " << mcorr << std::endl;
        }
      median += mcorr;
    }
  }  
}

DEFINE_ART_CLASS_TOOL(FDHDDataInterface)
