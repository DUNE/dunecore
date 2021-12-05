#ifndef HDF5Utils_h
#define HDF5Utils_h

//#include "artdaq-core/Data/Fragment.hh"

#include <hdf5.h>
#include <deque>
#include <map>
#include <memory>
#include <string>



#include "daqdataformats/Fragment.hpp"
#include "lardataobj/RawData/RawDigit.h"
#include "lardataobj/RawData/RDTimeStamp.h"

namespace dune {
namespace HDF5Utils {

using dunedaq::daqdataformats::Fragment;
using dunedaq::daqdataformats::FragmentHeader;
typedef std::vector<raw::RawDigit> RawDigits;
typedef std::vector<raw::RDTimeStamp> RDTimeStamps;

struct HDFFileInfo {
  hid_t filePtr;
  size_t bytesWritten;
  std::string fileName;
  int runNumber;
  int dataFormatVersion;
};

struct HeaderInfo {
  int magicWord = 0;
  int version = 0;
  uint64_t trigNum = 0;
  uint64_t trigTimestamp = 0;
  uint64_t nReq = 0;
  int runNum = 0;
  int errBits = 0;
  short triggerType = 0;
};

uint64_t formatTrigTimeStamp (uint64_t trigTimeStamp);
typedef std::unique_ptr<HDFFileInfo> HDFFileInfoPtr;
HDFFileInfoPtr openFile(const std::string& fileName);
void closeFile(HDFFileInfoPtr hdfFileInfoPtr);
std::deque<std::string> getTopLevelGroupNames(HDFFileInfoPtr& hdfFileInfoPtr);
std::deque<std::string> getMidLevelGroupNames(hid_t gid);
bool attrExists(hid_t object, const std::string& attrname);
hid_t getGroupFromPath(hid_t fd, const std::string &path);

void getHeaderInfo(hid_t the_group, const std::string & det_type,
                   HeaderInfo & info);

typedef std::vector<Fragment> Fragments;
//typedef std::map<std::string, std::unique_ptr<Fragments>> FragmentListsByType;


}
}

#endif
