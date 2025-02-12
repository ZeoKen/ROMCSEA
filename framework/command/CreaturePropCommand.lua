CreaturePropCommand = class("CreaturePropCommand", pm.SimpleCommand)

function CreaturePropCommand:execute(note)
  local data = note.body
  if note.name == ServiceEvent.PlayerMapObjectData then
    local target = SceneCreatureProxy.FindCreature(data.guid)
    if target ~= nil then
      self:UpdateProp(target, data)
    end
  elseif note.name == ServiceEvent.NpcChangeHp then
    local target = SceneCreatureProxy.FindCreature(data.charid)
    if target ~= nil then
      self:UpdatePropHp(target, data)
    end
  end
end

function CreaturePropCommand:UpdateProp(target, data)
  if target.props == nil then
    target.props = Props.new(UserProxy.Instance.creatureProps, true)
  end
  target:SetProps(data.attrs)
  if data.attrs ~= nil and #data.attrs > 0 then
    GameFacade.Instance:sendNotification(SceneCreatureEvent.PropChange, target)
  end
end

function CreaturePropCommand:UpdatePropHp(target, data)
  if target.props == nil then
    return
  end
  if data.hp ~= nil then
    local oldHP = target.props:GetPropByName("Hp"):GetValue()
    target.props:GetPropByName("Hp"):SetValue(data.hp)
    GameFacade.Instance:sendNotification(SceneCreatureEvent.PropHpChange, target)
  end
end
