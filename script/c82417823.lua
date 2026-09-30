--クリスタルクリアウィング・シンクロ・ドラゴン・オブ・ザ・フォー・ヘブンリー・ドラゴンズ
--Crystal Clear Wing Synchro Dragon of the Four Heavenly Dragons
local s,id,o=GetID()

local CRYSTAL_CLEAR_WING_SYNCHRO_DRAGON=59765225

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- Synchro Summon procedure:
	-- 1 "Crystal Clear Wing Synchro Dragon" + 2+ Tuners
	-- Total Levels must equal this card's Level
	Synchro.AddProcedure(c,s.tunerfilter,2,99,s.crystalfilter,1,1)

	-- Synchro Summon procedure:
	-- 1 Synchro Tuner + 1 "Crystal Clear Wing Synchro Dragon"
	Synchro.AddProcedure(c,s.syntunerfilter,1,1,s.crystalfilter,1,1)

	c:AddMustBeSynchroSummoned()

	-- Your opponent cannot target "Clear Wing" monsters you control
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.prottg)
	e1:SetValue(s.tgval)
	c:RegisterEffect(e1)

	-- Your opponent cannot destroy "Clear Wing" monsters you control by card effects
	local e2=Effect.CreateEffect(c)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.prottg)
	e2:SetValue(s.indval)
	c:RegisterEffect(e2)

	-- When a "Clear Wing" monster(s) would leave the field because of an opponent's card effect
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)

	-- If this card leaves the field because of an opponent's card effect
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCountLimit(1,id+1)
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

s.listed_names={CRYSTAL_CLEAR_WING_SYNCHRO_DRAGON}
s.listed_series={SET_CLEAR_WING,SET_SYNCHRO_DRAGON}

function s.tunerfilter(c,scard,sumtype,tp)
	return c:IsType(TYPE_TUNER,scard,sumtype,tp)
		or c:IsHasEffect(EFFECT_CAN_BE_TUNER)
end

function s.syntunerfilter(c,scard,sumtype,tp)
	return c:IsType(TYPE_SYNCHRO,scard,sumtype,tp)
		and c:IsType(TYPE_TUNER,scard,sumtype,tp)
end

function s.crystalfilter(c,scard,sumtype,tp)
	return c:IsCode(CRYSTAL_CLEAR_WING_SYNCHRO_DRAGON)
end

function s.prottg(e,c)
	return c:IsFaceup()
		and c:IsSetCard(SET_CLEAR_WING)
end

function s.tgval(e,re,rp)
	return rp~=e:GetHandlerPlayer()
end

function s.indval(e,re,rp)
	return rp~=e:GetHandlerPlayer()
end

function s.negfilter(c,tp,re)
	return c:IsFaceup()
		and c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsSetCard(SET_CLEAR_WING)
		and c:IsRelateToEffect(re)
end

function s.relfilter(c,tp)
	return c:IsFaceup()
		and c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsSetCard(SET_CLEAR_WING)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp then return false end
	if not Duel.IsChainNegatable(ev) then return false end

	local ex,tg,ct,p,loc

	ex,tg,ct,p,loc=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
	if ex and tg and tg:IsExists(s.negfilter,1,nil,tp,re) then
		return true
	end

	ex,tg,ct,p,loc=Duel.GetOperationInfo(ev,CATEGORY_REMOVE)
	if ex and tg and tg:IsExists(s.negfilter,1,nil,tp,re) then
		return true
	end

	ex,tg,ct,p,loc=Duel.GetOperationInfo(ev,CATEGORY_TOGRAVE)
	if ex and tg and tg:IsExists(s.negfilter,1,nil,tp,re) then
		return true
	end

	ex,tg,ct,p,loc=Duel.GetOperationInfo(ev,CATEGORY_TOHAND)
	if ex and tg and tg:IsExists(s.negfilter,1,nil,tp,re) then
		return true
	end

	ex,tg,ct,p,loc=Duel.GetOperationInfo(ev,CATEGORY_TODECK)
	if ex and tg and tg:IsExists(s.negfilter,1,nil,tp,re) then
		return true
	end

	ex,tg,ct,p,loc=Duel.GetOperationInfo(ev,CATEGORY_RELEASE)
	if ex and tg and tg:IsExists(s.relfilter,1,nil,tp) then
		return true
	end

	return false
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsChainNegatable(ev)
	end

	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,re:GetHandler(),1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.NegateActivation(ev) then return end

	local tc=re:GetHandler()
	if not tc then return end

	local atk=0
	if tc:IsType(TYPE_MONSTER) then
		atk=tc:GetAttack()
	end

	if tc:IsRelateToEffect(re) then
		if Duel.SendtoGrave(tc,REASON_EFFECT)>0 and atk>0 then
			local c=e:GetHandler()
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(math.floor(atk/2))
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			c:RegisterEffect(e1)
		end
	end
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return rp==1-tp
		and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsPreviousPosition(POS_FACEUP)
		and c:GetReason()&REASON_EFFECT~=0
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_SYNCHRO_DRAGON)
		and c:IsType(TYPE_SYNCHRO)
		and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCountFromEx(tp,tp,nil)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end

	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local tc=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,1,
		nil,
		e,tp
	):GetFirst()

	if tc then
		if Duel.SpecialSummon(
			tc,
			SUMMON_TYPE_SYNCHRO,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)>0 then
			tc:CompleteProcedure()
		end
	end
end
