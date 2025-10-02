#ifndef SIMPLEBEAMPARTICLE_H
#define SIMPLEBEAMPARTICLE_H
#include <iostream>
#include <map>
#include <TTree.h>
class DetectorHolder {

public:
    float x{0};
    float y{0};
    float z{0};
    float Px{0};
    float Py{0};
    float Pz{0};
    float t{0};
    float PDGid{0};
    float EventID{0};
    float TrackID{0};
    float ParentID{0};
    int current_event{0};
    bool done{false};
    std::map<std::string, float *> branches{
        {"x", &x},
        {"y", &y},
        {"z", &z},
        {"Px", &Px},
        {"Py", &Py},
        {"Pz", &Pz},
        {"t", &t},
        {"PDGid", &PDGid},
        {"EventID", &EventID},
        {"TrackID", &TrackID},
        {"ParentID", &ParentID}
    };
    // TTree * fTree = 0x0;
    void SetTree(TTree * tree) {
        // fTree = tree;
        for (auto & [key, ptr] : branches) {
            tree->SetBranchAddress(key.c_str(), ptr);
        }
    };

    friend std::ostream& operator<<(std::ostream& os, const DetectorHolder& obj) {
        os << "TrackID: " << obj.TrackID << "\n" <<
              "PDGid: " << obj.PDGid << "\n" <<
              "EventID: " << obj.EventID << "\n" <<
              "ParentID: " << obj.ParentID << "\n" <<
              "x: " << obj.x << "\n" <<
              "y: " << obj.y << "\n" <<
              "z: " << obj.z << "\n" <<
              "t: " << obj.t << "\n" <<
              "Px: " << obj.Px << "\n" <<
              "Py: " << obj.Py << "\n" <<
              "Pz: " << obj.Pz << "\n";
        return os;
    }
};


// class DetectorHolder;

struct SimpleBeamParticle {


    std::vector<float> x, y, z, Px, Py, Pz, t;
    std::vector<std::string> detectors;
    int PDGid{0}, EventID{0}, TrackID{0}, ParentID{0};

    SimpleBeamParticle(DetectorHolder * holder, std::string name);
    // SimpleBeamParticle(DetectorHolder * holder, std::string name) {
    //     TrackID = static_cast<int>(holder->TrackID);
    //     PDGid = static_cast<int>(holder->PDGid);
    //     EventID = static_cast<int>(holder->EventID);
    //     ParentID = static_cast<int>(holder->ParentID);

    //     detectors.push_back(name);
    //     x.push_back(holder->x);
    //     y.push_back(holder->y);
    //     z.push_back(holder->z);
    //     t.push_back(holder->t);
    //     Px.push_back(holder->Px);
    //     Py.push_back(holder->Py);
    //     Pz.push_back(holder->Pz);
    // }
    void merge(DetectorHolder * holder, std::string name, int overall_event);
    // void merge(DetectorHolder * holder, std::string name, int overall_event) {
    //     if (PDGid != 22 &&
    //         ((TrackID != static_cast<int>(holder->TrackID)) ||
    //         (PDGid != static_cast<int>(holder->PDGid)) ||
    //         (EventID != static_cast<int>(holder->EventID)) || 
    //         (ParentID != static_cast<int>(holder->ParentID)))
    //         /*std::find(detectors.begin(), detectors.end(), name) != detectors.end()*/) {
    //             std::cerr << "(" << overall_event << ") This part: " << *this << "\nInput: (" << name << ") " << (*holder) << std::endl; 
    //             throw std::runtime_error("ATTEMPTING TO MERGE INVALID PARTS");
    //         }
    //     detectors.push_back(name);
    //     x.push_back(holder->x);
    //     y.push_back(holder->y);
    //     z.push_back(holder->z);
    //     t.push_back(holder->t);
    //     Px.push_back(holder->Px);
    //     Py.push_back(holder->Py);
    //     Pz.push_back(holder->Pz);
    // }

    friend std::ostream& operator<<(std::ostream& os, const SimpleBeamParticle& obj);
    // friend std::ostream& operator<<(std::ostream& os, const SimpleBeamParticle& obj) {
    //     os << "\tTrackID: " << obj.TrackID << "\n" <<
    //           "\tPDGid: " << obj.PDGid << "\n" <<
    //           "\tEventID: " << obj.EventID << "\n" <<
    //           "\tParentID: " << obj.ParentID << "\n";
    //           for (size_t i = 0; i < obj.detectors.size(); ++i) {
    //             os << "\t\t" << obj.detectors[i] << " " << obj.x[i] << " " << obj.y[i] << " " << obj.z[i] << " " << obj.t[i] << " " << obj.Px[i] << " " << obj.Py[i] << " " << obj.Pz[i] << "\n";
    //           }
    //     return os;
    // }

    SimpleBeamParticle(){}
};
#endif