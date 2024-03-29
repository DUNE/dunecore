#include "HDF5Utils.h"
#include <cstring>
#include <iostream>
#include "detdataformats/wib/WIBFrame.hpp"
#include "art/Framework/Services/Registry/ServiceHandle.h"
#include <algorithm>
#include "TMath.h"

namespace dune {
  namespace HDF5Utils {

    HDFFileInfoPtr openFile(const std::string& fileName) {
      HDFFileInfoPtr hdfFileInfoPtr(new HDFFileInfo());

      // open the actual file, but set the close degree so that when we close the file, all
      // open objects (attributes, groups, datasets) get closed automatically.  This is needed
      // so that xrootd streaming picks up the new file instead of accessing the old one

      hid_t fapl = H5Pcreate(H5P_FILE_ACCESS);
      H5Pset_fclose_degree(fapl,H5F_CLOSE_STRONG);
      hdfFileInfoPtr->filePtr = H5Fopen(fileName.data(), H5F_ACC_RDONLY, fapl);
      H5Pclose(fapl);

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

      //std::vector<char> outname;
      //ssize_t cs = 0;
      //cs = H5Fget_name(hdfFileInfoPtr->filePtr, NULL, 0 ) + 10;
      //outname.resize(cs);  // and a little extra just in case
      //cs = H5Fget_name(hdfFileInfoPtr->filePtr, outname.data(), cs );
      //std::cout << "Calling H5Fclose on file: " << outname.data() << std::endl;

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
  
    // trigger timestamp formatter with a fixed 20 ns clock period (50 MHz clock)

    uint64_t formatTrigTimeStamp (uint64_t trigTimeStamp)
    {
      int clock_period = 20; //20 ns with 50MHz DAQClock 
      uint64_t trigtime = trigTimeStamp * clock_period; //time in ns 
      uint64_t million = 1e9;
      uint64_t trigtime_sec =  trigtime/million;
      //std::cout << "trigtime_sec: " << trigtime_sec << std::endl;
      uint64_t trigtime_nanosec = trigtime % million;
      uint64_t toReturn = (trigtime_sec << 32) | trigtime_nanosec;
      return toReturn;
    }

    // FreqMHz is the clock frequency in MHz.  Otherwise same as formatTrigTimeStamp above
    // common values are 50.0 in the VD coldbox BDE, and 62.5 for ProtoDUNE-HD and its coldbox

    uint64_t formatTrigTimeStampWithFrequency (uint64_t trigTimeStamp, double FreqMHz)
    {
      double clock_period = 1000.0/FreqMHz; 
      uint64_t trigtime = trigTimeStamp * clock_period; //time in ns 
      uint64_t million = 1e9;
      uint64_t trigtime_sec =  trigtime/million;
      //std::cout << "trigtime_sec: " << trigtime_sec << std::endl;
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

      if (result)
        {
          H5Aclose(retval);
        }
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
      H5Dread(datasetid, H5T_STD_I8LE, H5S_ALL, H5S_ALL,
              H5P_DEFAULT, ds_data);
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
  }
}
