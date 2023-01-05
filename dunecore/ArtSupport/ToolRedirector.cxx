// ToolRedirector.cxx

#include "dunecore/ArtSupport/ToolRedirector.h"

//**********************************************************************

ToolRedirector::ToolRedirector(fhicl::ParameterSet const& ps) {
  if ( ! ps.has_key("tool_redirector") ) {
    throw ToolRedirector::MissingKeyException();
  }
}

//**********************************************************************

ToolRedirector::~ToolRedirector() { }

//**********************************************************************

const char* ToolRedirector::MissingKeyException::MissingKeyException::what() const throw() {
  return "Implementations of ToolRedirector must provide the fcl key \"tool_redirector\"";
}

//**********************************************************************
