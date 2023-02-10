// EventContextService_service.cxx

#include "EventContextService.h"
#include "dunecore/DuneInterface/Data/DuneEventInfo.h"
#include "dunecore/DuneCommon/Utility/DuneContextManager.h"
#include "art/Framework/Principal/Event.h"
#include "art/Framework/Services/Registry/ServiceDefinitionMacros.h"

using std::string;
using std::cout;
using std::endl;
using art::Timestamp;

//**********************************************************************

EventContextService::EventContextService(const fhicl::ParameterSet& ps, art::ActivityRegistry& reg)
: m_LogLevel(ps.get<Index>("LogLevel")) {
  reg.sPostSourceEvent.watch(this, &EventContextService::postSourceEvent);
}

//**********************************************************************

void EventContextService::postSourceEvent(const art::Event& evt, art::ScheduleContext) {
  string myname = "EventContextService::postSourceEvent: ";
  DuneContextManager* pcm = DuneContextManager::instance();
  if ( pcm == nullptr ) {
    cout << myname << "WARNING: Context manager not found." << endl;
    return;
  }
  const DuneContext* pctx = pcm->context();
  bool haveOldContext = pctx != nullptr;
  Index irunOld = haveOldContext ? pctx->getRun() : 0;
  Index ievtOld = haveOldContext ? pctx->getEvent() : 0;
  Timestamp beginTime = evt.time();
  time_t itim = beginTime.timeHigh();
  int itimrem = beginTime.timeLow();
  // Older protoDUNE data has time in low field.
  if ( itim == 0 && itimrem != 0 ) {
    itimrem = itim;
    itim = beginTime.timeLow();
  }
  Index irun = evt.run();
  Index isru = evt.subRun();
  Index ievt = evt.event();
  if ( haveOldContext && irun == irunOld && ievt == ievtOld ) {
    cout << myname << "WARNING: Ignoring update with unchanged run-event " << irun << "-" << ievt << endl;
    return;
  }
  if ( m_LogLevel >= 3 ) {
    cout << myname << "INFO: Run-event " << irun << "-" << ievt << endl;
  } else if ( m_LogLevel >= 2 && irun != irunOld ) {
    cout << myname << "INFO: Run-event " << irun << "-" << ievt << endl;
  }
  pcm->setContext(new DuneEventInfo(irun, ievt, isru, itim, itimrem));
}

//**********************************************************************

DEFINE_ART_SERVICE(EventContextService)
