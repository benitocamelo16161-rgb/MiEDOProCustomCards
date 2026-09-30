--ヘビーメタルキング
--Heavy Metal King
local s,id,o=GetID()

local MUSICIAN_KING=56907389
local METALMORPH=68540058

--Cannot be Normal Summoned
function s.cannotns(e,c)
	return true
end

--Cannot be Set
function s.cannotset(e,c)
	return true
end

--Material filter
function s.matfilter(c)
	return c:IsFaceup()
		and c:IsCode(MUSICIAN_KING)
		and c:IsReleasable()
		and c:GetEquipGroup():IsExists(s.metafilter,1,nil)
end

function s.metafilter(c)
	return c:IsCode(METALMORPH)
end

--Special Summon condition
function s.spcon(e,c)
	if c==nil then
		return true
	end

	local tp=c:GetControler()

	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE,0,1,nil)
end

--Special Summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	return true
end

--Tribute Musician King equipped with Metalmorph
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.matfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,1,
		nil
	)

	if #g>0 then
		Duel.Release(g,REASON_COST)
	end
end

--If this card attacks during damage calculation
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()

	return Duel.GetAttacker()==c
		and c:IsRelateToBattle()
		and bc~=nil
		and bc:IsRelateToBattle()
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()

	if not bc or not bc:IsRelateToBattle() then return end

	local atk=bc:GetAttack()
	if atk<0 then atk=0 end

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(math.floor(atk/2))
	e1:SetReset(RESET_PHASE+PHASE_DAMAGE_CAL)
	c:RegisterEffect(e1)
end


function s.initial_effect(c)
	c:EnableReviveLimit()

	--Cannot be Normal Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCode(EFFECT_CANNOT_SUMMON)
	c:RegisterEffect(e1)

	--Cannot be Set
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e2)

	--Must first be Special Summoned from the Deck
	--by Tributing "Musician King" equipped with "Metalmorph"
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetCode(EFFECT_SPSUMMON_CONDITION)
	e3:SetValue(aux.FALSE)
	c:RegisterEffect(e3)

	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_SPSUMMON_PROC)
	e4:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e4:SetRange(LOCATION_DECK)
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	e4:SetValue(SUMMON_TYPE_SPECIAL)
	c:RegisterEffect(e4)

	--	-- During damage calculation only; if this card attacks,
	-- it gains ATK equal to half the ATK of the attack target
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e5:SetCondition(s.atkcon)
	e5:SetOperation(s.atkop)
	c:RegisterEffect(e5)
end