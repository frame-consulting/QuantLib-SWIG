/*
 Copyright (C) 2018 Sebastian Schlenkrich

 This file is part of QuantLib, a free-software/open-source library
 for financial quantitative analysts and developers - http://quantlib.org/

 QuantLib is free software: you can redistribute it and/or modify it
 under the terms of the QuantLib license.  You should have received a
 copy of the license along with this program; if not, please email
 <quantlib-dev@lists.sf.net>. The license is also available online at
 <http://quantlib.org/license.shtml>.

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the license for more details.
*/

#ifndef quantlib_vanillalocalvolmodel_i
#define quantlib_vanillalocalvolmodel_i

%include common.i
%include date.i
%include daycounters.i
%include types.i
%include currencies.i
%include observer.i
%include marketelements.i
%include interpolation.i
%include indexes.i
%include optimizers.i
%include options.i

%include volatilities.i


%{
#include <ql/experimental/vanillalocalvolmodel/vanillalocalvolmodel.hpp>
#include <ql/experimental/vanillalocalvolmodel/vanillalocalvolsmilesection.hpp>
#include <ql/experimental/vanillalocalvolmodel/vanillalocalvoltermstructures.hpp>

using QuantLib::VanillaLocalVolModel;
using QuantLib::VanillaLocalVolModelSmileSection;
using QuantLib::VanillaLocalVolSwaptionVTS;
%}

// we need to tell SWIG to export shared_ptr with new classes
// %template(VanillaLocalVolModelBase) ext::shared_ptr<VanillaLocalVolModel>;
// %template(VanillaLocalVolModelSmileSectionBase) ext::shared_ptr<VanillaLocalVolModelSmileSection>;

// we need to tell C++ that our new pointer-based classes are type names
// %{
// typedef ext::shared_ptr<VanillaLocalVolModel> VanillaLocalVolModelPtr;
// typedef ext::shared_ptr<VanillaLocalVolModelSmileSection> VanillaLocalVolModelSmileSectionPtr;
// typedef ext::shared_ptr<VanillaLocalVolSwaptionVTS> VanillaLocalVolSwaptionVTSPtr;
// %}

// we use an object adapter pattern to extend base class interface by new underlying class methods

%shared_ptr(VanillaLocalVolModel)
class VanillaLocalVolModel {
  public:
        VanillaLocalVolModel(
            const Time                T,
            const Real                S0,
            const Real                sigmaATM,
            const std::vector<Real>&  Sp,
            const std::vector<Real>&  Sm,
            const std::vector<Real>&  Mp,
            const std::vector<Real>&  Mm,
            // controls for calibration
            const Size                maxCalibrationIters = 5,
            const Size                onlyForwardCalibrationIters = 0,
            const bool                adjustATMFlag = true,
            const bool                enableLogging = false,
            const bool                useInitialMu  = false,
            const Real                initialMu     = 0.0 );

        // inspectors
        const std::vector<std::string> logging();
        const Time timeToExpiry()       ;
        const Real forward()            ;
        const Real sigmaATM()           ;
        const Real alpha()              ;
        const Real mu()                 ;
        const Real nu()                 ;
        const Size maxCalibrationIters();
        const Size onlyForwardCalibrationIters();
        const bool adjustATMFlag()      ;
        const bool enableLogging()      ;
        const bool useInitialMu()       ;
        const Real initialMu()          ;

        // attributes in more convenient single-vector format
        const std::vector<Real> underlyingX()   ;
        const std::vector<Real> underlyingS()   ;
        const std::vector<Real> localVol()      ;
        const std::vector<Real> localVolSlope() ;

        // model function evaluations
        const Real localVol(Real S)    ;
        const Real underlyingS(Real x) ;

        //calculating expectations - that is the actual purpose of that model

        // calculate the forward price of an OTM option
        const Real expectation(bool isRightWing, Real strike); 

        // calculate the forward price of an OTM power option with payoff 1_{S>K}(S-K)^2
        const Real variance(bool isRightWing, Real strike); 
};

%shared_ptr(VanillaLocalVolModelSmileSection)
class VanillaLocalVolModelSmileSection : public SmileSection {
  public:
        VanillaLocalVolModelSmileSection(
            const Date&                                   expiryDate,
            const Rate&                                   forward,
            const std::vector<Rate>&                      relativeStrikes,
            const std::vector<Volatility>&                smileVolatilities,
            const Real                                    extrapolationRelativeStrike,
            const Real                                    extrapolationSlope,
            bool                                          vegaWeighted = false,
            const ext::shared_ptr<EndCriteria>&           endCriteria = ext::shared_ptr<EndCriteria>(new EndCriteria(100, 10, 1.0e-6, 1.0e-6, 1.0e-6)),
            const ext::shared_ptr<OptimizationMethod>&    method = ext::shared_ptr<OptimizationMethod>(new LevenbergMarquardt(1.0e-6, 1.0e-6, 1.0e-6)),
            const DayCounter&                             dc = Actual365Fixed(),
            const Date&                                   referenceDate = Date(),
            const VolatilityType                          type = Normal,
            const Rate                                    shift = 0.0,
            const ext::shared_ptr<VanillaLocalVolModel>&  model = ext::shared_ptr<VanillaLocalVolModel>(),
            const Real                                    minSlope = -3.0,   //  lower boundary for m in calibration
            const Real                                    maxSlope =  3.0,   //  upper boundary for m in calibration
            const Real                                    alpha = 1.0e-4);   //  Tikhonov alpha

        VanillaLocalVolModelSmileSection(
            const Date&                                   expiryDate,
            const Rate&                                   forward,
            const Volatility&                             atmVolatility,
            const ext::shared_ptr<VanillaLocalVolModelSmileSection>& smile1,
            const ext::shared_ptr<VanillaLocalVolModelSmileSection>& smile2,
            const Real&                                   rho,
            const bool                                    calcSimple = true,  // use only ATM vol for x-grid calculation
            const DayCounter&                             dc = Actual365Fixed(),
            const Date&                                   referenceDate = Date(),
            const VolatilityType                          type = Normal,
            const Rate                                    shift = 0.0);

        const ext::shared_ptr<VanillaLocalVolModel>&  model();

};


namespace std {
    %template(VanillaLocalVolModelSmileSectionVector) vector<ext::shared_ptr<VanillaLocalVolModelSmileSection> >;
    %template(VanillaLocalVolModelSmileSectionVectorVector) vector<vector<ext::shared_ptr<VanillaLocalVolModelSmileSection> > >;
}


%shared_ptr(VanillaLocalVolSwaptionVTS)
class VanillaLocalVolSwaptionVTS : public SwaptionVolatilityStructure {
  public:
        VanillaLocalVolSwaptionVTS(
            const Handle<SwaptionVolatilityStructure>&                                              atmVolTS,
            const std::vector< std::vector< ext::shared_ptr<VanillaLocalVolModelSmileSection> > >&  smiles,
            const std::vector< Period >&                                                            swapTerms,
            const ext::shared_ptr<SwapIndex>&                                                       index);
};


#endif
