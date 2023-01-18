// DuneContextToolRedirector.cxx

#include "dunecore/DuneCommon/Utility/DuneContextToolRedirector.h"
#include "dunecore/DuneCommon/Utility/DuneContextManager.h"

using Name = DuneContextToolRedirector::Name;
using Content = DuneContextToolRedirector::Context;

//**********************************************************************

DuneContextToolRedirector::DuneContextToolRedirector(fhicl::ParameterSet const& ps)
: ToolRedirector(ps) { }

//**********************************************************************

Name DuneContextToolRedirector::getName() const {
  DuneContextManager* pcm = DuneContextManager::instance();
  const Context* pcon = pcm->context();
  return getNameInContext(pcon);
}

//**********************************************************************
