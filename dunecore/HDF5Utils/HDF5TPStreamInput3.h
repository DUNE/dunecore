// Input source for the second HDF5 file format version from the DAQ people
// using the DUNE-DAQ HDF5RawInputFile class

// This is a version of the HDF5TPStreamInput2.h with the new data format from dune-daq v4.4.0, April 23, 2024

#ifndef HDF5TPStreamInput3_h
#define HDF5TPStreamInput3_h
#include "art/Framework/Core/InputSourceMacros.h" 
#include "art/Framework/IO/Sources/Source.h" 
#include "art/Framework/IO/Sources/SourceTraits.h"
#include "art/Framework/Core/fwd.h"
#include "art/Framework/Core/FileBlock.h"
#include "art/Framework/Core/ProductRegistryHelper.h"
#include "art/Framework/IO/Sources/SourceHelper.h"
#include "art/Framework/IO/Sources/put_product_in_principal.h"
#include "art/Framework/Principal/EventPrincipal.h"
#include "art/Framework/Principal/RunPrincipal.h"
#include "art/Framework/Principal/SubRunPrincipal.h"
#include "art/Framework/Services/Registry/ServiceHandle.h"
#include "canvas/Persistency/Provenance/FileFormatVersion.h"
#include "messagefacility/MessageLogger/MessageLogger.h"
#include "fhiclcpp/ParameterSet.h"
#include "art/Framework/Services/Registry/ServiceHandle.h"
#include "dunecore/HDF5Utils/HDF5RawFile3Service.h"
#include "dunecore/HDF5Utils/HDF5Utils.h"

namespace dune {
//Forward declare the class
class HDF5TPStreamInput3Detail;
}

class dune::HDF5TPStreamInput3Detail {
 public:
  HDF5TPStreamInput3Detail(fhicl::ParameterSet const & ps,
                              art::ProductRegistryHelper & rh,
                              art::SourceHelper const & sh);

  void readFile(std::string const & filename, art::FileBlock*& fb);

  bool readNext(art::RunPrincipal const* const inR,
                art::SubRunPrincipal const* const inSR,
                art::RunPrincipal*& outR,
                art::SubRunPrincipal*& outSR,
                art::EventPrincipal*& outE);

  void closeCurrentFile() {
    art::ServiceHandle<dune::HDF5RawFile3Service> rawFileService;
    rawFileService->Close();
  };

 private:
  dunedaq::hdf5libs::HDF5RawDataFile::record_id_set fUnprocessedTimeSliceIDs;
  std::string pretend_module_name;
  int fLogLevel;
  double fClockFreqMHz;               // clock frequency in MHz -- used to unpack trigger timestamps for the event
  art::SourceHelper const& pmaker;
 };
#endif
