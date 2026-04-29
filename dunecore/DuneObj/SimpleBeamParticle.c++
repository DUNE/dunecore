#include "SimpleBeamParticle.h"

SimpleBeamParticle::SimpleBeamParticle(DetectorHolder * holder, std::string name) {
    TrackID = static_cast<int>(holder->TrackID);
    PDGid = static_cast<int>(holder->PDGid);
    EventID = static_cast<int>(holder->EventID);
    ParentID = static_cast<int>(holder->ParentID);
    detectors.push_back(name);
    x.push_back(holder->x);
    y.push_back(holder->y);
    z.push_back(holder->z);
    t.push_back(holder->t);
    Px.push_back(holder->Px);
    Py.push_back(holder->Py);
    Pz.push_back(holder->Pz);
}

void SimpleBeamParticle::merge(DetectorHolder * holder, std::string name, int overall_event) {
        if (/*PDGid != 22 &&*/
            ((TrackID != static_cast<int>(holder->TrackID)) ||
            (PDGid != static_cast<int>(holder->PDGid)) ||
            (EventID != static_cast<int>(holder->EventID)) || 
            (ParentID != static_cast<int>(holder->ParentID)))
            /*std::find(detectors.begin(), detectors.end(), name) != detectors.end()*/) {
                std::cerr << "(" << overall_event << ") This part: " << *this << "\nInput: (" << name << ") " << (*holder) << std::endl; 
                throw std::runtime_error("ATTEMPTING TO MERGE INVALID PARTS");
            }
        detectors.push_back(name);
        x.push_back(holder->x);
        y.push_back(holder->y);
        z.push_back(holder->z);
        t.push_back(holder->t);
        Px.push_back(holder->Px);
        Py.push_back(holder->Py);
        Pz.push_back(holder->Pz);
    }

std::ostream& operator<<(std::ostream& os, const SimpleBeamParticle& obj) {
    os << "\tTrackID: " << obj.TrackID << "\n" <<
          "\tPDGid: " << obj.PDGid << "\n" <<
          "\tEventID: " << obj.EventID << "\n" <<
          "\tParentID: " << obj.ParentID << "\n";
          for (size_t i = 0; i < obj.detectors.size(); ++i) {
            os << "\t\t" << obj.detectors[i] << " " << obj.x[i] << " " << obj.y[i] << " " << obj.z[i] << " " << obj.t[i] << " " << obj.Px[i] << " " << obj.Py[i] << " " << obj.Pz[i] << "\n";
          }
    return os;
}