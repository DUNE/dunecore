////////////////////////////////////////////////////////////////////////
// Class:       HDF5RawFile2Service
// Plugin Type: service (Unknown Unknown)
// File:        HDF5RawFile2Service.h
//
// Generated at Tue Nov 15 16:04:29 2022 by Thomas Junk using cetskelgen
// from  version .
////////////////////////////////////////////////////////////////////////

#ifndef DUNEHDF5RawFile2Service_H
#define DUNEHDF5RawFile2Service_H

#include "art/Framework/Services/Registry/ActivityRegistry.h"
#include "art/Framework/Services/Registry/ServiceMacros.h"
#include "fhiclcpp/ParameterSet.h"
#include "dunecore/HDF5Utils/dunedaqhdf5utils2/HDF5RawDataFile.hpp"

namespace dune
{

  class HDF5RawFile2Service {
  public:
    explicit HDF5RawFile2Service(fhicl::ParameterSet const& p, art::ActivityRegistry& areg);
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

DECLARE_ART_SERVICE(dune::HDF5RawFile2Service, LEGACY)

// DUNEHDF5RawFile2Service_H
#endif 
