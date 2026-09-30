
--クリスタル召喚
--Cristal Invocacion
--Kurigod El Ser Celestial De Cristal

local s,id,o=GetID()

function s.initial_effect(c)
 c:EnableReviveLimit()

 -- Special Summon itself from the Extra Deck when a direct attack is declared
 local e1=Effect.CreateEffect(c)
 e1:SetDescription(aux.Stringid(id,0))
 e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
 e1:SetCode(EVENT_ATTACK_ANNOUNCE)
 e1:SetRange(LOCATION_EXTRA)
 e1:SetCountLimit(1,id)
 e1:SetCondition(s.spcon)
 e1:SetTarget(s.sptg)
 e1:SetOperation(s.spop)
 c:RegisterEffect(e1)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
 local at=Duel.GetAttacker()
 return at
  and at:IsControler(1-tp)
  and Duel.GetAttackTarget()==nil
  and Duel.GetLocationCountFromEx(tp,tp,nil)>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
 if chk==0 then
  return Duel.GetLocationCountFromEx(tp,tp,nil)>0
 end

 -- Absolutely nothing can be chained to this effect
 Duel.SetChainLimit(aux.FALSE)

 Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
 local c=e:GetHandler()

 if not c:IsLocation(LOCATION_EXTRA) then return end
 if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then return end

 -- Special Summon from the Extra Deck
 if Duel.SpecialSummon(
  c,
  SUMMON_TYPE_SPECIAL,
  tp,
  tp,
  true,
  true,
  POS_FACEUP
 )>0 then

  -- YOU WIN.
  Duel.Win(tp,REASON_EFFECT)
 end
end