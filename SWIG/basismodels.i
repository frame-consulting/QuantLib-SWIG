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

#ifndef quantlib_basismodels_i
#define quantlib_basismodels_i

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
#include <ql/experimental/basismodels/swaptioncfs.hpp>

using QuantLib::SwapCashFlows;
using QuantLib::SwaptionCashFlows;
%}

// we need to tell SWIG to export shared_ptr with new classes

// we need to tell C++ that our new pointer-based classes are type names

// we use an object adapter pattern to extend base class interface by new underlying class methods 

class SwapCashFlows {
public:
    SwapCashFlows ( const ext::shared_ptr<VanillaSwap>& swap,
                    const Handle<YieldTermStructure>&   discountCurve,
                    bool                                contTenorSpread = true );
    // inspectors
    const std::vector<Real>& floatTimes();
    const std::vector<Real>& floatWeights();
    const std::vector<Real>& fixedTimes();
    const std::vector<Real>& fixedWeights();
    const std::vector<Real>& annuityWeights();
};

class SwaptionCashFlows : public SwapCashFlows {
public:
    SwaptionCashFlows ( const ext::shared_ptr<Swaption>&  swaption,
                        const Handle<YieldTermStructure>& discountCurve,
                        bool                              contTenorSpread = true );
    const std::vector<Real>& exerciseTimes();
};


#endif
