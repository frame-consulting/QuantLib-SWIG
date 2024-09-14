/*
 Copyright (C) 2019 Sebastian Schlenkrich

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

#ifndef quantlib_multiassetmodels_i
#define quantlib_multiassetmodels_i

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
#include <ql/experimental/templatemodels/stochasticprocessT.hpp>
#include <ql/experimental/templatemodels/multiasset/all.hpp>

using QuantLib::RealStochasticProcess;
using QuantLib::MultiAssetBSModel;
using QuantLib::MultiAssetSLVModel;
%}

%template(RealStochasticProcessBase) ext::shared_ptr<RealStochasticProcess>;

namespace std {
    %template(RealStochasticProcessVector) vector<ext::shared_ptr<RealStochasticProcess> >;
}


%shared_ptr(RealStochasticProcess);
class RealStochasticProcess {
public:
    // dimension of X
    virtual Size size() = 0;
    // stochastic factors (underlying, volatilities and spreads)
    virtual Size factors() = 0;
    // initial values for simulation
    virtual std::vector<Real> initialValues() = 0;
    // integrate X1 = X0 + drift()*dt + diffusion()*dW*sqrt(dt)
    // default implementation
    virtual void evolve( const Real t0, const std::vector<Real>& X0, const Real dt, const std::vector<Real>& dW, std::vector<Real>& X1 );
    // we want to keep track of the model details
    virtual std::vector< std::string > stateAliases();
    virtual std::vector< std::string > factorAliases();

};

%shared_ptr(MultiAssetBSModel);
class MultiAssetBSModel : public RealStochasticProcess {
public:
    MultiAssetBSModel(const Handle<YieldTermStructure>&                                               termStructure,
                      const std::vector<std::string>&                                                 aliases,
                      const std::vector<ext::shared_ptr<QuantLib::GeneralizedBlackScholesProcess>>&   processes,
                      const std::vector< std::vector<Real> >&                                         correlations);
    MultiAssetBSModel(const Handle<YieldTermStructure>&                                               termStructure,
                      const std::vector<std::string>&                                                 aliases,
                      const std::vector<ext::shared_ptr<QuantLib::GeneralizedBlackScholesProcess>>&   processes);

    //This constructor enables to directly pass a local vol term structure, i.e. an InterpolatedLocalVolSurface
    MultiAssetBSModel(const Handle<YieldTermStructure>&                                 termStructure,
                      const std::vector<std::string>&                                   aliases,
                      const std::vector<ext::shared_ptr<QuantLib::LocalVolSurface>>&    localVolSurfaces,
                      const std::vector< std::vector<Real> >&                           correlations);
    MultiAssetBSModel(const Handle<YieldTermStructure>&                                 termStructure,
                      const std::vector<std::string>&                                   aliases,
                      const std::vector<ext::shared_ptr<QuantLib::LocalVolSurface>>&    localVolSurfaces);

    virtual Size size();
    // stochastic factors (underlying, volatilities and spreads)
    virtual Size factors();
    // initial values for simulation
    virtual std::vector<Real> initialValues();
};

%shared_ptr(MultiAssetSLVModel);
class MultiAssetSLVModel : public RealStochasticProcess {
public:
    MultiAssetSLVModel(const Handle<YieldTermStructure>&                                  termStructure,
                       const std::vector<std::string>&                                    aliases,
                       const std::vector<ext::shared_ptr<QuantLib::HestonSLVProcess>>&    processes,
                       const std::vector< std::vector<Real> >&                            correlations);
    MultiAssetSLVModel(const Handle<YieldTermStructure>&                                  termStructure,
                       const std::vector<std::string>&                                    aliases,
                       const std::vector<ext::shared_ptr<QuantLib::HestonSLVProcess>>&    processes);

    virtual Size size();
    // stochastic factors (underlying, volatilities and spreads)
    virtual Size factors();
    // initial values for simulation
    virtual std::vector<Real> initialValues();
};


#endif
