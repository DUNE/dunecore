////////////////////////////////////////////////////////////////////////
// Class:       HDF5RawFile3Service
// Plugin Type: service (Unknown Unknown)
// File:        HDF5RawFile3Service_service.cc
//
// This is essentially a copy of HDF5RawFile2Service_service.cc with an include of the
// raw data file header in dunedaqhdf5utils3, which has changed format in April 2024
// with respect to the older one in dunedaqhdf5utils2.
////////////////////////////////////////////////////////////////////////

#include "art/Framework/Services/Registry/ActivityRegistry.h"
#include "art/Framework/Services/Registry/ServiceMacros.h"
#include "fhiclcpp/ParameterSet.h"
#include "dunecore/HDF5Utils/HDF5RawFile3Service.h"

// constructor

dune::HDF5RawFile3Service::HDF5RawFile3Service(fhicl::ParameterSet const& p, art::ActivityRegistry& areg)
// :
// Initialize member data here.
{
}

// sets the pointer and assumes ownership of it

void dune::HDF5RawFile3Service::SetPtr(std::unique_ptr<dunedaq::hdf5libs::HDF5RawDataFile> fileptr)
{
  fRawDataFilePtr = std::move(fileptr);
}

// gets a non-owning copy of the file pointer

dunedaq::hdf5libs::HDF5RawDataFile* dune::HDF5RawFile3Service::GetPtr()
{
  return fRawDataFilePtr.get();
}

void dune::HDF5RawFile3Service::Close()
{
  fRawDataFilePtr.reset();
}


DEFINE_ART_SERVICE(dune::HDF5RawFile3Service)
