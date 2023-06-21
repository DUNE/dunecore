//Written by Andrew Olivier, aoliv23@lsu.edu, on 4/12/2016
//Demonstrates how to multiply matrices in ROOT, then writes the original matrices and their product to a gdml file.  

//standard library includes
#include <iostream> //std::cout

//ROOT includes
#include "TGeoMatrix.h"
#include "TGeoManager.h"
#include "TGeoVolume.h"
#include "TGeoBoolNode.h"
#include "TGeoCompositeShape.h"
#include "TMath.h"

void RotExample() //rotations in degrees
{
  // Double_t thetaYZ = 11.671;
  // Double_t thetaXZ = 10.578;

  Double_t thetaYZ = 45.0;
  Double_t thetaXZ = 7.7;

  Double_t BeamTheta = TMath::RadToDeg()*TMath::ATan(TMath::Sqrt(pow(TMath::Tan(TMath::DegToRad()*thetaXZ),2) + pow(TMath::Tan(TMath::DegToRad()*thetaYZ),2)));
  Double_t BeamPhi   = TMath::RadToDeg()*TMath::ATan(TMath::Tan(TMath::DegToRad()*thetaYZ)/TMath::Tan(TMath::DegToRad()*thetaXZ));
  cout<<"BeamTheta="<<BeamTheta<<",  BeamPhi="<<BeamPhi<<"\n"; 

  TGeoManager* out = new TGeoManager("rotEx", "Rotation Example");

  //Very annoying for this example: TGeoManager seems to require that I define a world volume, so let's use our new matrix!
  TGeoMaterial* matVac = new TGeoMaterial("Vacuum", 0, 0, 0);
  TGeoMedium* vac = new TGeoMedium("Vacuum", 1, matVac);
  TGeoMaterial* matal = new TGeoMaterial("Aluminium", 26.98, 13, 2.7);
  TGeoMedium* alum = new TGeoMedium("Aluminium", 1, matal);

  TGeoVolume* world = gGeoManager->MakeBox("volworld", vac, 50., 50., 50.);
  gGeoManager->SetTopVolume(world);

  //Set up first rotation
  //Note: TGeoRotation::SetAngles(double theta, double phi, double psi) supposedly rotates by Euler angles
  TGeoTranslation* origin = new TGeoTranslation(0, 0, 0);
  TGeoRotation* r1 = new TGeoRotation();
  r1->SetName("MyXRotation"); //Next two lines in case this helps to find these matrics in gdml form
  r1->SetTitle("MyXRotation");
  r1->RotateY(BeamTheta); //rotation about x axis in degrees
//  r1->RotateY(90); //rotation about x axis in 90 degrees

  //Set up second rotation
  TGeoRotation* r2 = new TGeoRotation();
  r2->SetName("MyYRotation");
  r2->SetTitle("MyYRotation");
  r2->RotateZ(-BeamPhi); //rotation about y axis in degrees

  TGeoRotation* ident = new TGeoRotation();
  ident->SetName("MyRotation");
  ident->SetTitle("MyRotation");
  ident->RotateZ(0.); 

  TGeoRotation* r3 = new TGeoRotation();
  r3->SetName("MyZRotation");
  r3->SetTitle("MyZRotation");
  r3->RotateZ(90.);

  //Brief Version: To multiply geometry matrices in ROOT, we apparently need to make a TGeoHMatrix out of one of them

  //Long Version: TGeoMatrix, the base class of TGeoRotation, TGeoTranslation, and TGeoScale, can only be multiplied with operator *()! But, to call operator *,  //we need a TGeoMatrix object.  All we have so far are pointers to derived types.  So, while we could dynamic_cast TGeoRotation* to a TGeoMatrix* and then 
  //dereference to call operator *, I think it is much easier, and much easier to understand what I am doing, if I construct a TGeoHMatrix pointer and use 
  //TGeoHMatrix::Multiply(TGeoMatrix&).  

  TGeoHMatrix* hr1 = new TGeoHMatrix(*r2);
  hr1->SetName("MyXYRotation");
  hr1->SetTitle("MyXYRotation");
  hr1->Multiply(r1);

  TGeoHMatrix* hr3 = new TGeoHMatrix(*r1);
  hr3->SetName("MyXZRotation");
  hr3->SetTitle("MyXZRotation");
  hr3->Multiply(r3);


  TGeoHMatrix* iden = new TGeoHMatrix(*ident);
  iden->SetName("MyIden");
  iden->SetTitle("MyIden");

  
  //Print matrices to stdout before printing to gdml
  std::cout << "Y rotation matrix:\n";
  r1->Print();
  
  std::cout << "Z rotation matrix:\n";
  r2->Print();
  
  std::cout << "(X matrix)*(Y matrix):\n";
  hr1->Print();
  std::cout << "(X matrix)*(Y matrix):\n";
  hr3->Print();

  //Also very annoying: I cannot get TGeoManager to write matrices to the output gdml file that are not used, so making a dummy volume
//  TGeoVolume* dummyBox1 = gGeoManager->MakeBox("voldummyBox1", vac, 1., 1., 1.);
//  world->AddNode(dummyBox1, 1, r1);

//  TGeoVolume* dummyBox2 = gGeoManager->MakeBox("voldummyBox2", vac, 1., 1., 1.);
//  world->AddNode(dummyBox2, 2, r2);

  TGeoMaterial *mat = new TGeoMaterial("Vacuum",0,0,0);
  TGeoMedium *med = new TGeoMedium("Vacuum",1,mat);
  Double_t nlow[3];
  Double_t nhi[3];
  Double_t thetalow = (180 - BeamTheta)*TMath::DegToRad();
  Double_t philow = 180*TMath::DegToRad();
  Double_t thetahigh = BeamTheta*TMath::DegToRad();
  Double_t phihigh = 0*TMath::DegToRad();
  // Double_t cylZ = 50./TMath::Cos(thetalow);
  Double_t cylZ = 183./TMath::Cos(thetalow);
  cout << "cylZ = " << cylZ << endl;

  nlow[0] = TMath::Sin(thetalow)*TMath::Cos(philow);
  nlow[1] = TMath::Sin(thetalow)*TMath::Sin(philow);
  nlow[2] = TMath::Cos(thetalow);
  nhi[0] = TMath::Sin(thetahigh)*TMath::Cos(phihigh);
  nhi[1] = TMath::Sin(thetahigh)*TMath::Sin(phihigh);
  nhi[2] = TMath::Cos(thetahigh);
  cout<<"thetalow = "<<thetalow<<", philow = "<<philow<<", nlow0 = "<< nlow[0] <<", nlow1 = "<< nlow[1] <<", nlow2 = "<< nlow[2]<<endl; 
  cout<<"thetahigh = "<<thetahigh<<", phihigh = "<<phihigh<<", nhi0 = "<< nhi[0] <<", nhi1 = "<< nhi[1] <<", nhi2 = "<< nhi[2]<<endl;
  TGeoVolume *dummyCyl = gGeoManager->MakeCtub("voldummyCyl",med,0.,25., cylZ, 0.,360.,nlow[0], nlow[1], nlow[2], nhi[0],nhi[1],nhi[2]);


//  TGeoVolume* dummyBoxh1 = gGeoManager->MakeBox("voldummyBoxh1", vac, 10., 10., 10.);
  world->AddNode(dummyCyl, 1, hr1);
//  world->AddNode(dummyCyl, 1, iden);
  TGeoSubtraction* boxTubeSubBool = new TGeoSubtraction(world->GetShape(), dummyCyl->GetShape(), origin, hr1);
  TGeoCompositeShape* boxTubeSubShape = new TGeoCompositeShape("boxTubeSubShape", boxTubeSubBool);
  TGeoVolume* boxTubeSubVol = new TGeoVolume("boxTubeSubVol", boxTubeSubShape, alum);
// gGeoManager->SetTopVolume(boxTubeSubVol);
//  world->AddNode(boxTubeSubVol, 1, iden);

  out->Export("RotationExample2.gdml");
  out->SetTopVisible();
  boxTubeSubVol->Draw();
}
