/*
 This file is part of QuantLib, a free-software/open-source library
 for financial quantitative analysts and developers - http://quantlib.org/

 QuantLib is free software: you can redistribute it and/or modify it
 under the terms of the QuantLib license.  You should have received a
 copy of the license along with this program; if not, please email
 <quantlib-dev@lists.sf.net>. The license is also available online at
 <https://www.quantlib.org/license.shtml>.

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the license for more details.
*/

#ifndef quantlib_synthetic_cdo_i
#define quantlib_synthetic_cdo_i


%{
using QuantLib::BaseCorrelationTermStructure;
using QuantLib::Basket;
using QuantLib::ChoeKwonDefaultLossModel;
using QuantLib::DefaultLossModel;
using QuantLib::GaussianLHPLossModel;
using QuantLib::IntegralCDOEngine;
using QuantLib::Pool;
using QuantLib::MidPointCDOEngine;
using QuantLib::SyntheticCDO;
%}

%shared_ptr(Pool);
class Pool {
  public:
    Pool(const std::vector<std::string>& names,
         const std::vector<Handle<DefaultProbabilityTermStructure>>& termStructures);
};


%shared_ptr(Basket);
class Basket {
  public:
    Basket(const Date& refDate,
           const std::vector<std::string>& names,
           std::vector<Real> notionals,
           ext::shared_ptr<Pool> pool,
           Real attachmentRatio = 0.0,
           Real detachmentRatio = 1.0,
           ext::shared_ptr<Claim> claim = ext::shared_ptr<Claim>(new FaceValueClaim()));
    void setLossModel(const ext::shared_ptr<DefaultLossModel>& lossModel);
    Real expectedTrancheLoss(const Date& d) const;
};


%shared_ptr(DefaultLossModel);
class DefaultLossModel{
  private:
    DefaultLossModel();
};


%shared_ptr(GaussianLHPLossModel);
class GaussianLHPLossModel : public DefaultLossModel {
  public:
        GaussianLHPLossModel(
            const Handle<Quote>& correlation,
            const std::vector<Real>& recoveries);
};


%shared_ptr(ChoeKwonDefaultLossModel);
class ChoeKwonDefaultLossModel : public DefaultLossModel {
  public:
    ChoeKwonDefaultLossModel(
        const Handle<Quote>& correlation,
        const std::vector<Real>& recoveries,
        Real p,
        Real q,
        Real mu,
        Real b,
        Real defaultThreshold = 1.0-1.0e-8
    );
};



%{
ext::shared_ptr<DefaultLossModel> GaussianCopulaInhomogeneousPoolLossModel(
    const Handle<Quote>& correlation,
    const std::vector<Real>& recoveries,
    Size nBuckets,
    Real max,
    Real min,
    Real nSteps
){
    ext::shared_ptr<QuantLib::GaussianConstantLossLM> latentModel(new QuantLib::GaussianConstantLossLM(
        correlation,
        recoveries,
        QuantLib::LatentModelIntegrationType::GaussianQuadrature,
        recoveries.size(),
        QuantLib::GaussianCopulaPolicy::initTraits()));
    return ext::shared_ptr<DefaultLossModel>(
        new QuantLib::IHGaussPoolLossModel(
            latentModel,
            nBuckets,  //  100 - 200
            max,       //  3.0 - 5.0
            min,       // -5.0 - -3.0
            nSteps     //  15 - 50
        )
    );
}
%}
ext::shared_ptr<DefaultLossModel> GaussianCopulaInhomogeneousPoolLossModel(
    const Handle<Quote>& correlation,
    const std::vector<Real>& recoveries,
    Size nBuckets,
    Real max,
    Real min,
    Real nSteps
);


%{
ext::shared_ptr<DefaultLossModel> GaussianHullWhiteBucketingDefaultLossModel(
    const Handle<Quote>& correlation,
    const std::vector<Real>& recoveries,
    Real recoveryScaling,
    Size nBuckets,
    Real max,
    Real min,
    Real nSteps,
    bool useDetachmentUpperBound = false,
    bool enforceDistributionProperty = false
){
    ext::shared_ptr<QuantLib::GaussianConstantLossLM> latentModel(new QuantLib::GaussianConstantLossLM(
        correlation,
        recoveries,
        QuantLib::LatentModelIntegrationType::GaussianQuadrature,
        recoveries.size(),
        QuantLib::GaussianCopulaPolicy::initTraits()));
    QuantLib::GaussianHullWhiteBucketingDefaultLossModel::UpperBoundStrategy upperBoundStrategy = QuantLib::GaussianHullWhiteBucketingDefaultLossModel::One;
    if (useDetachmentUpperBound) {
        upperBoundStrategy = QuantLib::GaussianHullWhiteBucketingDefaultLossModel::Detachment;
    }
    return ext::shared_ptr<DefaultLossModel>(
        new QuantLib::GaussianHullWhiteBucketingDefaultLossModel(
            latentModel,
            recoveryScaling,  // 0.0 - 1.0
            nBuckets,  //  100 - 200
            max,       //  3.0 - 5.0
            min,       // -5.0 - -3.0
            nSteps,   //  15 - 50
            upperBoundStrategy,
            enforceDistributionProperty
        )
    );
}
%}
ext::shared_ptr<DefaultLossModel> GaussianHullWhiteBucketingDefaultLossModel(
    const Handle<Quote>& correlation,
    const std::vector<Real>& recoveries,
    Real recoveryScaling,
    Size nBuckets,
    Real max,
    Real min,
    Real nSteps,
    bool useDetachmentUpperBound = false,
    bool enforceDistributionProperty = false
);



%shared_ptr(BaseCorrelationTermStructure<QuantLib::BilinearInterpolation>);

template<class Interpolator2D_T>
class BaseCorrelationTermStructure  {
public:
    BaseCorrelationTermStructure(const Date& referenceDate,
                                 const Calendar& cal,
                                 BusinessDayConvention bdc,
                                 const std::vector<Date>& trancheDates,
                                 const std::vector<Real>& lossLevels,
                                 const std::vector<std::vector<Handle<Quote> > >& correls,  // correls[n_dates][n_loss_levels]
                                 const DayCounter& dc = DayCounter());
    Real correlation(const Date& d, Real lossLevel, bool extrapolate = true) const;
    Real correlation(const Time& t, Real lossLevel, bool extrapolate = true) const;
};

%template(BaseCorrelationTermStructureBilinear) BaseCorrelationTermStructure<QuantLib::BilinearInterpolation>;
%template(BaseCorrelationTermStructureBilinearHandle) Handle<BaseCorrelationTermStructure<QuantLib::BilinearInterpolation> >;


%{
ext::shared_ptr<DefaultLossModel> GaussianLHPBaseCorrelationLossModel(
    const Handle<BaseCorrelationTermStructure<QuantLib::BilinearInterpolation> >& correlationStructure,
    const std::vector<Real>& recoveries
){
    QuantLib::GaussianLHPLossModel::copulaType::initTraits traits;
    return ext::shared_ptr<DefaultLossModel>(
        new QuantLib::BaseCorrelationLossModel<QuantLib::GaussianLHPLossModel, QuantLib::BilinearInterpolation >(
            correlationStructure,
            recoveries,
            traits
        )
    );
}
%}
ext::shared_ptr<DefaultLossModel> GaussianLHPBaseCorrelationLossModel(
    const Handle<BaseCorrelationTermStructure<QuantLib::BilinearInterpolation> >& correlationStructure,
    const std::vector<Real>& recoveries
);


%{
ext::shared_ptr<DefaultLossModel> GaussianCopulaInhomogeneousPoolBaseCorrelationLossModel(
    const Handle<BaseCorrelationTermStructure<QuantLib::BilinearInterpolation> >& correlationStructure,
    const std::vector<Real>& recoveries,
    Size nBuckets = 200,
    Real max = 5.0,
    Real min = -5.0,
    Real nSteps = 50
){
    QuantLib::IHGaussPoolLossModel::copulaType::initTraits traits;
    return ext::shared_ptr<DefaultLossModel>(
        new QuantLib::BaseCorrelationLossModel<QuantLib::IHGaussPoolLossModel, QuantLib::BilinearInterpolation >(
            correlationStructure,
            recoveries,
            traits,
            1.0,  // recovery scaling
            nBuckets,
            max,
            min,
            nSteps
        )
    );
}
%}
ext::shared_ptr<DefaultLossModel> GaussianCopulaInhomogeneousPoolBaseCorrelationLossModel(
    const Handle<BaseCorrelationTermStructure<QuantLib::BilinearInterpolation> >& correlationStructure,
    const std::vector<Real>& recoveries,
    Size nBuckets = 200,
    Real max = 5.0,
    Real min = -5.0,
    Real nSteps = 50
);


%{
ext::shared_ptr<DefaultLossModel> GaussianHullWhiteBucketingBaseCorrelationLossModel(
    const Handle<BaseCorrelationTermStructure<QuantLib::BilinearInterpolation> >& correlationStructure,
    const std::vector<Real>& recoveries,
    Real recoveryScaling = 1.0,
    Size nBuckets = 200,
    Real max = 5.0,
    Real min = -5.0,
    Real nSteps = 50
){
    QuantLib::GaussianHullWhiteBucketingDefaultLossModel::copulaType::initTraits traits;
    return ext::shared_ptr<DefaultLossModel>(
        new QuantLib::BaseCorrelationLossModel<QuantLib::GaussianHullWhiteBucketingDefaultLossModel, QuantLib::BilinearInterpolation >(
            correlationStructure,
            recoveries,
            traits,
            recoveryScaling,
            nBuckets,
            max,
            min,
            nSteps
        )
    );
}
%}
ext::shared_ptr<DefaultLossModel> GaussianHullWhiteBucketingBaseCorrelationLossModel(
    const Handle<BaseCorrelationTermStructure<QuantLib::BilinearInterpolation> >& correlationStructure,
    const std::vector<Real>& recoveries,
    Real recoveryScaling = 1.0,
    Size nBuckets = 200,
    Real max = 5.0,
    Real min = -5.0,
    Real nSteps = 50
);


%{
ext::shared_ptr<DefaultLossModel> ChoeKwonBaseCorrelationLossModel(
    const Handle<BaseCorrelationTermStructure<QuantLib::BilinearInterpolation> >& correlationStructure,
    const std::vector<Real>& recoveries,
    const Real p,
    const Real q,
    const Real mu,
    const Real b
){
    QuantLib::ChoeKwonDefaultLossModel::copulaType::initTraits traits;
    return ext::shared_ptr<DefaultLossModel>(
        new QuantLib::BaseCorrelationLossModel<QuantLib::ChoeKwonDefaultLossModel, QuantLib::BilinearInterpolation >(
            correlationStructure,
            recoveries,
            traits,
            p,
            q,
            mu,
            b
        )
    );
}
%}
ext::shared_ptr<DefaultLossModel> ChoeKwonBaseCorrelationLossModel(
    const Handle<BaseCorrelationTermStructure<QuantLib::BilinearInterpolation> >& correlationStructure,
    const std::vector<Real>& recoveries,
    const Real p,
    const Real q,
    const Real mu,
    const Real b
);




%shared_ptr(SyntheticCDO);
class SyntheticCDO : public Instrument {
    public:
    SyntheticCDO (const ext::shared_ptr<Basket>& basket,
                  Protection::Side side,
                  const Schedule& schedule,
                  Rate upfrontRate,
                  Rate runningRate,
                  const DayCounter& dayCounter,
                  BusinessDayConvention paymentConvention,
                  ext::optional<Real> notional = ext::nullopt);

    const ext::shared_ptr<Basket>& basket() const;

    bool isExpired() const override;
    Rate fairPremium() const;
    Rate fairUpfrontPremium() const;
    Rate premiumValue () const;
    Rate protectionValue () const;
    Real premiumLegNPV() const;
    Real protectionLegNPV() const;
    /*!
      Total outstanding tranche notional, not wiped out
    */
    Real remainingNotional() const;
    /*! The number of times the contract contains the portfolio tranched 
            notional.
    */
    Real leverageFactor() const;
    //! Last protection date.
    const Date& maturity() const;
    /*! The Gaussian Copula LHP implied correlation that makes the 
        contract zero value. This is for a flat correlation along
        time and portfolio loss level.
    */
    Real implicitCorrelation(const std::vector<Real>& recoveries,
        const Handle<YieldTermStructure>& discountCurve, 
        Real targetNPV = 0.,
        Real accuracy = 1.0e-3) const;
    /*!
      Expected tranche loss for all payment dates
     */
    std::vector<Real> expectedTrancheLoss() const;
    Size error() const;
};


%shared_ptr(MidPointCDOEngine);
class MidPointCDOEngine : public PricingEngine {
  public:
    MidPointCDOEngine(Handle<YieldTermStructure> discountCurve);
};

%shared_ptr(IntegralCDOEngine);
class IntegralCDOEngine : public PricingEngine {
  public:
    IntegralCDOEngine(Handle<YieldTermStructure> discountCurve);
};

#endif