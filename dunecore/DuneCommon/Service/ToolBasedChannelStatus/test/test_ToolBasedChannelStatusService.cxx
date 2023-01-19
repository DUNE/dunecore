// test_ToolBasedChannelStatusService.cxx

// David Adams
// Januarey 2023
//
// Test ToolBasedChannelStatusService.

#include "../ToolBasedChannelStatusService.h"
#include <string>
#include <iostream>
#include <sstream>
#include <fstream>
#include <iomanip>
#include "dunecore/ArtSupport/ArtServiceHelper.h"
#include "dunecore/DuneServiceAccess/DuneServiceAccess.h"

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

int test_ToolBasedChannelStatusService() {
  const string myname = "test_ToolBasedChannelStatusService: ";
#ifdef NDEBUG
  cout << myname << "NDEBUG must be off." << endl;
  abort();
#endif
  const string line = "-----------------------------";

  Index ncha = 20;

  cout << myname << line << endl;
  string fclfile = "test_ChannelStatusConfigTool.fcl";
  cout << myname << "Creating top-level FCL." << endl;
  ofstream fout(fclfile.c_str());
  fout << "tools: {" << endl;
  fout << "  mytool: {" << endl;
  fout << "    tool_type: ChannelStatusConfigTool" << endl;
  fout << "    LogLevel: 1" << endl;
  fout << "    DefaultIndex: 0" << endl;
  fout << "    IndexVectors: [" << endl;
  fout << "      []," << endl;
  fout << "      [ 0,  8, 16]," << endl;
  fout << "      [ 4, 12]" << endl;
  fout << "    ]" << endl;
  fout << "  }" << endl;
  fout << "}" << endl;
  fout.close();

  cout << myname << line << endl;
  cout << myname << "Loading services." << endl;
  std::ostringstream oss;
  oss << "services: {" << endl;
  oss << "  mysvc: {" << endl;
  oss << "    service_provider: \"ToolBasedChannelStatusService\"" << endl;
  oss << "    LogLevel: 1" << endl;
  oss << "    NChannel: " << ncha << endl;
  oss << "    ToolName: mytool" << endl;
  oss << "  }" << endl;
  oss << "}" << endl;
  ArtServiceHelper::load_services(oss.str());

  cout << myname << line << endl;
  cout << myname << "Fetch ChannelStatus service and provider." << endl;
  ServiceHandle<lariov::ChannelStatusService> hcss;
  const lariov::ChannelStatusProvider* pcsp = hcss->provider();
  assert( pcsp != nullptr );

  cout << myname << line << endl;
  cout << myname << "Check in-range channels." << endl;
  for ( Index icha=0; icha<ncha; ++icha ) {
    cout << setw(4) << icha << ": " << pcsp->Status(icha) << endl;
  }

/*
  unsigned int ngrp = hcgs->size();
  cout << myname << "Check group count: " << ngrp << endl;
  assert( ngrp == 2 );

  cout << myname << line << endl;
  cout << myname << "Group names and channels:" << endl;
  for ( unsigned int igrp=0; igrp<ngrp; ++igrp ) {
    string name = hcgs->name(igrp);
    const vector<ChannelGroupService::Index> chans = hcgs->channels(igrp);
    cout << myname << "  " << setw(10) << name << ":";
    for ( ChannelGroupService::Index chan : chans ) cout << setw(6) << chan;
    cout << endl;
    assert( name.size() );
    assert( name != "NoSuchGroup" );
    assert( chans.size() );
  }

  cout << myname << line << endl;
  cout << myname << "Fetch ChannelGroupService by pointer." << endl;
  ChannelGroupService* pcgs = ArtServicePointer<ChannelGroupService>();
  pcgs->print(cout, myname);
*/

  cout << myname << line << endl;
  cout << myname << "Done." << endl;
  return 0;
}

int main(int argc, char* argv[]) {
  if ( argc > 1 ) {
    cout << "Usage: " << argv[0] << endl;
  }
  return test_ToolBasedChannelStatusService();
}
