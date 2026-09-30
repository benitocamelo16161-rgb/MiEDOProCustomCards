--罪宝のゴブリンライダー
--Sinful Spoils of the Goblin Biker
local s,id,o=GetID()

function s.initial_effect(c)

	-- Detach 1 Xyz Material; Special Summon 1 Level 4 or lower "Goblin" monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Banish this card from the GY; add 1 "Goblin" or "Diabell" monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.thcost)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- "Goblin" Level 4 or lower
function s.gobfilter(c,e,tp)
	return c:IsSetCard(SET_GOBLIN)
		and c:IsLevelBelow(4)
		and c:IsMonster()
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Detach 1 Xyz Material from a monster on the field
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.CheckRemoveOverlayCard(tp,LOCATION_MZONE,LOCATION_MZONE,1,REASON_COST)
	end
	Duel.RemoveOverlayCard(tp,LOCATION_MZONE,LOCATION_MZONE,1,1,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.gobfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(
		tp,
		s.gobfilter,
		tp,
		LOCATION_HAND+LOCATION_DECK,
		0,
		1,1,
		nil,
		e,tp
	)

	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- Banish this card from the GY
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return e:GetHandler():IsAbleToRemoveAsCost()
	end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- Target 1 "Goblin" monster in your GY
function s.gyfilter(c)
	return c:IsSetCard(SET_GOBLIN)
		and c:IsMonster()
		and c:IsAbleToDeck()
end

-- "Goblin" or "Diabell" Level 4 or lower
function s.addfilter(c)
	return c:IsMonster()
		and c:IsLevelBelow(4)
		and (c:IsSetCard(SET_GOBLIN) or c:IsSetCard(SET_DIABELL))
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE)
			and chkc:IsControler(tp)
			and s.gyfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(s.gyfilter,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.addfilter,tp,LOCATION_DECK,0,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.gyfilter,tp,LOCATION_GRAVE,0,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(
		tp,
		s.addfilter,
		tp,
		LOCATION_DECK,
		0,
		1,1,
		nil
	)

	local sc=g:GetFirst()
	if not sc then return end

	if Duel.SendtoHand(sc,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,sc)
		if tc:IsLocation(LOCATION_GRAVE) then
			Duel.SendtoDeck(tc,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
		end
	end
end