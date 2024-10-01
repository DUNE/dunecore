////////////////////////////////////////////////////////////////////////
// Class:       HDF5RawFile3service
// Plugin Type: service (Unknown Unknown)
// File:        HDF5RawFile3service.h
//
// This is essentially a copy of HDF5RawFile2Service.h with an include of the
// raw data file header in dunedaqhdf5utils3, which has changed format in April 2024
// with respect to the older one in dunedaqhdf5utils2.
////////////////////////////////////////////////////////////////////////

#ifndef DUNEHDF5RawFile3Service_H
#define DUNEHDF5RawFile3Service_H

#include "art/Framework/Services/Registry/ActivityRegistry.h"
#include "art/Framework/Services/Registry/ServiceMacros.h"
#include "fhiclcpp/ParameterSet.h"
#include "dunecore/HDF5Utils/dunedaqhdf5utils3/HDF5RawDataFile.hpp"

namespace dune
{

  class HDF5RawFile3Service {
  public:
    explicit HDF5RawFile3Service(fhicl::ParameterSet const& p, art::ActivityRegistry& areg);
    // The compiler-generated destructor is fine for non-base
    // classes without bare pointers or other resource use.

    // sets the pointer and assumes ownership of it

    void SetPtr(std::unique_ptr<dunedaq::hdf5libs::HDF5RawDataFile> fileptr);

    // gets a non-owning copy of the file pointer

    dunedaq::hdf5libs::HDF5RawDataFile *GetPtr();

    void Close();

  private:

    std::unique_ptr<dunedaq::hdf5libs::HDF5RawDataFile> fRawDataFilePtr;

  };

}

DECLARE_ART_SERVICE(dune::HDF5RawFile3Service, LEGACY)

// DUNEHDF5RawFile3Service_H
#endif 
