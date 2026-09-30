--究極封印王エクゾディア
--Exodia the Ultimate Forbidden Lord
local s,id,o=GetID()

function s.initial_effect(c)

	--Special Summon procedure
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--Cannot be Special Summoned by other ways
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_SPSUMMON_CONDITION)
	e2:SetValue(s.splimit)
	c:RegisterEffect(e2)

	--Send all cards your opponent controls to the GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetTarget(s.gytg)
	e3:SetOperation(s.gyop)
	c:RegisterEffect(e3)

	--ATK gain
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetValue(s.atkval)
	c:RegisterEffect(e4)

	--DEF gain
	local e5=e4:Clone()
	e5:SetCode(EFFECT_UPDATE_DEFENSE)
	e5:SetValue(s.defval)
	c:RegisterEffect(e5)

	--Pay LP
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_ATKCHANGE)
	e6:SetType(EFFECT_TYPE_IGNITION)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1,id)
	e6:SetCost(s.lpcost)
	e6:SetOperation(s.lpop)
	c:RegisterEffect(e6)

	--Unaffected by effects
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCode(EFFECT_IMMUNE_EFFECT)
	e7:SetValue(s.efilter)
	c:RegisterEffect(e7)

	--Battle destruction protection
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_SINGLE)
	e8:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e8:SetValue(s.battlefilter)
	c:RegisterEffect(e8)

	--Mandatory End Phase penalty
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,2))
	e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e9:SetCode(EVENT_PHASE+PHASE_END)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCountLimit(1)
	e9:SetCondition(s.epcon)
	e9:SetTarget(s.eptg)
	e9:SetOperation(s.epop)
	c:RegisterEffect(e9)

	--Check DARK monster
	local e10=Effect.CreateEffect(c)
	e10:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e10:SetCode(EVENT_SPSUMMON_SUCCESS)
	e10:SetOperation(s.darkcheck)
	c:RegisterEffect(e10)

end

--Special Summon condition
function s.spcon(e,c)

	if c==nil then
		return true
	end

	local tp=c:GetControler()

	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(
			function(tc)
				return tc:IsAttribute(ATTRIBUTE_DARK)
			end,
			tp,
			LOCATION_GRAVE,
			0,
			5,
			nil
		)

end

--Only this Special Summon procedure
function s.splimit(e,se,sp,st)

	return se and se:GetHandler():IsCode(id)

end

--Target
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return true
	end

	Duel.SetChainLimit(function()
		return false
	end)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOGRAVE,
		nil,
		0,
		1-tp,
		LOCATION_ONFIELD
	)

end

--Send all opponent's cards to the GY
function s.gyop(e,tp,eg,ep,ev,re,r,rp)

	local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)

	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end

end

--Check DARK monster
function s.darkcheck(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	if Duel.IsExistingMatchingCard(
		function(tc)
			return tc:IsFaceup() and tc:IsAttribute(ATTRIBUTE_DARK)
		end,
		tp,
		0,
		LOCATION_MZONE,
		1,
		nil
	) then

		c:RegisterFlagEffect(
			id,
			RESET_EVENT+RESETS_STANDARD,
			0,
			1
		)

	end

end

--Count Forbidden One / DARK monsters
function s.getcount(c)

	local ct=0

	local g1=Duel.GetMatchingGroup(
		function(tc)
			return tc:IsSetCard(0x40) or tc:IsAttribute(ATTRIBUTE_DARK)
		end,
		0,
		LOCATION_GRAVE,
		LOCATION_GRAVE,
		nil
	)

	ct=#g1

	return ct

end

--ATK from GY
function s.atkval(e,c)

	local atk=s.getcount(c)*1000

	if c:GetFlagEffect(id)>0 then
		atk=atk*2
	end

	return atk

end

--DEF from GY
function s.defval(e,c)

	return s.getcount(c)*1000

end

--Pay all LP except 100
function s.lpcost(e,tp,eg,ep,ev,re,r,rp,chk)

	local lp=Duel.GetLP(tp)

	if chk==0 then
		return lp>100
	end

	local paid=lp-100

	Duel.PayLPCost(tp,paid)

	Duel.RegisterFlagEffect(
		tp,
		id+100,
		RESET_PHASE+PHASE_END,
		0,
		1
	)

	e:SetLabel(paid)

end

--Gain ATK/DEF
function s.lpop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()
	local paid=e:GetLabel()

	if paid>0 and c:IsFaceup() then

		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(paid)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)

		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		c:RegisterEffect(e2)

	end

end

--Unaffected by Spell/Trap and non-DARK/LIGHT/DIVINE monsters
function s.efilter(e,te)

	local tc=te:GetHandler()

	if tc:IsType(TYPE_MONSTER) then

		return not (
			tc:IsAttribute(ATTRIBUTE_DARK)
			or tc:IsAttribute(ATTRIBUTE_LIGHT)
			or tc:IsAttribute(ATTRIBUTE_DIVINE)
		)

	end

	return true

end

--Battle protection
function s.battlefilter(e,c)

	return c:IsAttribute(ATTRIBUTE_DARK)
		or c:IsAttribute(ATTRIBUTE_LIGHT)
		or c:IsAttribute(ATTRIBUTE_DIVINE)

end

--End Phase condition
function s.epcon(e,tp,eg,ep,ev,re,r,rp)

	return Duel.GetFlagEffect(tp,id+100)==0

end

--Target monster, except Exodia itself
function s.eptg(e,tp,eg,ep,ev,re,r,rp,chk)

	local c=e:GetHandler()

	if chk==0 then

		return Duel.IsExistingMatchingCard(
			function(tc)
				return tc:IsMonster() and tc~=c
			end,
			tp,
			LOCATION_HAND+LOCATION_MZONE,
			0,
			1,
			nil
		)

	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOGRAVE,
		nil,
		1,
		tp,
		LOCATION_HAND+LOCATION_MZONE
	)

end

--Send monster or lose LP
function s.epop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	local g=Duel.SelectMatchingCard(
		tp,
		function(tc)
			return tc:IsMonster() and tc~=c
		end,
		tp,
		LOCATION_HAND+LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	if #g>0 then

		Duel.SendtoGrave(g,REASON_EFFECT)

	else

		Duel.Damage(
			tp,
			c:GetLevel()*1000,
			REASON_EFFECT
		)

	end

end