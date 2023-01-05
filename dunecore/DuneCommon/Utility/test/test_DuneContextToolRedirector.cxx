// test_DuneContextToolRedirector.cxx
//
// David Adams
// January 2023
//
// Test the interfaces ToolRedirector, DuneContext and DuneContextToolRedirector.

#include <string>
#include <iostream>
#include <fstream>
#include "dunecore/DuneCommon/Utility/DuneContextManager.h"
#include "dunecore/DuneCommon/Utility/DuneContextToolRedirector.h"

#undef NDEBUG
#include <cassert>

using std::string;
using std::cout;
using std::endl;
using Name = std::string;
using Context = DuneContext;
using Index = Context::Index;
using ContextToolRedirector = DuneContextToolRedirector;

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

class TestContextToolRedirector : public DuneContextToolRedirector {
public:
  TestContextToolRedirector(fhicl::ParameterSet const& ps) : DuneContextToolRedirector(ps) { }
  ~TestContextToolRedirector() { }
  Name getNameInContext(const Context* pcon) const {
    const TestContext* ptcon = dynamic_cast<const TestContext*>(pcon);
    if ( ptcon == nullptr ) return "ERROR: Not TestContext";
    return ptcon->getLabel() + std::to_string(pcon->getRun());
  }
};

}  // end unamed namespace

//**********************************************************************

int test_DuneContextToolRedirector(bool useExistingFcl =false) {
  const string myname = "test_RunData: ";
#ifdef NDEBUG
  cout << myname << "NDEBUG must be off." << endl;
  abort();
#endif
  string line = "-----------------------------";

  cout << myname << line << endl;
  cout << myname << "Create and set context." << endl;
  TestContext* ptcon = new TestContext("tool", 123);
  DuneContextManager::instance()->setContext(ptcon);
  const TestContext& con = *ptcon;
  const DuneContext* pcon = ptcon;
  Name lab = con.getLabel();
  Index run = con.getRun();
  assert( lab == "tool" );
  assert( run == 123 );

  cout << myname << line << endl;
  cout << myname << "Creating context selector." << endl;
  fhicl::ParameterSet ps;
  ps.put("tool_redirector");
  TestContextToolRedirector sel(ps);

  cout << myname << line << endl;
  cout << myname << "Use context selector with explicit context." << endl;
  Name nam = sel.getNameInContext(pcon);
  cout << "Label " << lab << " for run " << run << " returns " << nam << endl;
  assert( nam == "tool123" );

  cout << myname << line << endl;
  cout << myname << "Call without explicit context." << endl;
  nam = sel.getName();
  cout << "Label " << lab << " for run " << run << " returns " << nam << endl;
  assert( nam == "tool123" );

  cout << myname << line << endl;
  cout << myname << "Call as redirector context." << endl;
  ToolRedirector* prd = dynamic_cast<ToolRedirector*>(&sel);
  assert( prd != nullptr );
  nam = prd->getName();
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
  return test_DuneContextToolRedirector();
}

//**********************************************************************
