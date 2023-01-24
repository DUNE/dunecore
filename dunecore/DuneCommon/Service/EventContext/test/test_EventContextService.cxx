// test_EventContextService.cxx

// David Adams
// Januarey 2023
//
// Test EventContextService.

#include "../EventContextService.h"
#include <string>
#include <iostream>
#include <sstream>
#include <fstream>
#include <iomanip>
#include "dunecore/ArtSupport/ArtServiceHelper.h"
#include "dunecore/DuneServiceAccess/DuneServiceAccess.h"
#include "dunecore/DuneCommon/Utility/DuneContextManager.h"
#include "../EventContextService.h"

using std::string;
using std::cout;
using std::endl;
using std::istringstream;
using std::ostringstream;
using std::ofstream;
using std::setw;
using std::vector;
using art::ServiceHandle;
using Index = unsigned int;

#undef NDEBUG
#include <cassert>

void setevt(EventContextService& ecss) {
  //artEvent(
}

int test_EventContextService() {
  const string myname = "test_EventContextService: ";
#ifdef NDEBUG
  cout << myname << "NDEBUG must be off." << endl;
  abort();
#endif
  const string line = "-----------------------------";

  cout << myname << line << endl;
  cout << myname << "Loading services." << endl;
  std::ostringstream oss;
  oss << "services: {" << endl;
  oss << "  mysvc: {" << endl;
  oss << "    service_provider: \"EventContextService\"" << endl;
  oss << "    LogLevel: 3" << endl;
  oss << "  }" << endl;
  oss << "}" << endl;
  ArtServiceHelper::load_services(oss.str());

  cout << myname << line << endl;
  cout << myname << "Fetch event status service." << endl;
  ServiceHandle<EventContextService> hect;
  const EventContextService* pect = hect.get();
  assert( pect != nullptr );

  cout << myname << line << endl;
  cout << myname << "Check context before events." << endl;
  assert( DuneContextManager::instance() != nullptr );
  const DuneContext* pctx = DuneContextManager::instance()->context();
  assert( pctx == nullptr );

  cout << myname << "Done." << endl;
  return 0;
}

int main(int argc, char* argv[]) {
  if ( argc > 1 ) {
    cout << "Usage: " << argv[0] << endl;
  }
  return test_EventContextService();
}
