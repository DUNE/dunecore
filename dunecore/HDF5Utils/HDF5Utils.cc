#include "HDF5Utils.h"
#include <cstring>
#include <iostream>
#include "detdataformats/wib/WIBFrame.hpp"
//#include "dune/VDColdbox/ChannelMap/VDColdboxChannelMapService.h"
#include "art/Framework/Services/Registry/ServiceHandle.h"
#include <algorithm>
#include "TMath.h"

namespace dune {
namespace HDF5Utils {

/*using dunedaq::detdataformats::WIBFrame;
using dunedaq::detdataformats::WIBHeader;*/

HDFFileInfoPtr openFile(const std::string& fileName) {
  HDFFileInfoPtr hdfFileInfoPtr(new HDFFileInfo());
  hdfFileInfoPtr->filePtr = H5Fopen(fileName.data(), H5F_ACC_RDONLY, H5P_DEFAULT);
  hdfFileInfoPtr->bytesWritten = 0;
  hdfFileInfoPtr->fileName = fileName;
  hdfFileInfoPtr->runNumber = 0;   // don't know it yet.  Fill it when we get fragments.
  hdfFileInfoPtr->dataFormatVersion = 0;

  hid_t grp = H5Gopen(hdfFileInfoPtr->filePtr,"/", H5P_DEFAULT);
  if (attrExists(grp, "data_format_version"))
    {
      hid_t ga = H5Aopen_name(grp, "data_format_version");
      H5Aread(ga, H5Aget_type(ga), &hdfFileInfoPtr->dataFormatVersion);
      H5Aclose(ga);
    }
  H5Gclose(grp);
  return hdfFileInfoPtr;
}

void closeFile(HDFFileInfoPtr hdfFileInfoPtr) {
  H5Fclose(hdfFileInfoPtr->filePtr);
  hdfFileInfoPtr->filePtr = 0;
}

std::deque<std::string> getTopLevelGroupNames(HDFFileInfoPtr& hdfFileInfoPtr) {
  hid_t grp = H5Gopen(hdfFileInfoPtr->filePtr, "/", H5P_DEFAULT);
  std::deque<std::string> theList = getMidLevelGroupNames(grp);
  H5Gclose(grp);
  return theList;
}

std::deque<std::string> getMidLevelGroupNames(hid_t grp) {
  std::deque<std::string> theList;
  hsize_t nobj = 0;
  H5Gget_num_objs(grp, &nobj);
  for (hsize_t idx = 0; idx < nobj; ++idx) {
    hsize_t len = H5Gget_objname_by_idx(grp, idx, NULL, 0 );
    char *memb_name = new char(len+1);
    H5Gget_objname_by_idx(grp, idx, memb_name, len+1 );
    theList.emplace_back(memb_name);
    delete memb_name;
  }
  return theList;
}

  
  uint64_t formatTrigTimeStamp (uint64_t trigTimeStamp)
  {
    int clock_period = 20; //20 ns with 50MHz DAQClock //FIXME don't hardcode
    uint64_t trigtime = trigTimeStamp * clock_period; //time in ns 
    uint64_t million = 1e9;
    uint64_t trigtime_sec =  trigtime/million;
    std::cout << "trigtime_sec: " << trigtime_sec << std::endl;
    uint64_t trigtime_nanosec = trigtime % million;
    uint64_t toReturn = (trigtime_sec << 32) | trigtime_nanosec;
    return toReturn;
  }
       

  bool attrExists(hid_t object, const std::string &attrname) {
  // Save old error handler 
  H5E_auto_t old_func;
  void *old_client_data;
  H5Eget_auto(H5E_DEFAULT,&old_func, &old_client_data);
  
  // Turn off error handling */
  H5Eset_auto(H5E_DEFAULT,NULL, NULL);
  
  // Probe. On failure, retval is supposed to be negative
  
  hid_t retval = H5Aopen_name(object, attrname.data());
  
  // Restore previous error handler 
  H5Eset_auto(H5E_DEFAULT,old_func, old_client_data);
  
  bool result = (retval >= 0);
  return result;
}

hid_t getGroupFromPath(hid_t fd, const std::string &path) {
  hid_t grp = H5Gopen(fd, path.data(), H5P_DEFAULT);
  return grp;
}

void getHeaderInfo(hid_t the_group, const std::string & det_type,
      	     HeaderInfo & info) {
  hid_t datasetid = H5Dopen(the_group, det_type.data(), H5P_DEFAULT);
  hsize_t ds_size = H5Dget_storage_size(datasetid);
  //std::cout << "      Data Set Size (bytes): " << ds_size << std::endl;
  // todo -- check for zero size
  if (ds_size < 64) {
    //std::cout << "TriggerRecordHeader datset too small" << std::endl; 
  }
  size_t narray = ds_size / sizeof(char);
  size_t rdr = ds_size % sizeof(char);
  if (rdr > 0 || narray == 0) narray++;
  char *ds_data = new char[narray];
  /*herr_t ecode = */H5Dread(datasetid, H5T_STD_I8LE, H5S_ALL, H5S_ALL,
      		       H5P_DEFAULT, ds_data);
  /*
    int firstbyte = ds_data[0];
    firstbyte &= 0xFF;
    int lastbyte = ds_data[narray-1];
    lastbyte &= 0xFF;*/
  //std::cout << std::hex << "      Retrieved data: ecode: " << ecode <<
  //"  first byte: " << firstbyte << " last byte: " <<
  //lastbyte << std::dec << std::endl;
  H5Dclose(datasetid);
  
  //int magic_word = 0;
  memcpy(&info.magicWord, &ds_data[0],4);
  //std::cout << "   Magic word: 0x" << std::hex << info.magicWord << std::dec <<
  //std::endl;
  
  //int version = 0;
  memcpy(&info.version, &ds_data[4],4);
  //std::cout << "   Version: " << std::dec << info.version << std::dec <<
  //std::endl;
  
  //uint64_t trignum=0;
  memcpy(&info.trigNum, &ds_data[8],8);
  //std::cout << "   Trig Num: " << std::dec << info.trigNum << std::dec <<
  //std::endl;
  
  //uint64_t trig_timestamp=0;
  memcpy(&info.trigTimestamp, &ds_data[16],8);
  //std::cout << "   Trig Timestamp: " << std::dec << info.trigTimestamp <<
  //std::dec << std::endl;
  
  //uint64_t nreq=0;
  memcpy(&info.nReq, &ds_data[24],8);
  //std::cout << "   No. of requested components:   " << std::dec << info.nReq <<
  //std::dec << std::endl;
  
  //int runno=0;
  memcpy(&info.runNum, &ds_data[32], 4);
  //std::cout << "   Run Number: " << std::dec << info.runNum << std::endl;
  //run_id = info.runNum;
  
  //int errbits=0;
  memcpy(&info.errBits, &ds_data[36], 4);
  //std::cout << "   Error bits: " << std::dec << info.errBits << std::endl;
  
  //short triggertype=0;
  memcpy(&info.triggerType, &ds_data[40], 2);
  //std::cout << "   Trigger type: " << std::dec << info.triggerType << std::endl;
  
  //delete[] ds_data;  // free up memory
} 
  

// This is designed to read 1APA/CRU, only for VDColdBox data. The function uses "apano", handed by DataPrep,
// as an argument.
/*
void getFragmentsForEvent(hid_t the_group, RawDigits& raw_digits, RDTimeStamps &timestamps, int apano, int maxchan)  {
  art::ServiceHandle<dune::VDColdboxChannelMapService> channelMap;
  
  std::deque<std::string> det_types
    = getMidLevelGroupNames(the_group);

  for (const auto & det : det_types)
    {
      if (det != "TPC") continue;
      //std::cout << "  Detector type:  " << det << std::endl;
      hid_t geoGroup = getGroupFromPath(the_group, det);
      std::deque<std::string> apaNames
        = getMidLevelGroupNames(geoGroup);
      
      std::cout << "Size of apaNames: " << apaNames.size() << std::endl;
      std::cout << "apaNames[apano]: "  << apaNames[apano-1] << std::endl;
      
      // apaNames is a vector whose elements start at [0].
      hid_t linkGroup = getGroupFromPath(geoGroup, apaNames[apano-1]);
      std::deque<std::string> linkNames
        = getMidLevelGroupNames(linkGroup);
      for (const auto & t : linkNames)
        {
          hid_t dataset = H5Dopen(linkGroup, t.data(), H5P_DEFAULT);
          hsize_t ds_size = H5Dget_storage_size(dataset);
          if (ds_size <= sizeof(FragmentHeader)) continue; //Too small
          
          std::vector<char> ds_data(ds_size);
          H5Dread(dataset, H5T_STD_I8LE, H5S_ALL, H5S_ALL, H5P_DEFAULT,
                  ds_data.data());
          H5Dclose(dataset);
          
          //Each fragment is a collection of WIB Frames
          Fragment frag(&ds_data[0], Fragment::BufferAdoptionMode::kReadOnlyMode);
          size_t n_frames = (ds_size - sizeof(FragmentHeader))/sizeof(WIBFrame);
          std::vector<raw::RawDigit::ADCvector_t> adc_vectors(256);
          uint32_t slot = 0, fiber = 0;
          for (size_t i = 0; i < n_frames; ++i)
            {
              auto frame = reinterpret_cast<WIBFrame*>(static_cast<uint8_t*>(frag.get_data()) + i*sizeof(WIBFrame));
              for (size_t j = 0; j < adc_vectors.size(); ++j)
                {
                  adc_vectors[j].push_back(frame->get_channel(j));
                }
      	
              if (i == 0)
                {
                  slot = frame->get_wib_header()->slot_no;
                  fiber = frame->get_wib_header()->fiber_no;
                }
            }
          //std::cout << "slot, fiber: "  << slot << ", " << fiber << std::endl;
          for (size_t iChan = 0; iChan < 256; ++iChan)
            {
              const raw::RawDigit::ADCvector_t & v_adc = adc_vectors[iChan];
      	//std::cout << "Channel: " << iChan << " N ticks: " << v_adc.size() << " Timestamp: " << frag.get_trigger_timestamp() << std::endl;

              int offline_chan = channelMap->getOfflChanFromSlotFiberChan(slot, fiber, iChan);
              if (offline_chan < 0) continue;
	        if (offline_chan > maxchan) continue;
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
  
void getMedianSigma(const raw::RawDigit::ADCvector_t &v_adc, float &median,
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
      //if (std::abs(mcorr)>1.0) std::cout << "mcorr: " << mcorr << std::endl;
      median += mcorr;
    }
  }
  
}
*/
}
}
