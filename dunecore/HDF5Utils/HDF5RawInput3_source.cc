#include "art/Framework/Core/InputSourceMacros.h"
#include "art/Framework/IO/Sources/Source.h"
#include "art/Framework/IO/Sources/SourceTraits.h"
#include "dunecore/HDF5Utils/HDF5RawInput3.h"
#include "dunecore/DuneObj/DUNEHDF5FileInfo2.h"
#include "lardataobj/RawData/RDTimeStamp.h"

dune::HDF5RawInput3Detail::HDF5RawInput3Detail(
                                               fhicl::ParameterSet const & ps,
                                               art::ProductRegistryHelper & rh,
                                               art::SourceHelper const & sh) 
  : pretend_module_name(ps.get<std::string>("raw_data_label", "daq")),
    fLogLevel(ps.get<int>("LogLevel", 0)),
    fClockFreqMHz(ps.get<double>("ClockFrequencyMHz", 50.0)),
    fHandleSequenceOption(ps.get<std::string>("HandleSequenceOption","ignore")),
    fTrnScale(ps.get<unsigned int>("TrnScale",10000)),
    pmaker(sh) {
      rh.reconstitutes<raw::DUNEHDF5FileInfo2, art::InEvent>(pretend_module_name);
      rh.reconstitutes<raw::RDTimeStamp, art::InEvent>(pretend_module_name, "trigger");
    }

void dune::HDF5RawInput3Detail::readFile(
                                         std::string const & filename, art::FileBlock*& fb) {

  // open the input file with the dunedaq class and hand the ownership off to the rawFileServie

  art::ServiceHandle<dune::HDF5RawFile3Service> rawFileService;
  auto hdf_file = std::make_unique<dunedaq::hdf5libs::HDF5RawDataFile>(filename);
  rawFileService->SetPtr(std::move(hdf_file));

  // for convenience, get a non-owning pointer
  auto rf = rawFileService->GetPtr();

  fUnprocessedEventRecordIDs = rf->get_all_trigger_record_ids();
  fLastEvent = 0;

  uint32_t run_number = rf->get_attribute<uint32_t>("run_number");
  MF_LOG_INFO("HDF5")
    << "HDF5 opened HDF file with run number " <<
    run_number  << " and " <<
    fUnprocessedEventRecordIDs.size() << " events";
  if (fLogLevel > 0)
    {
       for (const auto & e : fUnprocessedEventRecordIDs) MF_LOG_INFO("HDF5") << e.first << " " << e.second;
    }

  fb = new art::FileBlock(art::FileFormatVersion(1, "RawEvent2011"),
                          filename); 
}

bool dune::HDF5RawInput3Detail::readNext(art::RunPrincipal const* const inR,
                                         art::SubRunPrincipal const* const inSR,
                                         art::RunPrincipal*& outR,
                                         art::SubRunPrincipal*& outSR,
                                         art::EventPrincipal*& outE) 
{
  using namespace dune::HDF5Utils;
  
  art::ServiceHandle<dune::HDF5RawFile3Service> rawFileService;
  auto rf = rawFileService->GetPtr();

  // Establish default 'results'
  outR = 0;
  outSR = 0;
  outE = 0;

  if (fUnprocessedEventRecordIDs.empty()) {return false;}

  // take the first unprocessed event off the set

  auto nextEventRecordID_i = fUnprocessedEventRecordIDs.cbegin();
  auto nextEventRecordID = *nextEventRecordID_i;
  fUnprocessedEventRecordIDs.erase(nextEventRecordID_i);

  uint32_t run_id = rf->get_attribute<uint32_t>("run_number");

  // get trigger record header pointer

  auto trh = rf->get_trh_ptr(nextEventRecordID);

  //check that the run number in the trigger record header agrees with that in the file attribute

  auto run_id2 = trh->get_run_number();
  if (run_id != run_id2)
    {
      throw cet::exception("HDF5RawInput3_source.cc") << " Inconsistent run IDs in file attribute and trigger record header " << run_id << " " << run_id2;
    }

  // check that the trigger record number in the header agrees with what we are expecting

  auto trhtn = trh->get_trigger_number();
  if (nextEventRecordID.first != trhtn)
    {
      throw cet::exception("HDF5RawInput3_source.cc") << " Inconsistent trigger record numbers: " << nextEventRecordID.first << " " << trhtn;
    }
  
  // trigTimeStamp is NOT time but Clock-tick since the epoch.

  uint64_t trigTimeStamp = trh->get_trigger_timestamp();
  if (fLogLevel > 0)
    {
      std::cout << "HDF5RawInput3_source: Trigger Time Stamp: " << trigTimeStamp << std::endl;
    }
    
  uint64_t getTrigTime = formatTrigTimeStampWithFrequency(trigTimeStamp, fClockFreqMHz);
  if (fLogLevel > 0)
    {
      std::cout << "HDF5RawInput3_source: getTrigTime: " << getTrigTime << std::endl;
    }

  art::Timestamp artTrigStamp (getTrigTime);
  if (fLogLevel > 0)
    {
      std::cout << "HDF5RawInput3_source: artTrigStamp: " <<   artTrigStamp.value()<< std::endl;
    }

  std::unique_ptr<raw::RDTimeStamp> rd_timestamp(
                                                 new raw::RDTimeStamp(trigTimeStamp));

  // make new run if inR is 0 or if the run has changed
  if (inR == 0 || inR->run() != run_id) {
    outR = pmaker.makeRunPrincipal(run_id,artTrigStamp);
  }

  // make new subrun if inSR is 0 or if the subrun has changed
  art::SubRunID subrun_check(run_id, 1);
  if (inSR == 0 || subrun_check != inSR->subRunID()) {
    outSR = pmaker.makeSubRunPrincipal(run_id, 1, artTrigStamp);
  }

  // this is the trigger record ID:

  int event = nextEventRecordID.first;
  if ( fHandleSequenceOption == "increment" )
    {
      event = fLastEvent + 1;
      if (fLogLevel > 0)
	{
	  std::cout << "HDF5RawInput3_source: assigning event number via incrment: " << event << " orig: " << nextEventRecordID.first << " " << nextEventRecordID.second;
	}
    }
  else if ( fHandleSequenceOption == "shiftadd" )
    {
      event = event*fTrnScale + nextEventRecordID.second;
      if (fLogLevel > 0)
	{
	  std::cout << "HDF5RawInput3_source: assigning event number via shfitadd: " << event << " orig: " << nextEventRecordID.first << " " << nextEventRecordID.second;
	}
    }
  else if ( fHandleSequenceOption == "ignore" )
    {
      if (fLogLevel > 0)
	{
	  std::cout << "HDF5RawInput3_source: assigning event number ignoring seqID: " << event << " orig: " << nextEventRecordID.first << " " << nextEventRecordID.second;
	}
    }
  else
    {
      throw cet::exception("HDF5RawInput3_source.cc") << "Ununderstood HandleSequenceOption: " << fHandleSequenceOption << " use: ignore, increment or shiftadd";
    }
  fLastEvent = event;

  outE = pmaker.makeEventPrincipal(run_id, 1, event, artTrigStamp);
  if (fLogLevel > 0)
    {
      std::cout << "HDF5RawInput3_source: Event Time Stamp :" << outE->time().value() << std::endl;
    }

 
  std::unique_ptr<raw::DUNEHDF5FileInfo2> the_info(
                                                   new raw::DUNEHDF5FileInfo2(rf->get_file_name(), run_id, nextEventRecordID.first,
                                                                              nextEventRecordID.second));

  put_product_in_principal(std::move(the_info), *outE, pretend_module_name,
                           "");
  put_product_in_principal(std::move(rd_timestamp), *outE, pretend_module_name,
                           "trigger");

  return true;
}

//typedef for shorthand
namespace dune {
  using HDF5RawInput3Source = art::Source<HDF5RawInput3Detail>;
}


DEFINE_ART_INPUT_SOURCE(dune::HDF5RawInput3Source)
