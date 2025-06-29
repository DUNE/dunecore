#include "ProducerUtils.h"

namespace producer
{
    ProducerUtils::ProducerUtils(fhicl::ParameterSet const &p)
        : fGeometry(p.get<std::string>("Geometry"))
    {
    }

    void ProducerUtils::ComputeDistanceX(double &ClusterDistance, double t1, double t2, float driftLength, float driftTime)
    {
        // Use time in us to return the distance in cm
        ClusterDistance = abs(t1 - t2) * driftLength / driftTime;
    }

    void ProducerUtils::ComputeDistance3D(double &ClusterDistance, double t1, double y1, double z1, double t2, double y2, double z2, float driftLength, float driftTime)  
    {
        double x12 = 0; // This will be the distance in X in cm
        ComputeDistanceX(x12, t1, t2, driftLength, driftTime);
        ClusterDistance = sqrt(pow(x12, 2) + pow(y1 - y2, 2) + pow(z1 - z2, 2));
    }

    //......................................................
    // This function fills a map with the MCParticles from a given MCTruth
    void ProducerUtils::FillMyMaps(std::map<int, simb::MCParticle> &MyMap, art::FindManyP<simb::MCParticle> Assn, art::ValidHandle<std::vector<simb::MCTruth>> Hand)
    {
        for (size_t L1 = 0; L1 < Hand->size(); ++L1)
        {
        for (size_t L2 = 0; L2 < Assn.at(L1).size(); ++L2)
        {
            const simb::MCParticle ThisPar = (*Assn.at(L1).at(L2));
            MyMap[abs(ThisPar.TrackId())] = ThisPar;
        }
        }
        return;
    }

    //......................................................
    // This function returns the type of generator particle that produced a given MCTruth
    long unsigned int ProducerUtils::WhichGeneratorType(std::vector<std::map<int, simb::MCParticle>> GeneratorParticles, int TrID)
    {
        for (long unsigned int i = 0; i < GeneratorParticles.size(); i++)
        {
        if (InMyMap(TrID, GeneratorParticles[i]))
        {
            return i + 1;
        }
        }
        return 0; // If no match, then who knows???
    }

    //......................................................
    // This function checks if a given TrackID is in a given map
    bool ProducerUtils::InMyMap(int TrID, std::map<int, simb::MCParticle> ParMap)
    {
        std::map<int, simb::MCParticle>::iterator Particle;
        Particle = ParMap.find(TrID);
        if (Particle != ParMap.end())
        {
        return true;
        }
        else
        return false;
    }

    bool ProducerUtils::InMyMap(int TrID, std::map<int, float> TrackIDMap)
    {
        std::map<int, float>::iterator Particle;
        Particle = TrackIDMap.find(TrID);
        if (Particle != TrackIDMap.end())
        {
        return true;
        }
        else
        return false;
    }

    // This function creates a terminal color printout
    void ProducerUtils::PrintInColor(std::string MyString, int Color, std::string Type)
    {
        if (Type == "Info")
        {
            mf::LogInfo("ProducerUtils") << "\033[" << Color << "m" << MyString << "\033[0m";
        }
        if (Type == "Debug")
        {
            mf::LogDebug("ProducerUtils") << "\033[" << Color << "m" << MyString << "\033[0m";
        }
        if (Type == "Warning")
        {
            mf::LogWarning("ProducerUtils") << "\033[" << Color << "m" << MyString << "\033[0m";
        }
        if (Type == "Error")
        {
            mf::LogError("ProducerUtils") << "\033[" << Color << "m" << MyString << "\033[0m";
        }
        return;
    }

    // ......................................................
    // This function returns an integer that corresponds to a given color name
    int ProducerUtils::GetColor(std::string ColorName)
    {
        // Make color name lowercase
        std::transform(ColorName.begin(), ColorName.end(), ColorName.begin(), ::tolower);
        if (ColorName == "default")
            return 39;
        else
        if (ColorName == "black")
            return 30;
        else if (ColorName == "red")
            return 31;
        else if (ColorName == "green")
            return 32;
        else if (ColorName == "yellow")
            return 33;
        else if (ColorName == "blue")
            return 34;
        else if (ColorName == "magenta")
            return 35;
        else if (ColorName == "cyan")
            return 36;
        else if (ColorName == "white")
            return 37;
        else if (ColorName == "bright_black")
            return 90;
        else if (ColorName == "bright_red")
            return 91;
        else if (ColorName == "bright_green")
            return 92;
        else if (ColorName == "bright_yellow")
            return 93;
        else if (ColorName == "bright_blue")
            return 94;
        else if (ColorName == "bright_magenta")
            return 95;
        else if (ColorName == "bright_cyan")
            return 96;
        else if (ColorName == "bright_white")
            return 97;
        else
        {
            mf::LogError("ProducerUtils") << "Color " << ColorName << " not recognized. Returning white.";
            return 37;
        }
        return 0;
    }

    std::string ProducerUtils::str(int i)
    {
        std::stringstream ss;
        ss << i;
        return ss.str();
    }
    std::string ProducerUtils::str(bool i)
    {
        std::string j = "";
        if (i)
            j = "true";
        else
            j = "false";
        std::stringstream ss;
        ss << j;
        return ss.str();
    }
    std::string ProducerUtils::str(size_t i)
    {
        std::stringstream ss;
        ss << int(i);
        return ss.str();
    }
    std::string ProducerUtils::str(double i, int prec)
    {
        // Use prec to define the precision of the output in terms of number of decimal places
        std::stringstream ss;
        ss << std::fixed << std::setprecision(prec) << i;
        return ss.str();
    }
    std::string ProducerUtils::str(float i, int prec)
    {
        std::stringstream ss;
        ss << std::fixed << std::setprecision(prec) << i;
        return ss.str();
    }
    std::string ProducerUtils::str(std::vector<int> i)
    {
        std::stringstream ss;
        for (int j = 0; j < int(i.size()); j++)
        {
            ss << i[j] << " ";
        }
        return ss.str();
    }
    std::string ProducerUtils::str(std::vector<double> i, int prec)
    {
        std::stringstream ss;
        for (int j = 0; j < int(i.size()); j++)
        {
            ss << std::fixed << std::setprecision(prec) << i[j] << " ";
        }
        return ss.str();
    }
    std::string ProducerUtils::str(std::vector<float> i, int prec)
    {
        std::stringstream ss;
        for (int j = 0; j < int(i.size()); j++)
        {
            ss << std::fixed << std::setprecision(prec) << i[j] << " ";
        }
        return ss.str();
    }

    int ProducerUtils::supress_stdout()
    {
        std::fflush(stdout);

        int ret = dup(1);
        int nullfd = open("/dev/null", O_WRONLY);
        // check nullfd for error omitted
        dup2(nullfd, 1);
        close(nullfd);

        return ret;
    }

    void ProducerUtils::resume_stdout(int fd)
    {
        std::fflush(stdout);
        dup2(fd, 1);
        close(fd);
    }
    
    //......................................................
    double ProducerUtils::Sum(std::vector<double> Vec)
    {
        double Sum = 0;
        for (double Val : Vec)
        {
        Sum += Val;
        }
        return Sum;
    }
    float ProducerUtils::Sum(std::vector<float> Vec)
    {
        float Sum = 0;
        for (float Val : Vec)
        {
        Sum += Val;
        }
        return Sum;
    }

    //......................................................
    double ProducerUtils::Average(std::vector<double> Vec)
    {
        double sum = Sum(Vec);
        return sum / Vec.size();
    }
    float ProducerUtils::Average(std::vector<float> Vec)
    {
        float sum = Sum(Vec);
        return sum / Vec.size();
    }

    //......................................................
    double ProducerUtils::STD(std::vector<double> Vec)
    {
        double Mean = Average(Vec);
        double Sum = 0;
        for (double Val : Vec)
        {
        Sum += (Val - Mean) * (Val - Mean);
        }
        return sqrt(Sum / Vec.size());
    }
    float ProducerUtils::STD(std::vector<float> Vec)
    {
        float Mean = Average(Vec);
        float Sum = 0;
        for (float Val : Vec)
        {
        Sum += (Val - Mean) * (Val - Mean);
        }
        return sqrt(Sum / Vec.size());
    }
}