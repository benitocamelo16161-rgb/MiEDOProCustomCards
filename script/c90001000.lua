--Nameless Palladium Pharaoh
local s,id,o=GetID()

function s.initial_effect(c)

	--Reveal 1 other card; Special Summon this card
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--Treated as 3 Tributes
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRIPLE_TRIBUTE)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	--Search 1 Egyptian God + 1 Spell/Trap that mentions it
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

	-- Grant effects to the monster Summoned using this card as Tribute
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_BE_PRE_MATERIAL)
	e4:SetCondition(s.regcon)
	e4:SetOperation(s.regop)
	c:RegisterEffect(e4)

end

s.listed_names={
	10000020,	--Slifer the Sky Dragon
	10000000,	--Obelisk the Tormentor
	10000010	--The Winged Dragon of Ra
}

--==================================================
-- SPECIAL SUMMON
--==================================================

function s.revealfilter(c,sc)
	return c:IsLocation(LOCATION_HAND)
		and c~=sc
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.revealfilter,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil,
			e:GetHandler()
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_CONFIRM
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.revealfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil,
		e:GetHandler()
	)

	if #g>0 then
		Duel.ConfirmCards(
			1-tp,
			g
		)
	end
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(
				e,
				0,
				tp,
				false,
				false
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		e:GetHandler(),
		1,
		0,
		0
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then return end

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
-- GOD SEARCH
--==================================================

function s.godfilter(c)
	return c:IsMonster()
		and c:IsCode(
			10000020,
			10000000,
			10000010
		)
		and c:IsAbleToHand()
end

function s.thfilter(c,code)
	return c:IsSpellTrap()
		and c:IsAbleToHand()
		and c:ListsCode(code)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.godfilter,
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
	--Add 1 Egyptian God
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.godfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local god=g:GetFirst()
	if not god then return end

	Duel.SendtoHand(
		g,
		nil,
		REASON_EFFECT
	)

	Duel.ConfirmCards(
		1-tp,
		g
	)

	--Then add a Spell/Trap that mentions that God
	local code=god:GetCode()

	if not Duel.IsExistingMatchingCard(
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		nil,
		code
	) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local sg=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
	nil,
		code
	)

	if #sg>0 then
		Duel.SendtoHand(
			sg,
			nil,
			REASON_EFFECT
		)

		Duel.ConfirmCards(
			1-tp,
			sg
		)
	end
end

--==================================================
-- TRIBUTE EFFECT
--==================================================

function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetHandler():GetReasonCard()

	return r==REASON_SUMMON
		and rc
		and rc:IsFaceup()
		and rc:IsTributeSummoned()
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()

	if not rc then return end

	-- Unaffected by opponent's card effects
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.efilter)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	rc:RegisterEffect(e1)

	-- Cannot be destroyed by battle except by Level 10 or higher
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,4))
	e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetValue(s.indval)
	e2:SetReset(RESET_EVENT|RESETS_STANDARD)
	rc:RegisterEffect(e2)
end

function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

function s.indval(e,tc)
	return not tc:IsLevelAbove(10)
end