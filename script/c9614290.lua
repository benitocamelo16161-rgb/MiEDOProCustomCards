--トゥーン・イリュージョニスト・フェイスレス・マジシャン
--Toon Illusionist Faceless Mage
local s,id=GetID()

function s.initial_effect(c)

	--Cannot attack the turn it is Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetOperation(s.atklimit)
	c:RegisterEffect(e1)

	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	local e1c=e1:Clone()
	e1c:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e1c)

	--While you control "Toon World", your opponent cannot target this card with card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.twcon)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)

--While you control "Toon World", this card can only be attacked
local e3=Effect.CreateEffect(c)
e3:SetType(EFFECT_TYPE_SINGLE)
e3:SetCode(EFFECT_ONLY_BE_ATTACKED)
e3:SetRange(LOCATION_MZONE)
e3:SetCondition(s.twcon)
c:RegisterEffect(e3)

--While you control "Toon World", your opponent's monsters can only attack this card
local e3b=Effect.CreateEffect(c)
e3b:SetType(EFFECT_TYPE_FIELD)
e3b:SetCode(EFFECT_ONLY_ATTACK_MONSTER)
e3b:SetRange(LOCATION_MZONE)
e3b:SetCondition(s.twcon)
e3b:SetTargetRange(0,LOCATION_MZONE)
c:RegisterEffect(e3b)

	--While you control "Toon World" and your opponent controls no Toon monsters,
	--this card can attack directly
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_DIRECT_ATTACK)
	e4:SetCondition(s.dircon)
	c:RegisterEffect(e4)

	--You take no battle damage from battles involving this card
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e5:SetValue(1)
	c:RegisterEffect(e5)

	--When an opponent's monster declares an attack on this card:
	--You can take control of that opponent's monster,
	--and if you do, it is treated as a Toon monster
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,0))
	e6:SetCategory(CATEGORY_CONTROL)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e6:SetCode(EVENT_ATTACK_ANNOUNCE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1,id)
	e6:SetCondition(s.controlcon)
	e6:SetTarget(s.controltg)
	e6:SetOperation(s.controlop)
	c:RegisterEffect(e6)

	--Banish this card from your GY and 1 Toon card from your Deck,
	--both face-down; then banish 1 random card from your opponent's hand face-up
	--For the rest of this Duel, you cannot activate monster effects,
	--except Toon monsters or monsters that mention the Toon archetype
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,3))
	e7:SetCategory(CATEGORY_REMOVE)
	e7:SetType(EFFECT_TYPE_IGNITION)
	e7:SetRange(LOCATION_GRAVE)
	e7:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_DUEL)
	e7:SetCost(s.gycost)
	e7:SetTarget(s.gytg)
	e7:SetOperation(s.gyop)
	c:RegisterEffect(e7)

end

s.listed_names={CARD_TOON_WORLD}
s.listed_series={SET_TOON}

--Cannot attack the turn it is Summoned
function s.atklimit(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_ATTACK)
	e1:SetReset(RESETS_STANDARD_PHASE_END)
	e:GetHandler():RegisterEffect(e1)
end

--Toon World condition
function s.twcon(e,tp,eg,ep,ev,re,r,rp)
	local p=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(
		aux.FaceupFilter(Card.IsCode,CARD_TOON_WORLD),
		p,LOCATION_ONFIELD,0,1,nil
	)
end


--Direct attack condition
function s.dircon(e,tp,eg,ep,ev,re,r,rp)
	local p=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(
		aux.FaceupFilter(Card.IsCode,CARD_TOON_WORLD),
		p,LOCATION_ONFIELD,0,1,nil
	)
	and not Duel.IsExistingMatchingCard(
		aux.FaceupFilter(Card.IsType,TYPE_TOON),
		p,0,LOCATION_MZONE,1,nil
	)
end

--Attack declaration condition
function s.controlcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetAttacker()

	return tc
		and tc:IsControler(1-tp)
		and Duel.GetAttackTarget()==c
end

--Control target
function s.controltg(e,tp,eg,ep,ev,re,r,rp,chk)
	local tc=Duel.GetAttacker()

	if chk==0 then
		return tc
			and tc:IsFaceup()
			and tc:IsControler(1-tp)
			and tc:IsControlerCanBeChanged()
	end

	Duel.SetOperationInfo(0,CATEGORY_CONTROL,tc,1,0,0)
end

--Take control and make it a Toon
function s.controlop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetAttacker()

	if not tc
		or not tc:IsFaceup()
		or not tc:IsControler(1-tp)
		or not tc:IsControlerCanBeChanged() then
		return
	end

	if Duel.GetControl(tc,tp)>0 then
-- Treat it as a Toon monster
local e1=Effect.CreateEffect(e:GetHandler())
e1:SetType(EFFECT_TYPE_SINGLE)
e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
e1:SetCode(EFFECT_ADD_TYPE)
e1:SetValue(TYPE_TOON)
e1:SetDescription(aux.Stringid(id,2))
e1:SetReset(RESET_EVENT|RESETS_STANDARD)
tc:RegisterEffect(e1)

-- Allow it to attack directly as a Toon
local e2=Effect.CreateEffect(e:GetHandler())
e2:SetType(EFFECT_TYPE_SINGLE)
e2:SetCode(EFFECT_DIRECT_ATTACK)
e2:SetCondition(function(e)
    local p=e:GetHandlerPlayer()
    return Duel.IsExistingMatchingCard(
        aux.FaceupFilter(Card.IsCode,CARD_TOON_WORLD),
        p,LOCATION_ONFIELD,0,1,nil
    ) and not Duel.IsExistingMatchingCard(
        aux.FaceupFilter(Card.IsType,TYPE_TOON),
        p,0,LOCATION_MZONE,1,nil
    )
end)
e2:SetReset(RESET_EVENT|RESETS_STANDARD)
tc:RegisterEffect(e2)
 end
end

--------------------------------------------------
-- GY EFFECT
--------------------------------------------------

--Only Toon cards can be selected from the Deck
function s.toonfilter(c)
	return c:IsSetCard(SET_TOON)
		and c:IsAbleToRemove()
end

--Cost:
--Banish this card from the GY face-down
--and 1 Toon card from the Deck face-down
function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)

	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemoveAsCost()
			and Duel.IsExistingMatchingCard(
				s.toonfilter,tp,LOCATION_DECK,0,1,nil
			)
	end

	--Banish this card face-down
	Duel.Remove(c,POS_FACEDOWN,REASON_COST)

	--Banish 1 Toon card from the Deck face-down
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(
		tp,s.toonfilter,tp,LOCATION_DECK,0,1,1,nil
	)

	if #g>0 then
		Duel.Remove(g,POS_FACEDOWN,REASON_COST)
	end

	--The restriction is applied when this effect is ACTIVATED
	local e1=Effect.CreateEffect(c)
e1:SetDescription(aux.Stringid(id,3))
e1:SetType(EFFECT_TYPE_FIELD)
e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET|EFFECT_FLAG_CLIENT_HINT)
e1:SetCode(EFFECT_CANNOT_ACTIVATE)
e1:SetTargetRange(1,0)
e1:SetValue(s.cannotactivate)

Duel.RegisterEffect(e1,tp)
end

--Check that the opponent has at least 1 card in hand
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0
	end

	Duel.SetOperationInfo(
		0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND
	)
end

--GY effect operation
function s.gyop(e,tp,eg,ep,ev,re,r,rp)

	local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)

	if #g==0 then return end

	--Random card from opponent's hand
	local sg=g:RandomSelect(1-tp,1)

	if #sg>0 then
		--Banish it FACE-UP
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
	end
end

--Restriction:
--You cannot activate monster effects for the rest of this Duel,
--except Toon monsters or monsters that mention the Toon archetype
function s.cannotactivate(e,re)

	if not re:IsMonsterEffect() then
		return false
	end

	local c=re:GetHandler()

	--Toon monsters are allowed
	if c:IsType(TYPE_TOON) then
		return false
	end

	--Monsters that mention the Toon archetype are allowed
	if c:ListsCode(CARD_TOON_WORLD) then
    return false
end

	return true
end