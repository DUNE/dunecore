// test_DuneEventInfo.cxx
//
// David Adams
// January 2020
//
// Test DuneEventInfo.

#include <string>
#include <iostream>
#include <fstream>
#include <vector>
#include "dunecore/DuneInterface/Data/DuneEventInfo.h"

#undef NDEBUG
#include <cassert>

using std::string;
using std::cout;
using std::endl;
using std::vector;

using Index = DuneContext::Index;

//**********************************************************************

int test_DuneEventInfo() {
  const string myname = "test_DuneEventInfo: ";
#ifdef NDEBUG
  cout << myname << "NDEBUG must be off." << endl;
  abort();
#endif
  string line = myname + "-----------------------------";

  cout << line << endl;
  cout << "Checking bad context." << endl;
  DuneEventInfo deibad;
  const DuneContext* pcon = &deibad;
  assert( ! deibad.isValid() );
  assert( ! pcon->isValid() );

  cout << line << endl;
  cout << "Checking good context." << endl;
  Index irun = 123;
  Index ievt = 456;
  DuneEventInfo dei(irun, ievt);
  pcon = &dei;
  cout << dei.runString() << endl;
  assert( dei.isValid() );
  assert( dei.run == irun );
  assert( dei.event == ievt );
  assert( dei.getRun() == irun );
  assert( dei.getEvent() == ievt );
  assert( pcon->getRun() == irun );
  assert( pcon->getEvent() == ievt );
  assert( pcon->isValid() );
  assert( dei.getRun() == irun );
  assert( pcon->getRun() == irun );
  assert( dei.getEvent() == ievt );
  assert( pcon->getEvent() == ievt );

  cout << line << endl;
  cout << myname << "All tests passed." << endl;
  return 0;
}

//**********************************************************************

int main(int argc, char* argv[]) {
  if ( argc > 1 ) {
    cout << "Usage: " << argv[0] << " [ARG]" << endl;
    return 0;
  }
  return test_DuneEventInfo();
}

//**********************************************************************
