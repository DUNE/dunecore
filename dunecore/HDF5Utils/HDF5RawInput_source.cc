#include "art/Framework/Core/InputSourceMacros.h"
#include "art/Framework/IO/Sources/Source.h"
#include "art/Framework/IO/Sources/SourceTraits.h"
#include "dune/HDF5Utils/HDF5RawInput.h"
#include "dune/DuneObj/DUNEHDF5FileInfo.h"
#include "lardataobj/RawData/RDTimeStamp.h"

dune::HDF5RawInputDetail::HDF5RawInputDetail(
    fhicl::ParameterSet const & ps,
    art::ProductRegistryHelper & rh,
    art::SourceHelper const & sh) 
  : pretend_module_name(ps.get<std::string>("raw_data_label", "daq")),
    fLogLevel(ps.get<int>("LogLevel", 0)),
    pmaker(sh) {
  rh.reconstitutes<raw::DUNEHDF5FileInfo, art::InEvent>(pretend_module_name); 
  rh.reconstitutes<raw::RDTimeStamp, art::InEvent>(pretend_module_name, "trigger");
}

void dune::HDF5RawInputDetail::readFile(
    std::string const & filename, art::FileBlock*& fb) {
  hdf_file_ = dune::HDF5Utils::openFile(filename);
  unprocessedEventList_
      = dune::HDF5Utils::getTopLevelGroupNames(hdf_file_);
  MF_LOG_INFO("HDF5")
      << "HDF5 opened HDF file with run number " <<
         hdf_file_->runNumber  << " and " <<
         unprocessedEventList_.size() << " events";
  for (const auto & e : unprocessedEventList_)
    MF_LOG_INFO("HDF5") << e;

  fb = new art::FileBlock(art::FileFormatVersion(1, "RawEvent2011"),
                          filename); 
}

bool dune::HDF5RawInputDetail::readNext(art::RunPrincipal const* const inR,
                                                art::SubRunPrincipal const* const inSR,
                                                art::RunPrincipal*& outR,
                                                art::SubRunPrincipal*& outSR,
                                                art::EventPrincipal*& outE) 
{
  using namespace dune::HDF5Utils;
  
  // Establish default 'results'
  outR = 0;
  outSR = 0;
  outE = 0;

  if (unprocessedEventList_.empty()) {return false;}
  std::string nextEventGroupName = unprocessedEventList_.front();
  unprocessedEventList_.pop_front();

  size_t run_id = 999; //runNumber can be 0,
                      //but this seems like an issue
                      //with art

  //Accessing run number
  hid_t the_group = getGroupFromPath (hdf_file_->filePtr, nextEventGroupName);
  //std::vector<std::string> detector_types = getMidLevelGroupNames(the_group);
  HeaderInfo header_info;
  std::string det_type = "TriggerRecordHeader";
  getHeaderInfo(the_group, det_type, header_info);
  if (fLogLevel > 0) {
    std::cout << "   Magic word: 0x" << std::hex << header_info.magicWord <<
                 std::dec << std::endl;
    std::cout << "   Version: " << std::dec << header_info.version <<
                 std::dec << std::endl;
    std::cout << "   Trig Num: " << std::dec << header_info.trigNum <<
                 std::dec << std::endl;
    std::cout << "   Trig Timestamp: " << std::dec <<
                 header_info.trigTimestamp << std::dec << std::endl;
    std::cout << "   No. of requested components:   " << std::dec <<
                 header_info.nReq << std::dec << std::endl;
    std::cout << "   Run Number: " << std::dec << header_info.runNum <<
                 std::endl;
    std::cout << "   Error bits: " << std::dec << header_info.errBits <<
                 std::endl;
    std::cout << "   Trigger type: " << std::dec << header_info.triggerType <<
                 std::endl;
  }
   MF_LOG_INFO("HDF5") << "header_info.trigTimestamp :" << header_info.trigTimestamp << std::endl;

   // trigTimeStamp is NOT time but Clock-tick since the epoch.
   uint64_t trigTimeStamp = header_info.trigTimestamp;
    
   uint64_t getTrigTime = formatTrigTimeStamp (trigTimeStamp);
   std::cout << "getTrigTime :" << getTrigTime << std::endl;
  
   art::Timestamp artTrigStamp (getTrigTime);
   std::cout << "artTrigStamp :" << artTrigStamp.value() << std::endl;

  run_id = header_info.runNum;
  std::unique_ptr<raw::RDTimeStamp> rd_timestamp(
    new raw::RDTimeStamp(header_info.trigTimestamp));

 

  // make new run if inR is 0 or if the run has changed
  if (inR == 0 || inR->run() != run_id) {
    outR = pmaker.makeRunPrincipal(run_id,artTrigStamp);
  }

  // make new subrun if inSR is 0 or if the subrun has changed
  art::SubRunID subrun_check(run_id, 1);
  if (inSR == 0 || subrun_check != inSR->subRunID()) {
    outSR = pmaker.makeSubRunPrincipal(run_id, 1, artTrigStamp);
  }

  //Where to get event number?
  //For now -- parse from input record
  std::string event_str = nextEventGroupName;
  std::string trig = "TriggerRecord";
  auto pos = event_str.begin() + event_str.find(trig);
  event_str.erase(pos, pos + trig.size());
  int event = std::stoi(event_str);
  outE = pmaker.makeEventPrincipal(run_id, 1, event, artTrigStamp);
  //std::cout << "Event Time Stamp :" << event.time() << std::endl;
 
  std::unique_ptr<raw::DUNEHDF5FileInfo> the_info(
      new raw::DUNEHDF5FileInfo(hdf_file_->fileName, hdf_file_->filePtr,
                           0, nextEventGroupName));

  put_product_in_principal(std::move(the_info), *outE, pretend_module_name,
                           "");
  put_product_in_principal(std::move(rd_timestamp), *outE, pretend_module_name,
                           "trigger");

  return true;
}

//typedef for shorthand
namespace dune {
using HDF5RawInputSource = art::Source<HDF5RawInputDetail>;
}


DEFINE_ART_INPUT_SOURCE(dune::HDF5RawInputSource)
