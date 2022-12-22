// DuneContextManager.h
//
// David Adams
// December 2022
//
// This class provides access to DUNE context, meaning global data that remain
// valid for well-delineated processing periods. For HEP, this would typically
// include run and event numbers.
//
// The class is a singleton in a single-threaded environment but it is envisioned
// that a separate context would be maintained for each thread in an MT environment.

#ifndef DuneContextManager_H
#define DuneContextManager_H

#include "dunecore/DuneInterface/Data/DuneContext.h"
#include <memory>

class DuneContextManager {

public:  // Types.

  using Context = DuneContext;

public:  // Class methods

  static DuneContextManager* instance();

public:  // Object methods

  // Set the context.
  // Caller creates the object on the heap and relinquishes ownership.
  // Ther previous context is destroyed.
  void setContext(const Context*);

  // Return the current context generically.
  const Context* context() const;
  
  // Return the current context promoted to the specified type.
  // Returns 0 if the context exists and is promoted.
  template<class T>
  const T* fullContext() const { return dynamic_cast<const T*>(context()); }

private:  // Data.

  static DuneContextManager* m_instance;
  std::unique_ptr<const Context> m_pcon;

};

#endif
