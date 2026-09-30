--Red-Eyes Infernal Armament Dragon
local s,id=GetID()

function s.initial_effect(c)
	--Fusion Summon
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.mat1,s.mat2)

	--Set 1 Equip Card from Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SET)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	--Negate activation, destroy itself, inflict 700 damage
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

--Special Summon from Deck or GY
local e3=Effect.CreateEffect(c)
e3:SetDescription(aux.Stringid(id,2))
e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
e3:SetCode(EVENT_TO_GRAVE)
e3:SetProperty(EFFECT_FLAG_DELAY)
e3:SetCountLimit(1,id+2)
e3:SetTarget(s.sptg)
e3:SetOperation(s.spop)
c:RegisterEffect(e3)

	--Equip this card to a monster
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_EQUIP)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetRange(LOCATION_MZONE)
  e4:SetCountLimit(1)
	e4:SetTarget(s.eqtg)
	e4:SetOperation(s.eqop)
	c:RegisterEffect(e4)

	--Equipped monster gains 1000 ATK
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_EQUIP)
	e5:SetCode(EFFECT_UPDATE_ATTACK)
	e5:SetValue(1000)
	c:RegisterEffect(e5)

	--Equipped monster is unaffected by opponent's card effects
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_EQUIP)
	e6:SetCode(EFFECT_IMMUNE_EFFECT)
	e6:SetValue(s.efilter)
	c:RegisterEffect(e6)
end

s.listed_names={
	101402001,
	101402002,
	101402003,
	101402004,
	101402136,
 CARD_DARK_TIME_WIZARD
}

--Fusion materials
function s.mat1(c)
	return c:IsAttribute(ATTRIBUTE_FIRE)
end

function s.mat2(c)
	return c:IsCode(CARD_REDEYES_B_DRAGON)
end

--Set filter: Equip Spells + Equip Traps
function s.setfilter(c)
	return c:IsSSetable()
		and (c:IsType(TYPE_EQUIP) or c:IsEquipTrap())
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(
				s.setfilter,
				tp,
				LOCATION_DECK,
				0,
				1,
				nil
			)
	end
	Duel.SetOperationInfo(
		0,
		CATEGORY_SET,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(
		tp,
		s.setfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)
	local tc=g:GetFirst()
	if not tc then return end

	if Duel.SSet(tp,tc)>0 and tc:IsTrap() then
		--Can be activated this turn
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(aux.Stringid(id,4))
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

--Negate activation
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
		and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		e:GetHandler(),
		1,
		0,
		0
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DAMAGE,
		nil,
		0,
		1-tp,
		700
	)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--If this card is no longer in the Monster Zone, the negate is cancelled
	if not c:IsLocation(LOCATION_MZONE) then return end

	if Duel.NegateActivation(ev) then
		if Duel.Destroy(c,REASON_EFFECT)>0 then
			Duel.Damage(1-tp,700,REASON_EFFECT)
		end
	end
end

--Special Summon filter
function s.spfilter(c,e,tp)
	return (
		(c:IsAttribute(ATTRIBUTE_FIRE) and c:IsRace(RACE_WARRIOR))
		or c:IsCode(
			101402001,
			101402002,
			101402003,
			101402004,
			101402136
		)
		or c:ListsCode(CARD_DARK_TIME_WIZARD)
	)
	and not c:IsType(
		TYPE_FUSION|
		TYPE_RITUAL|
		TYPE_SYNCHRO|
		TYPE_XYZ|
		TYPE_LINK
	)
	and c:IsCanBeSpecialSummoned(
		e,
		0,
		tp,
		false,
		false
	)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.spfilter,
				tp,
				LOCATION_DECK|LOCATION_GRAVE,
				0,
				1,
				nil,
				e,
				tp
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_DECK|LOCATION_GRAVE
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_DECK|LOCATION_GRAVE,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(
			tc,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end

--Equip target
function s.eqfilter(c)
	return c:IsFaceup()
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsFaceup()
			and chkc~=e:GetHandler()
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingTarget(
				s.eqfilter,
				tp,
				LOCATION_MZONE,
				LOCATION_MZONE,
				1,
				e:GetHandler()
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)

	Duel.SelectTarget(
		tp,
		s.eqfilter,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		1,
		1,
		e:GetHandler()
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_EQUIP,
		e:GetHandler(),
		1,
		0,
		0
	)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()

	if not tc then return end

	if not c:IsRelateToEffect(e)
		or c:IsFacedown()
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup() then
		return
	end

	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

	if Duel.Equip(tp,c,tc) then
		--Equip limit
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetValue(s.eqlimit)
		e1:SetLabelObject(tc)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end

function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end

--Unaffected by opponent's card effects
function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end