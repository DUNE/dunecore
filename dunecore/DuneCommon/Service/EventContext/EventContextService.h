// EventContextService.h
//
// David Adams
// January 2023
//
// Service implementation for EventContextService.
//
// Configuration:
//   LogLevel - 0=quiet, 1=init, 2=run change, 3=event change

#ifndef EventContextService_H
#define EventContextService_H

// LArSoft libraries
#include "art/Framework/Services/Registry/ServiceDeclarationMacros.h"
#include "art/Framework/Services/Registry/ActivityRegistry.h"
#include <memory>

namespace art {
  class Run;
  class Event;
  class ScheduleContext;
}

class EventContextService {

public:

  using Index = unsigned int;

  // Ctor.
  EventContextService(const fhicl::ParameterSet& ps, art::ActivityRegistry& reg);

private:

  // React to a new run
  //void postBeginRun(art::Run const& run);

  // React to new event.
  void postSourceEvent(const art::Event&, art::ScheduleContext);

  Index m_LogLevel;

};

DECLARE_ART_SERVICE(EventContextService, SHARED)

#endif
