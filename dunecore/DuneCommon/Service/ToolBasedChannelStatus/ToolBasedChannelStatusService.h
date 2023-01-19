// ToolBasedChannelStatusService.h
//
// David Adams
// January 2023
//
// Service implementation for ToolBasedChannelStatusService.
//

#ifndef ToolBasedChannelStatusService_H
#define ToolBasedChannelStatusService_H

// LArSoft libraries
#include "art/Framework/Services/Registry/ServiceDeclarationMacros.h"
#include "larevt/CalibrationDBI/Interface/ChannelStatusService.h"
#include "ToolBasedChannelStatus.h"
#include <memory>

namespace art {
  class Run;
}

class ToolBasedChannelStatusService : public lariov::ChannelStatusService {

public:

  // Constructor: reads the channel IDs from the configuration
  ToolBasedChannelStatusService(const fhicl::ParameterSet& ps);

private:

  virtual const lariov::ChannelStatusProvider& DoGetProvider() const override {
    return *DoGetProviderPtr();
  }
  virtual const lariov::ChannelStatusProvider* DoGetProviderPtr() const override {
    return m_provider.get();
  }

  // React to a new run
  void postBeginRun(art::Run const& run);

  std::unique_ptr<ToolBasedChannelStatus> m_provider;

};

DECLARE_ART_SERVICE_INTERFACE_IMPL(ToolBasedChannelStatusService,
                                   lariov::ChannelStatusService,
                                   LEGACY)

#endif
