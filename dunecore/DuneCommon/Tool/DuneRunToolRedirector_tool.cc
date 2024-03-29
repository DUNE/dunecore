// DuneRunToolRedirector_tool.cc

#include "DuneRunToolRedirector.h"
#include "dunecore/DuneCommon/Utility/StringManipulator.h"

#include <iostream>
#include <iomanip>

using std::cout;
using std::endl;
using std::setw;
using std::stoi;
using Name = std::string;
using Index = DuneRunToolRedirector::Index;

//**********************************************************************

DuneRunToolRedirector::DuneRunToolRedirector(fhicl::ParameterSet const& ps)
: DuneContextToolRedirector(ps),
  m_LogLevel(ps.get<Index>("LogLevel")),
  m_DefaultName(ps.get<Name>("DefaultName")),
  m_Ranges(ps.get<NameVector>("Ranges")),
  m_stage(0) {
  const Name myname = "DuneRunToolRedirector::ctor: ";
  if ( m_LogLevel >= 1 ) {
    cout << myname << "     LogLevel: " << m_LogLevel << endl;
    cout << myname << "  DefaultName: " << m_DefaultName << endl;
    cout << myname << "       Ranges: [";
    Name sep = "";
    for ( Name srannam : m_Ranges ) {
      cout << sep << "\n" << myname << "                " << srannam;
      sep = ",";
    }
    cout << "\n" << myname << "                ]" << endl;
  }
  // Build the map.
  m_names[0] = m_DefaultName;
  for ( Name srannam : m_Ranges ) {
    NameVector svals = StringManipulator(srannam).split(":", true);
    if ( svals.size() != 3 || svals[0].size() == 0 ) {
      cout << myname << "WARNING: Ignoring invalid range specifier: " << srannam << endl;
      continue;
    }
    Index run1 = stoi(svals[0]);
    Name srun2 = svals[1];
    bool have_run2 = srun2.size() > 0;
    Index run2 = have_run2 ? stoi(srun2) : 0;
    if ( have_run2 && run2 <= run1 ) {
      cout << myname << "WARNING: Ignoring range specifier with run2 <= run1: " << srannam << endl;
      continue;
    }
    Name nam = svals[2];
    if ( nam == "" ) nam = m_DefaultName;
    // If the new range is finite and there is not already an entry at run2,
    // we will have to add one to keep the remainder of that overlapped range.
    bool add_run2 = have_run2 && m_names.count(run2)==0;
    Name nam2 = add_run2 ? getNameFromRun(run2) : "logic-error";
    // Insert new name at run1.
    m_names[run1] = nam;
    // Remove the entries overlapped by the new entry.
    NameMap::iterator inam_delete = std::next(m_names.find(run1));
    NameMap::iterator inam_keep = have_run2 ? m_names.lower_bound(run2) : m_names.end();
    m_names.erase(inam_delete, inam_keep);
    // Replace the partially overlapped entry.
    if ( add_run2 ) m_names[run2] = nam2;
  }
  // Display the map.
  if (m_LogLevel >= 2 ) {
    cout << myname << "Tool name map:" << endl;
    int wrun = 12;
    cout << myname << setw(wrun) << "Run" << "  Tool name" << endl;
    for ( const auto& ent : m_names ) {
        cout << myname << setw(wrun) << ent.first << ": " << ent.second << endl;
    }
  }
  m_stage = 1;
}

//**********************************************************************

Name DuneRunToolRedirector::getNameFromRun(Index run) const {
  const Name myname = "DuneRunToolRedirector::get: ";
  NameMap::const_iterator irun_next = m_names.upper_bound(run);
  Name tnam = std::prev(irun_next)->second;
  // Display message always at level 4 and when running at level 3.
  if ( m_LogLevel >= 3 && ( m_LogLevel >=4 || m_stage==1 ) ) {
    cout << myname << "For run " << run << ", returning tool name " << tnam << endl;
  }
  return tnam;
}

//**********************************************************************

Name DuneRunToolRedirector::getNameInContext(const Context* pcon) const {
  const Name myname = "DuneRunToolRedirector::getNameInContext: ";
  bool running = m_stage == 1;
  if ( pcon == nullptr ) {
    if ( running ) cout << myname << "ERROR: Context not found." << endl;
    return m_DefaultName;
  }
  Index run = pcon->getRun();
  if ( run == DuneContext::badIndex() ) {
    if ( running ) cout << myname << "ERROR: Context does not have a run." << endl;
    return m_DefaultName;
  }
  return getNameFromRun(run);
}

//**********************************************************************

DEFINE_ART_CLASS_TOOL(DuneRunToolRedirector)
