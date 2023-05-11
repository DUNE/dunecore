// test_TextIndexMapTool.cxx
//
// David Adams
// April 2020
//
// Test TextIndexMapTool.

#include "dunecore/ArtSupport/DuneToolManager.h"
#include "dunecore/DuneInterface/Tool/IndexMapTool.h"
#include <string>
#include <iostream>
#include <fstream>

#undef NDEBUG
#include <cassert>

using std::string;
using std::cout;
using std::endl;
using std::map;
using std::ofstream;
using fhicl::ParameterSet;
using Index = unsigned int;

//**********************************************************************

int test_TextIndexMapTool(bool useExistingFcl =false) {
  const string myname = "test_TextIndexMapTool: ";
#ifdef NDEBUG
  cout << myname << "NDEBUG must be off." << endl;
  abort();
#endif
  string line = "-----------------------------";

  cout << myname << line << endl;
  string fclfile = "test_TextIndexMapTool.fcl";
  string txtfile = "test_TextIndexMapTool.txt";
  Index badval = 9999;
  if ( ! useExistingFcl ) {
    cout << myname << "Creating top-level FCL." << endl;
    ofstream fout(fclfile.c_str());
    fout << "tools: {" << endl;
    fout << "  mytool: {" << endl;
    fout << "    tool_type: TextIndexMapTool" << endl;
    fout << "    LogLevel: 1" << endl;
    fout << "    FileName: \"./" << txtfile << "\"" << endl;
    fout << "    FieldSeparators: " << "\" ,\"";
    fout << "    IndexIndex: 0" << endl;
    fout << "    ValueIndex: 2" << endl;
    fout << "    DefaultValue: " << badval << endl;
    fout << "  }" << endl;
    fout << "}" << endl;
    fout.close();
  }
  if ( ! useExistingFcl ) {
    cout << myname << "Creating text file." << endl;
    ofstream fout(txtfile.c_str());
    fout << "  1 abc  1001" << endl;
    fout << "2,22,1002 11" << endl;
    fout << " 3 three, 1003  extra" << endl;
    fout << "    4 , four,1004" << endl;
  } else {
    cout << myname << "Using existing top-level FCL." << endl;
  }

  cout << myname << line << endl;
  cout << myname << "Fetching tool manager." << endl;
  DuneToolManager* ptm = DuneToolManager::instance(fclfile);
  assert ( ptm != nullptr );
  DuneToolManager& tm = *ptm;
  tm.print();
  assert( tm.toolNames().size() >= 1 );

  cout << myname << line << endl;
  cout << myname << "Fetching tool." << endl;
  auto ptoo = tm.getPrivate<IndexMapTool>("mytool");
  assert( ptoo != nullptr );

  std::map<Index,Index> exp;
  for ( Index idx=1; idx<=4; ++idx ) {
    exp[idx] = 1000 + idx;
  }
  exp[11] = badval;
  cout << myname << line << endl;
  cout << myname << "Checking map." << endl;
  for ( const auto& ent : exp ) {
    Index idx = ent.first;
    Index expval = ent.second;
    Index val = ptoo->get(idx);
    cout << "   " << idx << ": " << val << " ?= " << expval << endl;
    assert( val == expval );
  }

  cout << myname << line << endl;
  cout << myname << "Done." << endl;
  return 0;
}

//**********************************************************************

int main(int argc, char* argv[]) {
  bool useExistingFcl = false;
  if ( argc > 1 ) {
    string sarg(argv[1]);
    if ( sarg == "-h" ) {
      cout << "Usage: " << argv[0] << " [keepFCL]" << endl;
      cout << "  If keepFCL = true, existing FCL file is used." << endl;
      return 0;
    }
    useExistingFcl = sarg == "true" || sarg == "1";
  }
  return test_TextIndexMapTool(useExistingFcl);
}

//**********************************************************************
