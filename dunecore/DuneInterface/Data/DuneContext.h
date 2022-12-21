// DuneContext.h
//
// David Adams
// December 2022
//
// Interface for context, the specifier for a unit of data processed
// independently. Conditions data can typically be selected based on
// this information.
//
// This generic interface is used to hold the context in the context
// manager and is used by many clients to access the data.
// Those needing more information can cast it up.

#ifndef DuneContext_H
#define DuneContext_H

class DuneContext {

public:

  using Index = unsigned int;

  // Value use to flag an undefined index.
  static Index badIndex() { return Index(-1); }

  // Dtor.
  virtual ~DuneContext() {};

  // Check if the context has been defined.
  virtual bool isValid() const { return getRun() != badIndex() && getEvent() != badIndex(); }

  // Return the run and event number.
  virtual Index getRun() const { return badIndex(); }
  virtual Index getEvent() const { return badIndex(); }

};

#endif
