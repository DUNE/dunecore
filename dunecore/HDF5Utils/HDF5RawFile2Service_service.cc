////////////////////////////////////////////////////////////////////////
// Class:       HDF5RawFile2Service
// Plugin Type: service (Unknown Unknown)
// File:        HDF5RawFile2Service_service.cc
//
// Generated at Tue Nov 15 16:04:29 2022 by Thomas Junk using cetskelgen
// from  version .
////////////////////////////////////////////////////////////////////////

#include "art/Framework/Services/Registry/ActivityRegistry.h"
#include "art/Framework/Services/Registry/ServiceMacros.h"
#include "fhiclcpp/ParameterSet.h"
#include "dunecore/HDF5Utils/HDF5RawFile2Service.h"

// constructor

dune::HDF5RawFile2Service::HDF5RawFile2Service(fhicl::ParameterSet const& p, art::ActivityRegistry& areg)
// :
// Initialize member data here.
{
}

// sets the pointer and assumes ownership of it

void dune::HDF5RawFile2Service::SetPtr(std::unique_ptr<dunedaq::hdf5libs::HDF5RawDataFile> fileptr)
{
  fRawDataFilePtr = std::move(fileptr);
}

// gets a non-owning copy of the file pointer

dunedaq::hdf5libs::HDF5RawDataFile* dune::HDF5RawFile2Service::GetPtr()
{
  return fRawDataFilePtr.get();
}

void dune::HDF5RawFile2Service::Close()
{
  fRawDataFilePtr.reset();
}


DEFINE_ART_SERVICE(dune::HDF5RawFile2Service)
