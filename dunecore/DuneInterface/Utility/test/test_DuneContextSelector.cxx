// test_DuneContextSelector.cxx
//
// David Adams
// December 2022
//
// Test the interfaces DuneContext and DuneContextSelector.

#include <string>
#include <iostream>
#include <fstream>
#include "dunecore/DuneInterface/Utility/DuneContextSelector.h"

#undef NDEBUG
#include <cassert>

using std::string;
using std::cout;
using std::endl;
using Name = std::string;
using Context = DuneContext;
using Index = Context::Index;
using ContextSelector = DuneContextSelector;

namespace {

class TestContext : public DuneContext {
  Name m_lab;
  Index m_run;
public:
  TestContext(Name lab, Index run) : m_lab(lab), m_run(run) { }
  ~TestContext() {}
  bool valid() const { return getRun() != badIndex(); }
  Name getLabel() const { return m_lab; }
  Index getRun() const { return m_run; }
};

class TestContextSelector {
public:
  TestContextSelector() { }
  ~TestContextSelector() { }
  Name getName(const Context* pcon) const {
    const TestContext* ptcon = dynamic_cast<const TestContext*>(pcon);
    if ( ptcon == nullptr ) return "ERROR: Not TestContext";
    return ptcon->getLabel() + std::to_string(pcon->getRun());
  }
};

}  // end unamed namespace

//**********************************************************************

int test_DuneContextSelector(bool useExistingFcl =false) {
  const string myname = "test_RunData: ";
#ifdef NDEBUG
  cout << myname << "NDEBUG must be off." << endl;
  abort();
#endif
  string line = "-----------------------------";

  cout << myname << line << endl;
  cout << myname << "Creating context selector." << endl;
  TestContextSelector sel;

  cout << myname << line << endl;
  cout << myname << "Create and use context selector." << endl;
  TestContext con("tool", 123);
  Name lab = con.getLabel();
  Index run = con.getRun();
  assert( lab == "tool" );
  assert( run == 123 );
  const DuneContext* pcon = &con;
  assert( pcon->getRun() == 123 );
  Name nam = sel.getName(pcon);
  cout << "Label " << lab << " for run " << run << " returns " << nam << endl;
  assert( nam == "tool123" );

  cout << myname << line << endl;
  cout << myname << "Done." << endl;
  return 0;
}

//**********************************************************************

int main(int argc, char* argv[]) {
  if ( argc > 1 ) {
    string sarg(argv[1]);
    if ( sarg == "-h" ) {
      cout << "Usage: " << argv[0];
      return 0;
    }
  }
  return test_DuneContextSelector();
}

//**********************************************************************
