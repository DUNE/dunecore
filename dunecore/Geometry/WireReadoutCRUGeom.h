////////////////////////////////////////////////////////////////////////
/// \file  WireReadoutCRUGeom.h
/// \brief Interface to channel algorithm class for a vertical drift TPC
///
/// \version $Id:  $
/// \author  vgalymov@ipnl.in2p3.fr
/// \Modified by lpaulucc@fnal.gov to include Optical Channel map
////////////////////////////////////////////////////////////////////////
#ifndef GEO_WIREREADOUTCRUGEOM_H
#define GEO_WIREREADOUTCRUGEOM_H

#include <vector>
#include <set>
#include <iostream>
#include <map>

#include "larcoreobj/SimpleTypesAndConstants/readout_types.h"
#include "larcoreobj/SimpleTypesAndConstants/geo_types.h"
#include "larcorealg/Geometry/WireReadoutGeom.h"
#include "fhiclcpp/fwd.h"

namespace geo{

  class WireReadoutCRUGeom : public WireReadoutGeom{

  public:


    explicit WireReadoutCRUGeom(fhicl::ParameterSet const& p, GeometryCore const* geom);

    std::vector<WireID>      ChannelToWire(raw::ChannelID_t channel)     const override;
    unsigned int             Nchannels()                                 const override;
    /// @brief Returns the number of channels in the specified ROP
    /// @return number of channels in the specified ROP, 0 if non-existent
    /// @todo Needs to be implemented
    virtual unsigned int Nchannels(readout::ROPID const& ropid) const override;



    //@{
    virtual double WireCoordinate
      (double YPos, double ZPos, geo::PlaneID const& planeID) const override;
    //@}

    //@{
    virtual WireID NearestWireID
      (const geo::Point_t& worldPos, geo::PlaneID const& planeID) const override;
    //@}

    //@{
    virtual raw::ChannelID_t PlaneWireToChannel
      (geo::WireID const& wireID) const override;
    //@}

    virtual SigType_t                SignalTypeForChannelImpl( raw::ChannelID_t const channel ) const override;
    virtual std::set<PlaneID> const& PlaneIDs()                                   const override;



    //
    // TPC set interface
    //
    /// @name TPC set mapping
    /// @{
    /**
     * @brief Returns the total number of TPC sets in the specified cryostat
     * @param cryoid cryostat ID
     * @return number of TPC sets in the cryostat, or 0 if no cryostat found
     */
    virtual unsigned int NTPCsets(readout::CryostatID const& cryoid) const override;

    /// Returns the largest number of TPC sets any cryostat in the detector has
    virtual unsigned int MaxTPCsets() const override;

    /// Returns whether we have the specified TPC set
    /// @return whether the TPC set is valid and exists
    virtual bool HasTPCset(readout::TPCsetID const& tpcsetid) const override;

    /// Returns the ID of the TPC set tpcid belongs to
    virtual readout::TPCsetID TPCtoTPCset(geo::TPCID const& tpcid) const override;

    /**
     * @brief Returns a list of ID of TPCs belonging to the specified TPC set
     * @param tpcsetid ID of the TPC set to convert into TPC IDs
     * @return the list of TPCs, empty if TPC set is invalid
     *
     * Note that the check is performed on the validity of the TPC set ID, that
     * does not necessarily imply that the TPC set specified by the ID actually
     * exists. Check the existence of the TPC set first (HasTPCset()).
     * Behaviour on valid, non-existent TPC set IDs is undefined.
     */
    virtual std::vector<geo::TPCID> TPCsetToTPCs
      (readout::TPCsetID const& tpcsetid) const override;

    /// Returns the ID of the first TPC belonging to the specified TPC set
    virtual geo::TPCID FirstTPCinTPCset
      (readout::TPCsetID const& tpcsetid) const override;

    /// @} TPC set mapping


    //
    // Readout plane interface
    //
    /// @name Readout plane mapping
    /// @{
    /**
     * @brief Returns the total number of ROP in the specified TPC set
     * @param tpcsetid TPC set ID
     * @return number of readout planes in the TPC set, or 0 if no TPC set found
     *
     * Note that this methods explicitly check the existence of the TPC set.
     */
    virtual unsigned int NROPs(readout::TPCsetID const& tpcsetid) const override;

    /// Returns the largest number of ROPs a TPC set in the detector has
    virtual unsigned int MaxROPs() const override;

    /// Returns whether we have the specified ROP
    /// @return whether the readout plane is valid and exists
    virtual bool HasROP(readout::ROPID const& ropid) const override;

    /// Returns the ID of the ROP planeid belongs to
    virtual readout::ROPID WirePlaneToROP
      (geo::PlaneID const& planeid) const override;

    /// Returns a list of ID of planes belonging to the specified ROP
    virtual std::vector<geo::PlaneID> ROPtoWirePlanes
      (readout::ROPID const& ropid) const override;

    /// Returns the ID of the first plane belonging to the specified ROP
    virtual geo::PlaneID FirstWirePlaneInROP
      (readout::ROPID const& ropid) const override;

    /**
     * @brief Returns a list of ID of TPCs the specified ROP spans
     * @param ropid ID of the readout plane
     * @return the list of TPC IDs, empty if readout plane ID is invalid
     *
     * Note that this check is performed on the validity of the readout plane
     * ID, that does not necessarily imply that the readout plane specified by
     * the ID actually exists. Check if the ROP exists with HasROP().
     * The behaviour on non-existing readout planes is undefined.
     */
    virtual std::vector<geo::TPCID> ROPtoTPCs
      (readout::ROPID const& ropid) const override;

    /// Returns the ID of the ROP the channel belongs to
    /// @throws cet::exception (category: "Geometry") if non-existent channel
    virtual readout::ROPID ChannelToROP(raw::ChannelID_t channel) const override;

    /**
     * @brief Returns the ID of the first channel in the specified readout plane
     * @param ropid ID of the readout plane
     * @return ID of first channel, or raw::InvalidChannelID if ID is invalid
     *
     * Note that this check is performed on the validity of the readout plane
     * ID, that does not necessarily imply that the readout plane specified by
     * the ID actually exists. Check if the ROP exists with HasROP().
     * The behaviour for non-existing readout planes is undefined.
     */
    virtual raw::ChannelID_t FirstChannelInROP
      (readout::ROPID const& ropid) const override;

    /// @} Readout plane mapping

    /// Photon detectors
    unsigned int NOpChannels(unsigned int NOpDets)                           const override;
    unsigned int MaxOpChannel(unsigned int NOpDets)                          const override;
    unsigned int NOpHardwareChannels(unsigned int opDet)                     const override;
    unsigned int OpChannel(unsigned int OpDet, unsigned int hwCh)            const override;
    unsigned int OpDetFromOpChannel(unsigned int opChannel)                  const override;
    unsigned int HardwareChannelFromOpChannel(unsigned int opChannel)        const override;
    bool  IsValidOpChannel(unsigned int opChannel, unsigned int /*NOpDets*/) const override
    {return fOpDet.count(opChannel); }

  private:

    unsigned int                  fNcryostat;      ///< number of cryostats in the detector
    unsigned int                  fNchannels;      ///< number of channels in the detector
    raw::ChannelID_t              fTopChannel;     ///< book keeping highest channel #
    std::vector<unsigned int>     fNTPC;           ///< number of TPCs in each cryostat
    std::set<View_t>              fViews;          ///< vector of the views present in the detector
    std::set<PlaneID>             fPlaneIDs;       ///< vector of the PlaneIDs present in the detector
    PlaneInfoMap_t<float>         fFirstWireProj;  ///< Distance (0,0,0) to first wire
                                                   ///< along orth vector per plane per TPC
    PlaneInfoMap_t<float>         fOrthVectorsY;   ///< Unit vectors orthogonal to wires in
    PlaneInfoMap_t<float>         fOrthVectorsZ;   ///< each plane - stored as 2 components
                                                   ///< to avoid having to invoke any bulky
                                                   ///< TObjects / CLHEP vectors etc
    PlaneInfoMap_t<float>         fWireCounts;     ///< Number of wires in each plane - for
                                                   ///< range checking after calculation
    TPCInfoMap_t<unsigned int>    fNPlanes;        ///< Number of planes in each TPC - for
                                                   ///< range checking after calculation
    PlaneInfoMap_t<unsigned int>  fPlaneBaselines; ///< The number of wires in all the
                                                   ///< tpcs and planes up to this one
                                                   ///< in the heirachy
    PlaneInfoMap_t<unsigned int>  fWiresPerPlane;  ///< The number of wires in this plane
                                                   ///< in the heirachy

    /// Photon detectors
    unsigned int fMaxOpDets;
    unsigned int fMaxOpChannel;
    unsigned int fNOpChannels;
    std::map<unsigned int, unsigned int> fOpDet;
    std::map<unsigned int, unsigned int> fHWChannel;

    /// Retrieved the wire cound for the specified plane ID
    unsigned int WireCount(geo::PlaneID const& id) const
    { return AccessElement(fWireCounts, id); }

    /// Returns the largest number of TPCs in a single cryostat
    unsigned int MaxTPCs() const;

    /// Converts a TPC ID into a TPC set ID using the same numerical indices
    static readout::TPCsetID ConvertTPCtoTPCset(geo::TPCID const& tpcid);

    /// Converts a TPC set ID into a TPC ID using the same numerical indices
    static geo::TPCID ConvertTPCsetToTPC(readout::TPCsetID const& tpcsetid);

    /// Converts a ROP ID into a wire plane ID using the same numerical indices
    static readout::ROPID ConvertWirePlaneToROP(geo::PlaneID const& planeid);

    /// Converts a wire plane ID into a ROP ID using the same numerical indices
    static geo::PlaneID ConvertROPtoWirePlane(readout::ROPID const& ropid);

  };
}
#endif // GEO_WIREREADOUTCRUGEOM_H
