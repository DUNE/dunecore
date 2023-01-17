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
#include "dunecore/ChannelStatus/ToolBasedChannelStatus.h"
#include <memory>

namespace art {
  class Run;
}

class ToolBasedChannelStatusService : public lariov::ChannelStatusService {

public:

  // Constructor: reads the channel IDs from the configuration
  ToolBasedChannelStatusService(fhicl::ParameterSet const& ps);

private:

  virtual lariov::ChannelStatusProvider& const DoGetProvider() const override {
    return *DoGetProviderPtr();
  }
  virtual lariov::ChannelStatusProvider* const DoGetProviderPtr() const override {
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
