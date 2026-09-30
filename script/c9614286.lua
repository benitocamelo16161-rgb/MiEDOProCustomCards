--Toon Relinquished
local s,id=GetID()

function s.initial_effect(c)

	--Cannot be Normal Summoned/Set
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_SUMMON)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e2)

	--Special Summon from hand by Tributing Toon monsters
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_SPSUMMON_PROC)
	e3:SetRange(LOCATION_HAND)
	e3:SetCountLimit(1)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

	--Can attack directly
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetCode(EFFECT_DIRECT_ATTACK)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.dircon)
	c:RegisterEffect(e4)

	--Equip opponent's Effect Monster when they activate a monster effect
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_EQUIP)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetCondition(s.eqcon)
	e5:SetTarget(s.eqtg)
	e5:SetOperation(s.eqop)
	c:RegisterEffect(e5)

	--Gain ATK equal to equipped monster's original ATK
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetCode(EFFECT_SET_ATTACK)
	e6:SetRange(LOCATION_MZONE)
	e6:SetValue(s.atkval)
	c:RegisterEffect(e6)

	--Gain DEF equal to equipped monster's original DEF
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e7:SetCode(EFFECT_SET_DEFENSE)
	e7:SetRange(LOCATION_MZONE)
	e7:SetValue(s.defval)
	c:RegisterEffect(e7)
end

--==================================================
-- Special Summon procedure
--==================================================

function s.spfilter(c,sc)
	return c~=sc
		and c:IsType(TYPE_TOON)
		and c:IsLevelAbove(1)
		and c:IsReleasable()
end

function s.spcon(e,c)
	if c==nil then return true end

	local tp=c:GetControler()

	return Duel.IsExistingMatchingCard(
		s.spfilter,
		tp,
		LOCATION_HAND|LOCATION_MZONE,
		0,
		1,
		nil,
		c
	)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.spfilter,
			tp,
			LOCATION_HAND|LOCATION_MZONE,
			0,
			1,
			nil,
			c
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_HAND|LOCATION_MZONE,
		0,
		1,
		1,
		nil,
		c
	)

	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end

	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()

	if not g then return end

	Duel.Release(g,REASON_COST)

	g:DeleteGroup()
end

--==================================================
-- Direct attack
--==================================================

function s.dircon(e)
	return Duel.IsExistingMatchingCard(
		aux.FaceupFilter(Card.IsCode,CARD_TOON_WORLD),
		e:GetHandlerPlayer(),
		LOCATION_ONFIELD,
		0,
		1,
		nil
	)
	and not Duel.IsExistingMatchingCard(
		aux.FaceupFilter(Card.IsType,TYPE_TOON),
		e:GetHandlerPlayer(),
		0,
		LOCATION_MZONE,
		1,
		nil
	)
end

--==================================================
-- Equip opponent's Effect Monster
--==================================================

function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and re:IsActiveType(TYPE_MONSTER)
end

function s.eqfilter(c)
	return c:IsType(TYPE_MONSTER+TYPE_EFFECT)
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE|LOCATION_GRAVE)
			and s.eqfilter(chkc)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingTarget(
				s.eqfilter,
				tp,
				0,
				LOCATION_MZONE|LOCATION_GRAVE,
				1,
				nil
			)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_EQUIP
	)

	local g=Duel.SelectTarget(
		tp,
		s.eqfilter,
		tp,
		0,
		LOCATION_MZONE|LOCATION_GRAVE,
		1,
		1,
		nil
	)

	if g:GetFirst():IsLocation(LOCATION_GRAVE) then
		Duel.SetOperationInfo(
			0,
			CATEGORY_LEAVE_GRAVE,
			g,
			1,
			0,
			0
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_EQUIP,
		g,
		1,
		0,
		0
	)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()

	if not tc then return end

	if not tc:IsRelateToEffect(e)
		or not tc:IsType(TYPE_MONSTER) then
		return
	end

	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	if not Duel.Equip(tp,tc,c) then
		return
	end

	--Equip limit
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_OWNER_RELATE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetValue(s.eqlimit)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)
end

function s.eqlimit(e,c)
	return e:GetOwner()==c
end

--==================================================
-- ATK / DEF
--==================================================

function s.atkval(e,c)
	local g=e:GetHandler():GetEquipGroup()
	local atk=0

	for tc in aux.Next(g) do
		local a=tc:GetBaseAttack()
		if a>0 then
			atk=atk+a
		end
	end

	return atk
end

function s.defval(e,c)
	local g=e:GetHandler():GetEquipGroup()
	local def=0

	for tc in aux.Next(g) do
		local d=tc:GetBaseDefense()
		if d>0 then
			def=def+d
		end
	end

	return def
end