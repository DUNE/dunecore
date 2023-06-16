// TextIndexMapTool_tool.cc

#include "TextIndexMapTool.h"
#include "dunecore/DuneCommon/Utility/StringManipulator.h"
#include "fhiclcpp/make_ParameterSet.h"
#include "TSystem.h"
#include <fstream>
#include <iostream>
#include <iomanip>

using std::cout;
using std::endl;
using std::setw;
using std::ifstream;
using std::getline;
using String = std::string;
using Index = TextIndexMapTool::Index;
using StringVector = std::vector<String>;

//**********************************************************************

TextIndexMapTool::TextIndexMapTool(fhicl::ParameterSet const& ps)
: m_LogLevel(ps.get<Index>("LogLevel")),
  m_FileName(ps.get<String>("FileName")),
  m_FieldSeparators(ps.get<String>("FieldSeparators")),
  m_IndexIndex(ps.get<Index>("IndexIndex")),
  m_ValueIndex(ps.get<Index>("ValueIndex")),
  m_DefaultValue(ps.get<Index>("DefaultValue")) {
  const String myname = "TextIndexMapTool::ctor: ";
  // Open the file.  See if we can open it as is, otherwise look in FW_SEARCH_PATH
  // this is set up in case the current working directory is not (yet) added to FW_SEARCH_PATH
  // in order to make the unit test work.
  const char* pcfnam = nullptr;
  String pcfnamestr;
  try {
    FILE *fptr = fopen(m_FileName.c_str(),"r");
    if (fptr)
      {
	pcfnam = m_FileName.c_str();
	fclose(fptr);
      }
    else
      {
        cet::search_path sp("FW_SEARCH_PATH");
        sp.find_file(m_FileName,pcfnamestr);
        pcfnam = pcfnamestr.c_str();
      }
  } catch(...) {
    cout << myname << "ERROR: Unable to parse file name:" << m_FileName << endl;
    return;
  }
  if ( pcfnam == nullptr ) {
    cout << myname << "ERROR: Unable to find file " << m_FileName << endl;
    return;
  }
  String sfnam(pcfnam);
  ifstream fin(pcfnam);
  if ( ! fin.is_open() ) {
    cout << myname << "ERROR: Unable to open file " << m_FileName << endl;
    if ( sfnam != m_FileName ) {
      cout << myname << "ERROR:         Expanded to " << sfnam << endl;
    }
    return;
  }
  String line;
  // Find separators.
  String seps = m_FieldSeparators;
  if ( seps.size() == 0 ) seps = " ";
  // Find position indices.
  Index ipos = m_IndexIndex;
  Index vpos = m_ValueIndex;
  Index mpos = std::max(ipos, vpos);
  Index iidx = 0;
  Index ival = 0;
  // Loop over lines in the file.
  if ( m_LogLevel >= 2 ) {
    cout << myname << "Fetching values." << endl;
  }
  Index nbad = 0;
  Index ndup = 0;
  while ( getline(fin, line) ) {
    if ( line.size() == 0 ) continue;
    if ( line[0] == '#' ) continue;
    String emsg = "";
    StringVector svals = StringManipulator(line).split(seps);
    if ( svals.size() > mpos ) {
      String sidx = svals[ipos];
      String sval = svals[vpos];
      try {
        iidx = std::stoi(sidx);
      } catch(...) {
        emsg = "String conversion failed for \"" + sidx + "\".";
      }
      try {
        ival = std::stoi(sval);
      } catch(...) {
        emsg = "String conversion failed for \"" + sval + "\".";
      }
    } else {
      emsg = "Too few values on line.";
    }
    if ( emsg.size() ) {
      if ( m_LogLevel >= 1 ) {
        cout << myname << "WARNING: Skipping bad line: \"" << line << "\" (" << emsg << ")" << endl;
      }
      ++nbad;
    } else {
      if ( m_map.count(iidx) ) {
        if ( m_LogLevel >= 1 ) {
          cout << myname << "WARNING: Replacing duplicate index " << iidx << endl;
        }
        ++ndup;
      }
      if ( m_LogLevel >= 2 ) {
        cout << myname << "  " << iidx << ": " << ival << endl;
      }
      m_map[iidx] = ival;
    }
  }
  // Display the parameters and result summary.
  if ( m_LogLevel >= 1 ) {
    cout << myname << "        LogLevel: " << m_LogLevel << endl;
    cout << myname << "        FileName: " << m_FileName << endl;
    if ( sfnam != m_FileName ) {
      cout << myname << "             (" << sfnam << ")" << endl;
    }
    cout << myname << " FieldSeparators: \"" << m_FieldSeparators << "\"";
    if ( seps != m_FieldSeparators ) cout << " (\"" << seps << "\")";
    cout << endl;
    cout << myname << "      IndexIndex: " << m_IndexIndex << endl;
    cout << myname << "      ValueIndex: " << m_ValueIndex << endl;
    cout << myname << "    DefaultValue: " << m_DefaultValue << endl;
    cout << myname << "              Map size: " << m_map.size() << endl;
    cout << myname << "        Bad line count: " << nbad << endl;
    cout << myname << "  Duplicate line count: " << ndup << endl;
  }
}

//**********************************************************************

Index TextIndexMapTool::get(Index iidx) const {
  const String myname = "TextIndexMapTool::get: ";
  IndexMap::const_iterator ient = m_map.find(iidx);
  if ( ient == m_map.end() ) return m_DefaultValue;
  return ient->second;
}

//**********************************************************************

DEFINE_ART_CLASS_TOOL(TextIndexMapTool)
