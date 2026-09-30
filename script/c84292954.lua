--H. O. P. E.
local s,id,o=GetID()

-- Store the activation turn for each physical copy
s.hope_turn={}

-- Store whether the activation of each physical copy was negated
s.hope_negated={}

-- Store the H.O.P.E. currently being activated
s.hope_pending={}

function s.initial_effect(c)

	--========================================
	-- Effect 2: Banish this card from GY
	--========================================

	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_RECOVER+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.gycost)
	e2:SetCondition(s.gycon)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)

	--========================================
	-- Effect 1: Fusion Summon
	--========================================

	local e1=Fusion.CreateSummonEff(
		c,
		s.fusfilter,
		nil,
		s.extrafil,
		s.extraop,
		nil,
		nil
	)

	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(s.cost)

	c:RegisterEffect(e1)

	--========================================
	-- Detect activation negation
	--========================================

	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAIN_NEGATED)
	e3:SetOperation(s.chainnegated)
	Duel.RegisterEffect(e3,0)

	--========================================
	-- Clear pending activation after chain
	--========================================

	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_CHAIN_END)
	e4:SetOperation(s.chainend)
	Duel.RegisterEffect(e4,0)
end

--========================================
-- Activation Cost
--========================================

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)

	local hand=Duel.IsExistingMatchingCard(
		Card.IsDiscardable,
		tp,
		LOCATION_HAND,
		0,
		1,
		nil
	)

	local deck=Duel.GetFieldGroupCount(
		tp,
		LOCATION_DECK,
		0
	)>0

	if chk==0 then
		return hand or deck
	end

	local c=e:GetHandler()

	-- Store the activation turn for this physical copy
	s.hope_turn[c]=Duel.GetTurnCount(tp)

	-- This activation has not been negated yet
	s.hope_negated[c]=false

	-- Remember which physical H.O.P.E. is currently activating
	s.hope_pending[tp]=c

	-- If both options are available
	if hand and deck then

		local op=Duel.SelectOption(
			tp,
			aux.Stringid(id,2),
			aux.Stringid(id,3)
		)

		-- Discard 1 card from hand
		if op==0 then

			Duel.Hint(
				HINT_SELECTMSG,
				tp,
				HINTMSG_DISCARD
			)

			local g=Duel.SelectMatchingCard(
				tp,
				Card.IsDiscardable,
				tp,
				LOCATION_HAND,
				0,
				1,
				1,
				nil
			)

			Duel.SendtoGrave(
				g,
				REASON_COST+REASON_DISCARD
			)

		-- Send top card of Deck to GY
		else

			local g=Duel.GetDecktopGroup(tp,1)

			Duel.SendtoGrave(
				g,
				REASON_COST
			)
		end

	-- Only discard is possible
	elseif hand then

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_DISCARD
		)

		local g=Duel.SelectMatchingCard(
			tp,
			Card.IsDiscardable,
			tp,
			LOCATION_HAND,
			0,
			1,
			1,
			nil
		)

		Duel.SendtoGrave(
			g,
			REASON_COST+REASON_DISCARD
		)

	-- Only top of Deck is possible
	else

		local g=Duel.GetDecktopGroup(tp,1)

		Duel.SendtoGrave(
			g,
			REASON_COST
		)
	end
end

--========================================
-- Detect activation negation
--========================================

function s.chainnegated(e,tp,eg,ep,ev,re,r,rp)

	local chain_card=Duel.GetChainInfo(
		ev,
		CHAININFO_TRIGGERING_CODE
	)

	if not chain_card then
		return
	end

	-- Check both players' pending H.O.P.E.
	for p=0,1 do

		local c=s.hope_pending[p]

		if c and chain_card==id then

			s.hope_negated[c]=true
			s.hope_pending[p]=nil

			return
		end
	end
end

--========================================
-- Chain End
--========================================

function s.chainend(e,tp,eg,ep,ev,re,r,rp)

	-- If the activation was NOT negated,
	-- simply clear the pending reference.
	for p=0,1 do
		s.hope_pending[p]=nil
	end
end

--========================================
-- HERO Fusion Monster
--========================================

function s.fusfilter(c,tp)
	return c:IsSetCard(0x8)
end

-- Materials from hand or Deck
function s.extrafil(e,tp)

	return Duel.GetMatchingGroup(
		Card.IsMonster,
		tp,
		LOCATION_HAND+LOCATION_DECK,
		0,
		nil
	)
end

--========================================
-- Randomly banish 1 Fusion Material
--========================================

function s.extraop(e,tc,tp,mg)

	if #mg==0 then
		return
	end

	local rg=mg:RandomSelect(tp,1)

	if #rg>0 then

		Duel.Remove(
			rg,
			POS_FACEUP,
			REASON_EFFECT+REASON_MATERIAL+REASON_FUSION
		)

		mg:Sub(rg)
	end
end

--========================================
-- GY Effect
--========================================

function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)

	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemoveAsCost()
	end

	Duel.Remove(
		c,
		POS_FACEUP,
		REASON_COST
	)
end

-- Only usable during your next turn
-- and only if the activation itself was NOT negated
function s.gycon(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	return s.hope_turn[c]~=nil
		and not s.hope_negated[c]
		and Duel.GetTurnPlayer()==tp
		and Duel.GetTurnCount(tp)>s.hope_turn[c]
end

function s.gyfilter(c)
	return c:IsFaceup()
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsFaceup()
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			Card.IsFaceup,
			tp,
			LOCATION_MZONE,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TARGET
	)

	Duel.SelectTarget(
		tp,
		Card.IsFaceup,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DISABLE,
		nil,
		1,
		0,
		LOCATION_MZONE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_RECOVER,
		nil,
		0,
		tp,
		0
	)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)

	local tc=Duel.GetFirstTarget()

	if not tc or not tc:IsFaceup() then
		return
	end

	local atk=tc:GetAttack()

	-- Gain LP equal to the target's ATK
	if atk>0 then
		Duel.Recover(
			tp,
			atk,
			REASON_EFFECT
		)
	end

	-- Permanently negate the target's effects
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(
		RESET_EVENT+RESETS_STANDARD
	)
	tc:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	tc:RegisterEffect(e2)
end