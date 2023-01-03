// test_DuneContextManager.cxx

#include "dunecore/DuneCommon/Utility/DuneContextManager.h"
#include "dunecore/DuneInterface/Data/DuneEventInfo.h"

#include <string>
#include <iostream>
#include <fstream>

using std::string;
using std::cout;
using std::endl;
using std::ofstream;

#undef NDEBUG
#include <cassert>

int test_DuneContextManager(bool useExistingFcl =false) {
  const string myname = "test_DuneContextManager: ";
  cout << myname << "Starting test" << endl;
#ifdef NDEBUG
  cout << myname << "NDEBUG must be off." << endl;
  abort();
#endif
  string line = "-----------------------------";
  string scfg;

  cout << line << endl;
  cout << myname << "Retrieve context manager." << endl;
  DuneContextManager* pcm = DuneContextManager::instance();
  assert( pcm->context() == nullptr );

  cout << myname << line << endl;
  cout << myname << "Retrieve initial context." << endl;
  assert( pcm->context() == nullptr );

  cout << myname << line << endl;
  cout << myname << "Create event info." << endl;
  DuneEventInfo* pevi = new DuneEventInfo(123, 456);
  assert( pevi->getRun() == 123 );
  assert( pevi->getEvent() == 456 );
  DuneContext* pcon = pevi;
  assert( pcon->getRun() == 123 );
  assert( pcon->getEvent() == 456 );

  cout << myname << line << endl;
  cout << myname << "Set context." << endl;
  pcm->setContext(pevi);
  assert( pcm->context() != nullptr );
  assert( pcm->context()->getRun() == 123 );
  assert( pcm->context()->getEvent() == 456 );

  cout << myname << line << endl;
  cout << myname << "Done." << endl;
  return 0;
}

int main() {
  int rstat = test_DuneContextManager();
  return rstat;
}
