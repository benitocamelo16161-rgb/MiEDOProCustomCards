--Armored Drake, the Dragon of Eternal Flame
local s,id,o=GetID()

s.listed_names={CARD_DARK_TIME_WIZARD}

function s.initial_effect(c)

	--==================================================
	-- Add 1 Dragon + up to 2 Spells/Traps that
	-- mention "Dark Time Wizard"
	--==================================================
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id+5)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	--==================================================
	-- Give a negate to the first Fusion/Xyz/Link
	-- monster that uses this card as material
	--==================================================
	local e3=Effect.CreateEffect(c)
e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
e3:SetCode(EVENT_BE_MATERIAL)
e3:SetProperty(EFFECT_FLAG_EVENT_PLAYER)

-- IMPORTANT:
-- Same count code for every Drake = shared limit.
-- The count resets each turn.
e3:SetCountLimit(1,id+1)

e3:SetCondition(s.effcon)
e3:SetOperation(s.effop)
c:RegisterEffect(e3)
end

function s.dragonfilter(c)
	return c:IsRace(RACE_DRAGON)
		and c:IsAbleToHand()
end

function s.darkfilter(c)
	return c:IsSpellTrap()
		and c:ListsCode(CARD_DARK_TIME_WIZARD)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if e:GetHandler():GetFlagEffect(id+4)>0 then
			return false
		end

		return Duel.IsExistingMatchingCard(
			s.dragonfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
		or Duel.IsExistingMatchingCard(
			s.darkfilter,
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
	local c=e:GetHandler()
	c:RegisterFlagEffect(
		id+4,
		RESET_EVENT+RESET_PHASE+PHASE_END,
		0,
		1
	)

	-- Add 1 Dragon
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,
		s.dragonfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end

	-- Add up to 2 Spells/Traps that mention
	-- "Dark Time Wizard", with different names
	local sg=Duel.GetMatchingGroup(
		s.darkfilter,
		tp,
		LOCATION_DECK,
		0,
		nil
	)

	local ct=math.min(sg:GetCount(),2)

	if ct>0 then
		local tg=Group.CreateGroup()

		while tg:GetCount()<ct and sg:GetCount()>0 do

			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

			local g=sg:Select(tp,1,1,nil)

			if #g==0 then
				break
			end

			local tc=g:GetFirst()
			tg:AddCard(tc)

			-- Remove cards with the same name
			local same=sg:Filter(
				function(c)
					return c:IsCode(tc:GetCode())
				end,
				nil
			)

			sg:Sub(same)
		end

		if #tg>0 then
			Duel.SendtoHand(tg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tg)
		end
	end

	-- Discard 1 card
	if Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)

		local dg=Duel.SelectMatchingCard(
			tp,
			aux.TRUE,
			tp,
			LOCATION_HAND,
			0,
			1,
			1,
			nil
		)

		if #dg>0 then
			Duel.SendtoGrave(
				dg,
				REASON_EFFECT+REASON_DISCARD
			)
		end
	end
end

--==================================================
-- Material effect
--==================================================
function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()

	if not rc then
		return false
	end

	-- Must be used as Fusion/Xyz/Link material
	if bit.band(r,REASON_FUSION+REASON_XYZ+REASON_LINK)==0 then
		return false
	end

	-- The summoned monster must actually have used
	-- this Drake as material
	local mg=rc:GetMaterial()
	if not mg or not mg:IsContains(c) then
		return false
	end

	return true
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()

	if not rc then
		return
	end

	--==================================================
	-- Give THIS Fusion/Xyz/Link its own negate.
	--==================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)

	-- IMPORTANT:
	-- No shared id here.
	-- Every monster receiving this effect gets
	-- its own once-per-turn negate.
	e1:SetCountLimit(1)

	e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e1:SetCondition(s.discon)
	e1:SetTarget(s.distg)
	e1:SetOperation(s.disop)

	-- The negate belongs to this monster.
	-- It remains as long as this monster remains
	-- on the field.
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)

	rc:RegisterEffect(e1)
end

function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED)
		and rp==1-tp
		and Duel.IsChainDisablable(ev)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_DISABLE,
		eg,
		1,
		0,
		0
	)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end
