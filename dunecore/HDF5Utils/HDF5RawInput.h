#ifndef HDF5RawInput_h
#define HDF5RawInput_h
#include "art/Framework/Core/InputSourceMacros.h" 
#include "art/Framework/IO/Sources/Source.h" 
#include "art/Framework/IO/Sources/SourceTraits.h"
#include "art/Framework/Core/Frameworkfwd.h"
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
//#include "dune-raw-data/HDFUtils/HDFFileReader.hh"
#include "HDF5Utils.h"


//Is raw a good namespace?
namespace dune {
//Forward declare the class
class HDF5RawInputDetail;
}

class dune::HDF5RawInputDetail {
 public:
  HDF5RawInputDetail(fhicl::ParameterSet const & ps,
                              art::ProductRegistryHelper & rh,
                              art::SourceHelper const & sh);

  void readFile(std::string const & filename, art::FileBlock*& fb);

  bool readNext(art::RunPrincipal const* const inR,
                art::SubRunPrincipal const* const inSR,
                art::RunPrincipal*& outR,
                art::SubRunPrincipal*& outSR,
                art::EventPrincipal*& outE);

  void closeCurrentFile() {
    if (hdf_file_->filePtr)
      dune::HDF5Utils::closeFile(std::move(hdf_file_));
  };

 private:
  std::unique_ptr<dune::HDF5Utils::HDFFileInfo> hdf_file_;
  std::deque<std::string> unprocessedEventList_;
  std::string pretend_module_name;
  int fLogLevel;
  art::SourceHelper const& pmaker;
 };
#endif
