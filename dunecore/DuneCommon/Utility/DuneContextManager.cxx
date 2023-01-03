// DuneContextManagers_t.cxx

#include "dunecore/DuneCommon/Utility/DuneContextManager.h"

using Context = DuneContextManager::Context;

//******************************************************************************

DuneContextManager* DuneContextManager::m_instance = new DuneContextManager;

//******************************************************************************

DuneContextManager* DuneContextManager::instance() {
  return m_instance;
}

//******************************************************************************

void DuneContextManager::setContext(const Context* pcon) {
  m_pcon.reset(pcon);
}

//******************************************************************************

const Context* DuneContextManager::context() const {
  return m_pcon.get();
}

//******************************************************************************
