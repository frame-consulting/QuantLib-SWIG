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

#ifndef quantlib_quasigaussian_i
#define quantlib_quasigaussian_i

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
%include templatemontecarlo.i
%include multiassetmodels.i




%{
#include <ql/experimental/templatemodels/qgaussian2/qgcalibrator.hpp>
#include <ql/experimental/templatemodels/qgaussian2/mccalibrator.hpp>
#include <ql/experimental/templatemodels/qgaussian2/qglsvmodel.hpp>

using QuantLib::QuasiGaussianModel;
using QuantLib::QGSwaprateModel;
using QuantLib::QGAverageSwaprateModel;
using QuantLib::QGCalibrator;
using QuantLib::QGMonteCarloCalibrator;
using QuantLib::QGLocalvolModel;

%}

// we need to tell SWIG to export shared_ptr with new classes
%template(QGLocalvolModelBase) ext::shared_ptr<QGLocalvolModel>;

// we need to tell C++ that our new pointer-based classes are type names
%{
typedef ext::shared_ptr<QGLocalvolModel> QGLocalvolModelPtr;
%}


%shared_ptr(QuasiGaussianModel);
class QuasiGaussianModel : public RealStochasticProcess {
  public:
    QuasiGaussianModel(
        const Handle<YieldTermStructure>&       termStructure,
        // number of yield curve factors (excluding stoch. vol)
        const Size                              d,       // (d+1)-dimensional Brownian motion for [x(t), z(t)]^T
        // unique grid for time-dependent parameters
        const std::vector<Time>&                times,   // time-grid of left-constant model parameter values
        // time-dependent parameters, left-piecewise constant on times_-grid
        const std::vector< std::vector<Real> >& sigma,   // volatility
        const std::vector< std::vector<Real> >& slope,   // skew
        const std::vector< std::vector<Real> >& curve,   // smile
        const std::vector<Real>&                eta,     // vol-of-vol
        // time-homogeneous parameters
        const std::vector<Real>&                delta,   // maturity of benchmark rates f(t,t+delta_i)
        const std::vector<Real>&                chi,     // mean reversions
        const std::vector< std::vector<Real> >& Gamma,   // (benchmark rate) correlation matrix
        const Real                              theta);  // mean reversion speed

    // inspectors
    const Handle<YieldTermStructure> termStructure()  ;
    const std::vector<Time>&                times()   ;
    const std::vector< std::vector<Real> >& sigma()   ;
    const std::vector< std::vector<Real> >& slope()   ;
    const std::vector< std::vector<Real> >& curve()   ;
    const std::vector<Time>&                eta()     ;
    const std::vector< std::vector<Real> >& DfT()     ;
    const std::vector< std::vector<Real> >& HHfInv()  ;
    const std::vector<Real>&                delta()   ;
    const std::vector<Real>&                chi()     ;
    const Real                              theta()   ;
    const Real                              z0()      ;
    const Real                              condHHf() ;

    // RealStochasticProcess
    virtual Size size();
    virtual Size factors();
    virtual std::vector<Real> initialValues();

};

%shared_ptr(QGSwaprateModel);
class QGSwaprateModel : public RealStochasticProcess {
  public:
    QGSwaprateModel (
        const ext::shared_ptr<QuasiGaussianModel>& model,
        const std::vector<Real>&    floatTimes,      // T[1], ..., T[M]
        const std::vector<Real>&    floatWeights,    // u[1], ..., u[M]
        const std::vector<Real>&    fixedTimes,      // T[1], ..., T[N]
        const std::vector<Real>&    fixedWeights,    // w[1], ..., w[N-1]
        const std::vector<Real>&    modelTimes,      // time grid for numerical integration
        const bool                  useExpectedXY);  // evaluate E^A [ x(t) ], E^A [ y(t) ] as expansion points

       Real              annuity     ( const Real t, const std::vector<Real>& x, const std::vector< std::vector<Real> >& y);
       Real              swapRate    ( const Real t, const std::vector<Real>& x, const std::vector< std::vector<Real> >& y); 
       std::vector<Real> swapGradient( const Real t, const std::vector<Real>& x, const std::vector< std::vector<Real> >& y);
       std::vector< std::vector<Real> > swapHessian( const Real t, const std::vector<Real>& x, const std::vector< std::vector<Real> >& y);
       Real sigma  (const Real t) ;
       Real slope  (const Real t) ;
       Real eta    (const Real t) ;
       Real theta  ()             ;
       Real z0     ()             ;
       Real rho    ()             ;
       Real S0     ()             ;

    // RealStochasticProcess
    virtual Size size();
    virtual Size factors();
    virtual std::vector<Real> initialValues();

};

%shared_ptr(QGAverageSwaprateModel);
class QGAverageSwaprateModel : public RealStochasticProcess {
  public:
    QGAverageSwaprateModel ( const ext::shared_ptr<QGSwaprateModel>& model );

    // inspectors
    Real sigma() ;
    Real slope() ;
    Real eta()   ;

    // undiscounted expectation of vanilla payoff
    Real vanillaOption(const Real strike, const int callOrPut, const Real accuracy = 1.0-6, const Size maxEvaluations = 1000);

    // RealStochasticProcess
    virtual Size size();
    virtual Size factors();
    virtual std::vector<Real> initialValues();

};

%shared_ptr(QGCalibrator);
class QGCalibrator {
  public:
    QGCalibrator(
        const ext::shared_ptr<QuasiGaussianModel>& model,
        const Handle<SwaptionVolatilityStructure>&  volTS,
        const std::vector< ext::shared_ptr<SwapIndex> >&  swapIndices,
        const Real                                  modelTimesStepSize,
        const bool                                  useExpectedXY,
        const Real                                  sigmaMax,
        const Real                                  slopeMax,
        const Real                                  etaMax,
        const Real                                  sigmaWeight,
        const Real                                  slopeWeight,
        const Real                                  etaWeight,
        const Real                                  penaltySigma,
        const Real                                  penaltySlope,
        const EndCriteria&                          endCriteria );

    // a single optimisation run
    Integer calibrate( const std::vector< std::vector< Real > >&  isInput,
                       const std::vector< std::vector< Real > >&  isOutput,
                       Real                                       epsfcn = 1.0e-4 );

    // inspectors
    const ext::shared_ptr<QuasiGaussianModel> calibratedModel();
    const std::vector<std::string>& debugLog();
    void acceptCalibration();
};

%shared_ptr(QGMonteCarloCalibrator);
class QGMonteCarloCalibrator {
  public:
    QGMonteCarloCalibrator(
        const ext::shared_ptr<QuasiGaussianModel>& model,
        const Handle<SwaptionVolatilityStructure>&  volTS,
        const std::vector< ext::shared_ptr<SwapIndex> >&  swapIndices,
        const Real                                  monteCarloStepSize,
        const Size                                  monteCarloPaths,
        const Real                                  sigmaMax,
        const Real                                  slopeMax,
        const Real                                  curveMax,
        const Real                                  sigmaWeight,
        const Real                                  slopeWeight,
        const Real                                  curveWeight,
        const Real                                  penaltySigma,
        const Real                                  penaltySlope,
        const Real                                  penaltyCurve,
        const EndCriteria&                          endCriteria );

    // a single optimisation run
    Integer calibrate( const std::vector< std::vector< Real > >&  isInput,
                       const std::vector< std::vector< Real > >&  isOutput,
                       Real                                       epsfcn = 1.0e-4 );

    // inspectors
    const ext::shared_ptr<QuasiGaussianModel> calibratedModel();
    const ext::shared_ptr<RealMCSimulation> mcSimulation();
    const std::vector<std::string>& debugLog();
    void acceptCalibration();

};

%rename(QGLocalvolModel) QGLocalvolModelPtr;
class QGLocalvolModelPtr : public ext::shared_ptr<QGLocalvolModel> {
  public:
    %extend {
        QGLocalvolModelPtr(
            const std::string                                      flavor,            // "SLV"
            const Handle<YieldTermStructure>&                      hYTS,
            const Handle<SwaptionVolatilityStructure>&             volTS,
            const Real                                             chi,               // 0.03
            const Real                                             theta,             // 0.1
            const Real                                             eta,               // 0.7
            const ext::shared_ptr<SwapIndex>&                      swapIndex,         // EuriborSwapIsdaFixA
            const std::vector<Real>&                               times,             // [1.0,2.0,..,10.0]
            const std::vector<Real>&                               stdDevGrid,        // [-3.0, ..., 3.0] (for non-SLV models) or [] (for SLV model)
            const size_t                                           nStrikes,          // 101 or 201 (only for SLV model)
            const bool                                             calcStochVolAdjustment,  // True
            const Real                                             kernelWidth,       // 1.06 N^0.2, ~0.15, see Silverman's rule of thumb
            const Real                                             svKernelScaling,   // ~3.0, smooth conditional expectation typically requires larger kernel width
            const size_t                                           nPaths,            // 10k
            const BigNatural                                       seed = 1234,
            const size_t                                           debugLevel = 1) {
            std::string flavorUpperCase = flavor;
            boost::to_upper(flavorUpperCase);
            ext::shared_ptr<SwapIndex> swapIdx_sp =  ext::dynamic_pointer_cast<SwapIndex>(swapIndex);
            if (flavorUpperCase.compare("SLV") == 0) {  
                return new QGLocalvolModelPtr(
                    new QuantLib::QGLSVModel(hYTS,volTS,chi,theta,eta,swapIdx_sp,times,nStrikes,
                        calcStochVolAdjustment,kernelWidth,svKernelScaling,nPaths,seed,debugLevel));
            }
            else if (flavorUpperCase.compare("BACKWARD") == 0) {
                return new QGLocalvolModelPtr(   
                    new QuantLib::QGLocalvolModelBackwardFlavor(hYTS, volTS, chi, theta, eta, swapIdx_sp,
                        times, stdDevGrid, false, kernelWidth*svKernelScaling, nPaths, seed, debugLevel));
            }
            else if (flavorUpperCase.compare("FORWARD") == 0) {
                return new QGLocalvolModelPtr(
                    new QuantLib::QGLocalvolModelForwardFlavor(hYTS, volTS, chi, theta, eta, swapIdx_sp,
                        times, stdDevGrid, false, kernelWidth*svKernelScaling, nPaths, seed, debugLevel));
            }
            else if (flavorUpperCase.compare("ANALYTIC") == 0) {
                return new QGLocalvolModelPtr(
                    new QuantLib::QGLocalvolModelAnalyticFlavor(hYTS, volTS, chi, swapIdx_sp,
                        times, stdDevGrid, nPaths, seed, debugLevel));
            }
            else if (flavorUpperCase.compare("MONTECARLO") == 0) {
                return new QGLocalvolModelPtr(
                    new QuantLib::QGLocalvolModelMonteCarloFlavor(hYTS, volTS, chi, theta, eta, swapIdx_sp,
                        times, stdDevGrid, false, kernelWidth*svKernelScaling, nPaths, seed, debugLevel));
            }
            if (flavorUpperCase.compare("BACKWARDSTOCHVOL") == 0) {
                return new QGLocalvolModelPtr(
                    new QuantLib::QGLocalvolModelBackwardFlavor(hYTS, volTS, chi, theta, eta, swapIdx_sp,
                        times, stdDevGrid, true, kernelWidth*svKernelScaling, nPaths, seed, debugLevel));
            }
            else if (flavorUpperCase.compare("FORWARDSTOCHVOL") == 0) {
                return new QGLocalvolModelPtr(
                    new QuantLib::QGLocalvolModelForwardFlavor(hYTS, volTS, chi, theta, eta, swapIdx_sp,
                        times, stdDevGrid, true, kernelWidth*svKernelScaling, nPaths, seed, debugLevel));
            }
            else if (flavorUpperCase.compare("MONTECARLOSTOCHVOL") == 0) {
                return new QGLocalvolModelPtr(
                    new QuantLib::QGLocalvolModelMonteCarloFlavor(hYTS, volTS, chi, theta, eta, swapIdx_sp,
                        times, stdDevGrid, true, kernelWidth*svKernelScaling, nPaths, seed, debugLevel));
            }
            QL_FAIL("Invalid flavor parameter");
        }

        // methods and inspectors

        void simulateAndCalibrate() {
            ext::dynamic_pointer_cast<QGLocalvolModel>(*self)->simulateAndCalibrate();
        }

        const ext::shared_ptr<RealMCSimulation> simulation() {
            return ext::dynamic_pointer_cast<QGLocalvolModel>(*self)->simulation();
        }

        const Real sigmaS(const Size idx, const Real s) {
            return ext::dynamic_pointer_cast<QGLocalvolModel>(*self)->sigmaS(idx,s);
        }

        std::vector<std::string> debugLog() {
            return ext::dynamic_pointer_cast<QGLocalvolModel>(*self)->debugLog();
        }

        // test the calibration of the model
        std::vector< std::vector<Real> > calibrationTest(const std::vector<Date>&  exerciseDates,
                                                         const std::vector<Real>&  stdDevStrikes ) {
            return ext::dynamic_pointer_cast<QGLocalvolModel>(*self)->calibrationTest(exerciseDates,stdDevStrikes);
        }

    }
};


#endif
