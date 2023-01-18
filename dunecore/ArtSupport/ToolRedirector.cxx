// ToolRedirector.cxx

#include "dunecore/ArtSupport/ToolRedirector.h"
using std::string;

//**********************************************************************
// Static members.
//**********************************************************************

bool ToolRedirector::hasRedirection(fhicl::ParameterSet const& ps) noexcept {
  bool isred;
  try { ps.get_if_present(key(), isred); }
  catch(...) { return false; }
  return true;
}

//**********************************************************************

bool ToolRedirector::isRedirecting(fhicl::ParameterSet const& ps) noexcept {
  bool isred = false;
  try { ps.get_if_present(key(), isred); }
  catch(...) { }
  return isred;
}

//**********************************************************************
// Non-staic members.
//**********************************************************************

ToolRedirector::ToolRedirector(fhicl::ParameterSet const& ps) {
  if ( ! ps.has_key(key()) ) {
    throw FhiclException(string("Fcl key \"") + key() + "\" not found.");
  }
  if ( ! hasRedirection(ps) ) {
    throw FhiclException(string("Fcl key \"") + key() + "\" must be boolean.");
  }
}

//**********************************************************************

ToolRedirector::~ToolRedirector() { }

//**********************************************************************

ToolRedirector::FhiclException::FhiclException(string msg)
: m_msg(msg) { }
  
//**********************************************************************

const char* ToolRedirector::FhiclException::what() const noexcept {
  return m_msg.c_str();
}

//**********************************************************************
