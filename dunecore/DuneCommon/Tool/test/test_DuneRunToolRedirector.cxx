// test_DuneRunToolRedirector.cxx
//
// David Adams
// January 2023
//
// Test DuneRunToolRedirector.

#include "dunecore/DuneCommon/Utility/DuneContextToolRedirector.h"
#include "dunecore/DuneInterface/Data/DuneEventInfo.h"
#include "dunecore/ArtSupport/DuneToolManager.h"
#include "TH1F.h"
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>

#undef NDEBUG
#include <cassert>

using std::string;
using std::cout;
using std::endl;
using std::ofstream;
using std::istringstream;
using std::setw;
using std::vector;
using fhicl::ParameterSet;
using Index = unsigned int;

//**********************************************************************

int test_DuneRunToolRedirector(bool redirect, bool useExistingFcl) {
  const string myname = "test_DuneRunToolRedirector: ";
#ifdef NDEBUG
  cout << myname << "NDEBUG must be off." << endl;
  abort();
#endif
  string line = "-----------------------------";

  string defnam = "no-such-tool";
  string sredirect = redirect ? "true" : "false";
  cout << myname << line << endl;
  string fclfile = "test_DuneRunToolRedirector.fcl";
  if ( ! useExistingFcl ) {
    cout << myname << "Creating top-level FCL." << endl;
    ofstream fout(fclfile.c_str());
    fout << "tools: {" << endl;
    fout << "  mytool: {" << endl;
    fout << "    tool_type: DuneRunToolRedirector" << endl;
    fout << "    tool_redirector: " << sredirect << endl;
    fout << "    LogLevel: 2" << endl;
    fout << "    DefaultName: \"" << defnam << "\"" << endl;
    fout << "    Ranges: [" << endl;
    fout << "               \"100:120:tool100\"," << endl;
    fout << "               \"120:130:tool120\"," << endl;
    fout << "               \"115:125:tool115\"" << endl;
    fout << "            ]" << endl;
    fout << "  }" << endl;
    fout << "}" << endl;
    fout.close();
  } else {
    cout << myname << "Using existing top-level FCL." << endl;
  }

  Index nrun = 200;
  vector<string> exps(nrun, defnam);
  for ( Index i=100; i<120; ++i ) exps[i] = "tool100";
  for ( Index i=120; i<130; ++i ) exps[i] = "tool120";
  for ( Index i=115; i<125; ++i ) exps[i] = "tool115";

  cout << myname << line << endl;
  cout << myname << "Fetching tool manager." << endl;
  DuneToolManager* ptm = DuneToolManager::instance(fclfile);
  assert ( ptm != nullptr );
  DuneToolManager& tm = *ptm;
  tm.print();
  assert( tm.toolNames().size() >= 1 );

  cout << myname << line << endl;
  cout << myname << "Fetching tool." << endl;
  auto mytool = tm.getPrivate<DuneContextToolRedirector>("mytool");
  assert( mytool != nullptr );

  cout << myname << line << endl;
  cout << "Check mapping with redirect = " << sredirect << "." << endl;
  for ( Index run=0; run<nrun; ++run ) {
    DuneEventInfo dei(run, 1);
    string nam = mytool->getNameInContext(&dei);
    if ( run > 90 && run < 150 ) cout << myname << setw(6) << run << ": " << nam << endl;
    assert( nam == exps[run] );
  }
  
  cout << myname << line << endl;
  cout << myname << "Done." << endl;
  return 0;
}

//**********************************************************************

int main(int argc, char* argv[]) {
  bool useExistingFcl = false;
  bool redirect = false;
  if ( argc > 1 ) {
    string sarg(argv[1]);
    if ( sarg == "-h" ) {
      cout << "Usage: " << argv[0] << " [redirect] [keepfcl]" << endl;
      cout << "  If redirect is true, tool redirection is performed." << endl;
      cout << "  If keepfck is true the existing fcl is used" << endl;
      return 0;
    }
    redirect = sarg == "true" || sarg == "1";
  }
  if ( argc > 2 ) {
    string sarg(argv[2]);
    useExistingFcl = sarg == "true" || sarg == "1";
  }
  return test_DuneRunToolRedirector(redirect, useExistingFcl);
}

//**********************************************************************
