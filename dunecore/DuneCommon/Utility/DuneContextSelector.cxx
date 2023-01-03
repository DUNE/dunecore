// DuneContextSelector.cxx

#include "dunecore/DuneCommon/Utility/DuneContextSelector.h"
#include "dunecore/DuneCommon/Utility/DuneContextManager.h"

using Name = DuneContextSelector::Name;
using Content = DuneContextSelector::Context;

Name DuneContextSelector::getName() const {
  DuneContextManager* pcm = DuneContextManager::instance();
  const Context* pcon = pcm->context();
  return getName(pcon);
}
