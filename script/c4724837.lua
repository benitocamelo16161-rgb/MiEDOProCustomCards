--Performapal Hipo, the Amazing Assistant of the King of Entertainment
local s,id,o=GetID()

function s.initial_effect(c)

	--Pendulum Procedure
	Pendulum.AddProcedure(c)

	--Pendulum Effect
	local pe=Effect.CreateEffect(c)


	--Pendulum Effect
	local pe=Effect.CreateEffect(c)
	pe:SetDescription(aux.Stringid(id,0))
	pe:SetCategory(CATEGORY_SPECIAL_SUMMON)
	pe:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	pe:SetCode(EVENT_DESTROYED)
	pe:SetRange(LOCATION_PZONE)
	pe:SetCountLimit(1,{id,0})
	pe:SetCondition(s.pecon)
	pe:SetTarget(s.petg)
	pe:SetOperation(s.peop)
	c:RegisterEffect(pe)

	--Treated as 2 Tributes for a Level 7 Dragon monster
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DOUBLE_TRIBUTE)
	e1:SetValue(s.tribval)
	c:RegisterEffect(e1)

	--Special Summon from hand or GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	--Search
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	local e3b=e3:Clone()
	e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3b)

	--Special Summon after a Pendulum Summon
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetRange(LOCATION_GRAVE+LOCATION_EXTRA)
	e4:SetCountLimit(1,{id,3})
	e4:SetCondition(s.pencon)
	e4:SetTarget(s.pentg)
	e4:SetOperation(s.penop)
	c:RegisterEffect(e4)

end

--========================================
-- Pendulum Effect
--========================================

function s.pefilter(c,tp)
	return c:IsControler(tp)
		and (
			c:IsSetCard(0x9f)
			or c:IsSetCard(0x98)
			or c:IsSetCard(0x99)
		)
		and c:IsReason(REASON_BATTLE+REASON_EFFECT)
end

function s.pecon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.pefilter,1,nil,tp)
end

function s.pesptg(c)
	return c:IsSetCard(0x9f)
		or c:IsSetCard(0x98)
end

function s.petg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.pesptg,
			tp,
			LOCATION_DECK+LOCATION_EXTRA,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_DECK+LOCATION_EXTRA
	)
end

function s.peop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(
		tp,
		s.pesptg,
		tp,
		LOCATION_DECK+LOCATION_EXTRA,
		0,
		1,
		1,
		nil
	)

	if #g>0 then
		Duel.SpecialSummon(
			g,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end

--========================================
-- 2 Tributes for Level 7 Dragon
--========================================

function s.tribval(e,c)
	return c:IsRace(RACE_DRAGON)
		and c:IsLevel(7)
end

--========================================
-- Special Summon from hand/GY
--========================================

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and (
			not Duel.IsExistingMatchingCard(
				aux.TRUE,
				tp,
				LOCATION_MZONE,
				0,
				1,
				nil
			)
			or Duel.IsExistingMatchingCard(
				function(c)
					return c:IsSetCard(0x9f)
						or c:IsSetCard(0x98)
						or c:IsSetCard(0x99)
				end,
				tp,
				LOCATION_MZONE,
				0,
				1,
				nil
			)
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		e:GetHandler(),
		1,
		tp,
		0
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsRelateToEffect(e) then
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
end

--========================================
-- Search
--========================================

function s.thfilter(c)
	return c:IsAbleToHand()
		and (
			c:IsSetCard(0x9f)
			or c:IsSetCard(0x98)
			or c:IsSetCard(0x99)
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
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--========================================
-- Special Summon after Pendulum Summon
--========================================

function s.pencon(e,tp,eg,ep,ev,re,r,rp)
	--All monsters in this event must have been Pendulum Summoned
	return eg:IsExists(
		function(c)
			return c:IsSummonType(SUMMON_TYPE_PENDULUM)
		end,
		1,
		nil
	)
end

function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)

	local c=e:GetHandler()

	if chk==0 then

		-- Hipo is in the Extra Deck:
		-- it needs a legal Extra Deck monster zone
		-- (Extra Monster Zone or a Main Monster Zone
		-- pointed to by a Link Monster).
		if c:IsLocation(LOCATION_EXTRA) then

			return Duel.GetLocationCountFromEx(
				tp,
				tp,
				nil,
				c
			)>0

		-- Hipo is in the GY:
		-- a normal Main Monster Zone is enough.
		else

			return Duel.GetLocationCount(
				tp,
				LOCATION_MZONE
			)>0
		end
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		c,
		1,
		tp,
		0
	)
end

function s.penop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then
		return
	end

	if Duel.SpecialSummon(
		c,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)==0 then
		return
	end

	-- You can choose whether to copy another monster's properties
	if not Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		return
	end

	local tc=Duel.SelectMatchingCard(
		tp,
		function(c)
			return c:IsFaceup()
		end,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	):GetFirst()

	if not tc then
		return
	end

	--Copy Level
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_LEVEL)
	e1:SetValue(tc:GetLevel())
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)

	--Copy Type
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CHANGE_RACE)
	e2:SetValue(tc:GetRace())
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e2)

	--Copy Attribute
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e3:SetValue(tc:GetAttribute())
	e3:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e3)
end