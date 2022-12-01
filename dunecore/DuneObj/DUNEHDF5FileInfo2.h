#ifndef DUNEHDF5FileInfo2_h
#define DUNEHDF5FileInfo2_h
#include <string>

namespace raw {
  class DUNEHDF5FileInfo2 {
  public:
  DUNEHDF5FileInfo2(std::string filename, uint32_t run, size_t event, size_t sequence)
    : fFileName(filename), fRun(run),
      fEvent(event), fSequence(sequence) {};
    DUNEHDF5FileInfo2(std::initializer_list<DUNEHDF5FileInfo2>) {};

    const std::string & GetFileName() const {return fFileName;};
    const uint32_t & GetRun() const {return fRun;};
    const size_t & GetEvent() const {return fEvent;};
    const size_t & GetSequence() const {return fSequence;};

  private:
    std::string fFileName;
    uint32_t fRun;
    size_t   fEvent;
    size_t   fSequence;
  };
}
#endif
