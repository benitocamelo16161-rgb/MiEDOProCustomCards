local s,id=GetID()

function s.initial_effect(c)

	--==================================================
	-- Nombre: "Red-Eyes Black Dragon" en campo/GY
	--==================================================
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE|LOCATION_GRAVE)
	e1:SetValue(CARD_REDEYES_B_DRAGON)
	c:RegisterEffect(e1)

	--==================================================
	-- Special Summon desde la mano
	-- Tributar 1 monstruo que mencione "Dark Time Wizard"
	--==================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	--==================================================
	-- Si es Invocado Normalmente o por Invocación Especial:
	-- revelar 1 Fusión y añadir un material listado
	--==================================================
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)

	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)

	--==================================================
	-- Invocación de Fusión
	-- El propio Red-Eyes Infernal Flame Dragon
	-- es material obligatorio
	--==================================================
	local e5=Fusion.CreateSummonEff(
		c,
		s.fusfilter,
		s.matfilter,
		s.fextra,
		s.shuffleop,
		c
	)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,{id,2})
	c:RegisterEffect(e5)
end

s.listed_names={
	CARD_REDEYES_B_DRAGON,
	CARD_DARK_TIME_WIZARD
}

--==================================================
-- SPECIAL SUMMON PROCEDURE
--==================================================

function s.releasefilter(c)
 return c:IsMonster()
  and (
   c:ListsCode(CARD_DARK_TIME_WIZARD)
   or c:IsCode(3129528)
  )
end

function s.spcon(e,c)
	if c==nil then return true end

	local tp=c:GetControler()

	return Duel.IsExistingMatchingCard(
		s.releasefilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(
		s.releasefilter,
		tp,
		LOCATION_MZONE,
		0,
		nil
	)

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_RELEASE
	)

	local sg=aux.SelectUnselectGroup(
		g,
		e,
		tp,
		1,
		1,
		nil,
		1,
		tp,
		HINTMSG_RELEASE,
		nil,
		nil,
		true
	)

	if #sg>0 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end

	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()

	if not g then return end

	Duel.Release(
		g,
		REASON_COST
	)

	g:DeleteGroup()
end

--==================================================
-- EFECTO DE REVELAR FUSIÓN / AÑADIR MATERIAL
--==================================================

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsSummonType(SUMMON_TYPE_NORMAL)
		or c:IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.exfilter(c,e,tp)
	return c:IsType(TYPE_FUSION)
		and c.material
		and Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil,
			c
		)
end

function s.thfilter(c,fc)
	if not c:IsAbleToHand() then
		return false
	end

	for _,code in ipairs(fc.material) do
		if c:IsCode(code) then
			return true
		end
	end

	return false
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.exfilter,
			tp,
			LOCATION_EXTRA,
			0,
			1,
			nil,
			e,
			tp
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
	local g=Duel.GetMatchingGroup(
		s.exfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,
		tp
	)

	if #g==0 then
		return
	end

	-- Elegir Fusión
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_CONFIRM
	)

	local fg=g:Select(tp,1,1,nil)

	if #fg==0 then
		return
	end

	local fc=fg:GetFirst()

	-- Revelar la Fusión
	Duel.ConfirmCards(
		1-tp,
		fg
	)

	-- Elegir material listado del Deck
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local mg=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil,
		fc
	)

	if #mg>0 then
		Duel.SendtoHand(
			mg,
			nil,
			REASON_EFFECT
		)

		Duel.ConfirmCards(
			1-tp,
			mg
		)
	end
end

--==================================================
-- EFECTO DE FUSIÓN
--==================================================

function s.fusfilter(c,e,tp)
	return c:IsType(TYPE_FUSION)
end

function s.matfilter(c,e,tp,chk)
	return c:IsAbleToDeck()
end

function s.fextra(e,tp)
	return Duel.GetMatchingGroup(
		s.matfilter,
		tp,
		LOCATION_HAND|LOCATION_GRAVE,
		0,
		nil,
		e,
		tp,
		0
	)
end

function s.shuffleop(e,tc,tp,sg)

	if #sg==0 then
		return
	end

	-- Barajar TODOS los materiales al Deck
	Duel.SendtoDeck(
		sg,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT+REASON_MATERIAL+REASON_FUSION
	)

	-- Muy importante:
	-- dejar el grupo vacío para impedir que
	-- Fusion.SummonEffOP mande los materiales al GY.
	sg:Clear()

	-- NO hacer "return false" aquí.
	-- Eso cancelaría la Invocación de Fusión.
end
