// LarsoftServiceAccess.cxx

#include "LarsoftServiceAccess.h"
#include "dunecore/ArtSupport/ArtServicePointer.h"
#include "dunecore/ArtSupport/ArtServiceProvider.h"

#include "larcore/Geometry/Geometry.h"
#include "larevt/CalibrationDBI/Interface/ChannelStatusService.h"

//**********************************************************************

// Geometry is special. It derives from its provider.

template<>
const GeometryCore* ArtServiceProvider<geo::GeometryCore>() {
  return GenericArtServicePointer<geo::Geometry>();
}

//**********************************************************************

template<>
const ChannelStatusProvider* ArtServiceProvider<lariov::ChannelStatusProvider>() {
  return DefaultArtServiceProvider<lariov::ChannelStatusService>();
}

//**********************************************************************
