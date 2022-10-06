// duneRunData.cxx
//
// David Adams
// May 2018
//
// Executable that displays the run data for a run.

#include <string>
#include <iostream>
#include <vector>
#include <sstream>
#include <memory>
#include "dunecore/ArtSupport/DuneToolManager.h"
#include "dunecore/DuneInterface/Tool/RunDataTool.h"

using std::string;
using std::cout;
using std::endl;
using std::istringstream;

int main(int argc, char** argv) {
  const string myname = "duneRunData: ";
  bool help = false;
  bool longhelp = false;
  unsigned int irun = 0;
  bool verbose = false;
  string fname;
  if ( argc > 1 ) {
    for ( int iarg=1; iarg< argc; ++iarg ) {
      string sarg = argv[iarg];
      if ( sarg == "-h" ) {
        help = true;
        break;
      } else if ( sarg == "-H" ) {
        help = true;
        longhelp = true;
        break;
      }
      if ( sarg == "-v" ) verbose = true;
    }
    if ( ! help ) {
      string sarg = argv[argc-1];
      istringstream ssarg(sarg);
      ssarg >> irun;
      if ( irun == 0 ) {
        cout << myname << "ERROR: Last field does not appear to be a number: \""
             << sarg << "\"" << endl;
        return 1;
      }
    }
  } else {
    help = true;
  } 
  if ( help ) {
    cout << "Usage: duneRunData [-h] [-v] [-c FCLFILE] RUN" << endl;
    cout << "  Displays the fcl-based run info for run RUN." << endl;
    cout << "  -h - Display short help message." << endl;
    cout << "  -H - Display long help message." << endl;
    cout << "  -v - Verbose display including info about fcl file and run data tool." << endl;
    if ( longhelp ) {
      cout << "This run info is kept in fcl files." << endl;
      cout << "For ProtoDUNE-SP those are stored in" << endl;
      cout << "  dunesw/fcl/protodune/fcldirs/rundata/protodune" << endl;
      cout << "and installed in" << endl;
      cout << "  fcl/rundata/protodune" << endl;
      cout << "Schema are described at" << endl;
      cout << "  https://wiki.dunescience.org/wiki/ProtoDUNE_run_configuration#Schema" << endl;
    }
    return 0;
  }
  string tname = "protoduneRunDataTool";
  if ( ! verbose ) cout.setstate(std::ios_base::failbit);   // Turn off cout
  cout << endl;
  cout << myname << "Fetching tool manager." << endl;
  DuneToolManager* ptm = DuneToolManager::instance();
  cout << endl;
  cout << myname << "Fetching run data tool." << endl;
  const RunDataTool* prdt = ptm->getShared<RunDataTool>(tname);
  cout << endl;
  if ( ! verbose ) cout.clear();  // Turn cout back on.
  if ( prdt == nullptr ) {
    cout << myname << "ERROR: Unable to find RunDataTool " << tname << endl;
    return 1;
  }
  RunData rdat = prdt->runData(irun);
  if ( rdat.isValid() ) {
    cout << rdat << endl;
  } else {
    cout << myname << "Unable to find run " << irun << endl;
    return 2;
  }
  return 0;
}
