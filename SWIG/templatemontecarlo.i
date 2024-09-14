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

#ifndef quantlib_template_montecarlo_i
#define quantlib_template_montecarlo_i

%include common.i
%include date.i
%include daycounters.i
%include types.i
%include currencies.i
%include observer.i
%include marketelements.i
%include interpolation.i
%include indexes.i


%{
#include <ql/experimental/templatemodels/montecarlo/montecarlomodells.hpp>

using QuantLib::RealStochasticProcess;
using QuantLib::RealMCSimulation;
using QuantLib::RealMCPayoff;
using QuantLib::RealMCPayoffPricer;
using QuantLib::RealMCBase;
using QuantLib::RealMCRates;
using QuantLib::RealAMCPricer;
%}

%shared_ptr(RealMCSimulation);
class RealMCSimulation {
    public:
        RealMCSimulation(
            const ext::shared_ptr<RealStochasticProcess>    process,
            const std::vector<Real>&                        simTimes,
            const std::vector<Real>&                        obsTimes,
            Size                                            nPaths,
            BigNatural                                      seed = 1234,
            bool                                            richardsonExtrapolation = false,
            bool                                            timeInterpolation = true,
            bool                                            storeBrownians = false );
            
        void simulate();

        // inspectors

        const ext::shared_ptr<RealStochasticProcess> process();
        const std::vector<Real>&                  simTimes();
        const std::vector<Real>&                  obsTimes();
        const Size                                nPaths();

        const std::vector< std::vector<Real> >&   observedPath(const Size pathIdx);

        // find an actual state of the model for a given observation time
        // this method is used by a path object and the result is passed on to
        // the stochastic process for payoff evaluation
        const std::vector<Real> state(const Size pathIdx, const Time t);

        const std::vector< std::vector<Real> >& brownian(const Size pathIdx);

        // manage MC adjusters

        void calculateNumeraireAdjuster(const std::vector<Real>&  numeraireObservTimes);

        void calculateZCBAdjuster( const std::vector<Real>& zcbObservTimes, const std::vector<Real>& zcbOffsetTimes );

        void calculateAssetAdjuster( const std::vector<Real>& assetObservTimes, const std::vector<std::string>& aliases );

        const std::vector<Real>& numeraireAdjuster();

        const std::vector< std::vector<Real> >& zcbAdjuster();

        const std::vector<Real>& assetAdjuster(const std::string& alias);
};

%shared_ptr(RealMCPayoff);
%nodefaultctor RealMCPayoff;
class RealMCPayoff {
public:
    Real observationTime();

    // calculate observation times recursively
    std::set<Time> observationTimes();

    // we want the times as vector because swig does not really know what to do with std::set
    std::vector<Real> observationTimesVector();

    // return a clone but with changed observation time; this effectively allows considering a payoff as an index
    virtual ext::shared_ptr<RealMCPayoff> at(const Time t);

};

// we also want to use vectors of payoffs
namespace std {
    %template(RealMCPayoffVector) vector<ext::shared_ptr<RealMCPayoff> >;
}


// generic pricer
%shared_ptr(RealMCPayoffPricer);
class RealMCPayoffPricer {
    public:
        RealMCPayoffPricer(const std::vector< ext::shared_ptr<RealMCPayoff> >&   payoffs,
                           const ext::shared_ptr<RealMCSimulation>&              simulation);

        Real NPV();
        
        static std::vector<Real> at(const ext::shared_ptr<RealMCPayoff>&      payoff,
                                    const ext::shared_ptr<RealMCSimulation>&  simulation);

        static std::vector<Real> discountedAt(const ext::shared_ptr<RealMCPayoff>&      payoff,
                                              const ext::shared_ptr<RealMCSimulation>&  simulation);

        static Real NPV(const std::vector< ext::shared_ptr<RealMCPayoff> >&  payoffs,
                        const ext::shared_ptr<RealMCSimulation>&             simulation);

        static std::vector<Real> NPVs(const std::vector< ext::shared_ptr<RealMCPayoff> >&  payoffs,
                                      const ext::shared_ptr<RealMCSimulation>&             simulation);

};


// basic payoffs and operations

%shared_ptr(RealMCClone);
class RealMCClone : public RealMCPayoff {
    public:
        RealMCClone(const ext::shared_ptr<RealMCPayoff>&     x,
                    const Time                               observationTime);
};

// a deterministic flow known in advance (undiscounted)
%shared_ptr(RealMCFixedAmount);
class RealMCFixedAmount : public RealMCPayoff {
    public:
        RealMCFixedAmount(const Real amount);
};

// (re-)set paydate of a payoff (for discounting)
%shared_ptr(RealMCPay);
class RealMCPay : public RealMCPayoff {
    public:
        RealMCPay(const ext::shared_ptr<RealMCPayoff>&    x,
                  const Time                              payTime);
};

// simple discounted cash payment
%shared_ptr(RealMCCash);
class RealMCCash : public RealMCPayoff {
    public:
        RealMCCash(Time obsTime, Time payTime);
};

// zero coupon bond payoff
%shared_ptr(RealMCZeroBond);
class RealMCZeroBond : public RealMCPayoff {
    public:
        RealMCZeroBond(Time obsTime, Time payTime, const std::string alias);
};

// 1 unit of modelled asset
%shared_ptr(RealMCAsset);
class RealMCAsset : public RealMCPayoff {
    public:
        RealMCAsset(Time obsTime, const std::string alias);
};

// return the continuous barrier no-hit probability
%shared_ptr(RealMCAssetBarrierNoHit);
class RealMCAssetBarrierNoHit : public RealMCPayoff {
    public:
        RealMCAssetBarrierNoHit(Time tStart, Time tEnd, Real downBarrier, Real upBarrier, Real downOrUpOrBoth, const std::string alias);
};

// 1 unit call or put exercised and settled at observation time
%shared_ptr(RealMCVanillaOption);
class RealMCVanillaOption : public RealMCPayoff {
    public:
        RealMCVanillaOption(Time obsTime, const std::string alias, Real strike, Real callOrPut);
};

// cache result in case it is requested repeatedly
%shared_ptr(RealMCCache);
class RealMCCache : public RealMCPayoff {
    public:
        RealMCCache(const ext::shared_ptr<RealMCPayoff>& x);
};

// arithmetics and functions applied to payoffs

// a x + y  (undiscounted)
%shared_ptr(RealMCAxpy);
class RealMCAxpy : public RealMCPayoff {
    public:
        RealMCAxpy(const Real                             a,
                   const ext::shared_ptr<RealMCPayoff>&   x,
                   const ext::shared_ptr<RealMCPayoff>&   y);
};

// x * y  (undiscounted)
%shared_ptr(RealMCMult);
class RealMCMult : public RealMCPayoff {
    public:
        RealMCMult(const ext::shared_ptr<RealMCPayoff>& x,
                   const ext::shared_ptr<RealMCPayoff>& y);
};

// x / y  (undiscounted)
%shared_ptr(RealMCDivision);
class RealMCDivision : public RealMCPayoff {
    public:
        RealMCDivision(const ext::shared_ptr<RealMCPayoff>& x,
                       const ext::shared_ptr<RealMCPayoff>& y);
};

// max{x,y}  (undiscounted)
%shared_ptr(RealMCMax);
class RealMCMax : public RealMCPayoff {
    public:
        RealMCMax(const ext::shared_ptr<RealMCPayoff>& x,
                  const ext::shared_ptr<RealMCPayoff>& y);
};

// min{x,y}  (undiscounted)
%shared_ptr(RealMCMin);
class RealMCMin : public RealMCPayoff {
    public:
        RealMCMin(const ext::shared_ptr<RealMCPayoff>& x,
                  const ext::shared_ptr<RealMCPayoff>& y);
};

// exp{x}  (undiscounted)
%shared_ptr(RealMCExponential);
class RealMCExponential : public RealMCPayoff {
    public:
        RealMCExponential(const ext::shared_ptr<RealMCPayoff>& x);
};

// log{x}  (undiscounted)
%shared_ptr(RealMCLogarithm);
class RealMCLogarithm : public RealMCPayoff {
    public:
        RealMCLogarithm(const ext::shared_ptr<RealMCPayoff>& x);
};

// sqrt{x}  (undiscounted)
%shared_ptr(RealMCSquareroot);
class RealMCSquareroot : public RealMCPayoff {
    public:
        RealMCSquareroot(const ext::shared_ptr<RealMCPayoff>& x);
};

// logical operators
%shared_ptr(RealMCLogical);
class RealMCLogical : public RealMCPayoff {
    public:
        RealMCLogical(const ext::shared_ptr<RealMCPayoff>&   x,
                      const ext::shared_ptr<RealMCPayoff>&   y,
                      const std::string&                     op);
};

// if-then-else
%shared_ptr(RealMCIfThenElse);
class RealMCIfThenElse : public RealMCPayoff {
    public:
        RealMCIfThenElse(
                      const ext::shared_ptr<RealMCPayoff>& x,
                      const ext::shared_ptr<RealMCPayoff>& y,
                      const ext::shared_ptr<RealMCPayoff>& z);
};

// basket of underlyings
%shared_ptr(RealMCBasket);
class RealMCBasket : public RealMCPayoff {
    public:
        RealMCBasket(
            const std::vector<ext::shared_ptr<RealMCPayoff> >&   underlyings,
            const std::vector<Real>                              weights,
            bool                                                 rainbow);
};

// we need to tell C++ that our outer classes are actual inner classes
%{
typedef RealMCBase::Clone              RealMCClone;
typedef RealMCBase::FixedAmount        RealMCFixedAmount;
typedef RealMCBase::Pay                RealMCPay;
typedef RealMCBase::Cash               RealMCCash;
typedef RealMCBase::ZeroBond           RealMCZeroBond;
typedef RealMCBase::Asset              RealMCAsset;
typedef RealMCBase::AssetBarrierNoHit  RealMCAssetBarrierNoHit;
typedef RealMCBase::VanillaOption      RealMCVanillaOption;
typedef RealMCBase::Cache              RealMCCache;
typedef RealMCBase::Axpy               RealMCAxpy;
typedef RealMCBase::Mult               RealMCMult;
typedef RealMCBase::Division           RealMCDivision;
typedef RealMCBase::Max                RealMCMax;
typedef RealMCBase::Min                RealMCMin;
typedef RealMCBase::Exponential        RealMCExponential;
typedef RealMCBase::Logarithm          RealMCLogarithm;
typedef RealMCBase::Squareroot         RealMCSquareroot;
typedef RealMCBase::Logical            RealMCLogical;
typedef RealMCBase::IfThenElse         RealMCIfThenElse;
typedef RealMCBase::Basket             RealMCBasket;
%}



// interest rate payoffs


// general swaption instrument
%shared_ptr(RealMCSwaption);
class RealMCSwaption : public RealMCPayoff {
    public:
        RealMCSwaption(
            Time                      obsTime,    // observation equals fixing time
            const std::vector<Time>&  floatTimes,
            const std::vector<Real>&  floatWeights,
            const std::vector<Time>&  fixedTimes,
            const std::vector<Real>&  annuityWeights,
            Real                      strikeRate,
            Real                      payOrRec );

        RealMCSwaption(
            Time                               obsTime,    // observation equals fixing time
            const ext::shared_ptr<SwapIndex>&  index,
            const Handle<YieldTermStructure>&  discYTSH,
            Real                               strikeRate,
            Real                               payOrRec );
};

// general swap (or CMS) rate
%shared_ptr(RealMCSwapRate);
class RealMCSwapRate : public RealMCPayoff {
    public:
        RealMCSwapRate(
            Time                      obsTime,    // observation equals fixing time
            const std::vector<Time>&  floatTimes,
            const std::vector<Real>&  floatWeights,
            const std::vector<Time>&  fixedTimes,
            const std::vector<Real>&  annuityWeights );

        RealMCSwapRate(
            Time                                obsTime,    // observation equals fixing time
            const ext::shared_ptr<SwapIndex>& index,
            const Handle<YieldTermStructure>&   discYTSH );
};

// Libor rate
%shared_ptr(RealMCLiborRate);
class RealMCLiborRate : public RealMCPayoff {
    public:
        RealMCLiborRate(
            Time                                obsTime,    // observation equals fixing time
            const ext::shared_ptr<IborIndex>&   index,
            const Handle<YieldTermStructure>&   discYTSH );
};

// Libor rate in hybrid model
%shared_ptr(RealMCLiborRateCcy);
class RealMCLiborRateCcy : public RealMCPayoff {
    public:
        RealMCLiborRateCcy(
            Time                                obsTime,    // observation equals fixing time
            const ext::shared_ptr<IborIndex>&   index,
            const Handle<YieldTermStructure>&   discYTSH,
            const std::string                   alias );
};

// annuity (of a swap rate)
%shared_ptr(RealMCAnnuity);
class RealMCAnnuity : public RealMCPayoff {
    public:
        RealMCAnnuity(
            Time                      obsTime,    // observation equals fixing time
            const std::vector<Time>&  fixedTimes,
            const std::vector<Real>&  annuityWeights );
};

// American Monte Carlo payoffs using regression

// minimum or maximum of sum of payoffs discounted to obsTime
%shared_ptr(RealAMCMinMax);
class RealAMCMinMax : public RealMCPayoff {
    public:
        RealAMCMinMax(
            const std::vector<ext::shared_ptr<RealMCPayoff>>&   x,
            const std::vector<ext::shared_ptr<RealMCPayoff>>&   y,
            const std::vector<ext::shared_ptr<RealMCPayoff>>&   z,
            const Time                                          observationTime,
            const Real                                          minMax,             // min = -1, max = +1
            const ext::shared_ptr<RealMCSimulation>             simulation,
            const Size                                          maxPolynDegree);
};

// indicator function 1_{x>y} or 1_{x<y} based on discounted values of x and y using regression via z
%shared_ptr(RealAMCOne);
class RealAMCOne : public RealMCPayoff {
    public:
        RealAMCOne(
            const std::vector<ext::shared_ptr<RealMCPayoff>>&   x,
            const std::vector<ext::shared_ptr<RealMCPayoff>>&   y,
            const std::vector<ext::shared_ptr<RealMCPayoff>>&   z,
            const Time                                          observationTime,
            const Real                                          largerLess,             // 1: (x>y), -1: (x<y)
            const ext::shared_ptr<RealMCSimulation>             simulation,
            const Size                                          maxPolynDegree);
};

// sum of future payoffs x based on discounted values of x using regression via z
%shared_ptr(RealAMCSum);
class RealAMCSum : public RealMCPayoff {
    public:
        RealAMCSum(
            const std::vector<ext::shared_ptr<RealMCPayoff>>&   x,
            const std::vector<ext::shared_ptr<RealMCPayoff>>&   z,
            const Time                                          observationTime,
            const ext::shared_ptr<RealMCSimulation>             simulation,
            const Size                                          maxPolynDegree);
};


// we need to tell C++ that our outer classes are actual inner classes
%{
typedef RealMCRates::GeneralSwaption  RealMCSwaption;
typedef RealMCRates::SwapRate         RealMCSwapRate;
typedef RealMCRates::LiborRate        RealMCLiborRate;
typedef RealMCRates::LiborRateCcy     RealMCLiborRateCcy;
typedef RealMCRates::Annuity          RealMCAnnuity;
typedef RealAMCPricer::MinMax         RealAMCMinMax;
typedef RealAMCPricer::One            RealAMCOne;
typedef RealAMCPricer::Sum            RealAMCSum;
%}


#endif
