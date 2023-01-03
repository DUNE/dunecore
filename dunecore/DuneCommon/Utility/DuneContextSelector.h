// DuneContextSelector.h
//
// Interface for a utility or tool that uses a context to select a name.

#ifndef DuneContextSelector_H
#define DuneContextSelector_H

#include "dunecore/DuneInterface/Data/DuneContext.h"
#include <string>

class DuneContextSelector {

public:

  using Name = std::string;
  using Context = DuneContext;

  // Dtor.
  virtual ~DuneContextSelector() {}

  // Return name based on context.
  // Pointer is passed so implementation can cast and can handle
  // missing context (null pointer).
  virtual Name getName(const Context* pcon) const =0;

  // Get context from the context manager and call the above method.
  virtual Name getName() const;

};

#endif
