--Supreme King Dragon Skywurm
local s,id=GetID()

function s.initial_effect(c)
	--Always treated as "Supreme King Z-ARC"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE|LOCATION_PZONE|LOCATION_GRAVE)
	e1:SetValue(13331639)
	c:RegisterEffect(e1)

	--Special Summon itself from hand or GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_HAND|LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,0})
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	--Add 1 "Supreme King Dragon" monster or 1 "Gate" card
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	--Pendulum Effect
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SET)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_PZONE)
	e4:SetCountLimit(1,{id,2})
	e4:SetTarget(s.settg)
	e4:SetOperation(s.setop)
	c:RegisterEffect(e4)
end

s.listed_names={13331639}
s.listed_series={0x10f8,0x20f8}

--==================================================
-- SPECIAL SUMMON
--==================================================

function s.spcon(e,c)
	if c==nil then return true end
	return not Duel.IsExistingMatchingCard(
		aux.TRUE,
		c:GetControler(),
		LOCATION_MZONE,
		LOCATION_MZONE,
		1,
		nil
	)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	return true
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.SpecialSummon(
		c,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)
end

--==================================================
-- SEARCH
--==================================================

function s.thfilter(c)
	return c:IsAbleToHand()
		and (
			c:IsSetCard(0x20f8)
			or c:IsSetCard(0x10f8)
		)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if #g>0 then
		Duel.SendtoHand(
			g,
			nil,
			REASON_EFFECT
		)

		Duel.ConfirmCards(
			1-tp,
			g
		)
	end
end

--==================================================
-- PENDULUM EFFECT
-- Set 1 Spell/Trap that mentions "Supreme King Z-ARC"
--==================================================

function s.setfilter(c)
	return c:IsSpellTrap()
		and c:IsSSetable()
		and c:ListsCode(13331639)
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

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SET
	)

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

	Duel.SSet(tp,tc)
end