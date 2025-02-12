local ServiceSceneProxy = class("ServiceSceneProxy", ServiceProxy)
ServiceSceneProxy.Instance = nil
ServiceSceneProxy.NAME = "ServiceSceneProxy"

function ServiceSceneProxy:ctor(proxyName)
  if ServiceSceneProxy.Instance == nil then
    self.proxyName = proxyName or ServiceSceneProxy.NAME
    ServiceProxy.ctor(self, self.proxyName)
    self:Init()
    ServiceSceneProxy.Instance = self
  end
end

function ServiceSceneProxy:Init()
end

function ServiceSceneProxy:onRegister()
  self:Listen(5, 33, function(data)
    self:RecvUserActionNtf(data)
  end)
  self:Listen(5, 42, function(data)
    self:RecvGoToUserCmd(data)
  end)
end

function ServiceSceneProxy:CallReliveUserCmd(type)
  if NetConfig.PBC then
    local msgId = ProtoReqInfoList.ReliveUserCmd.id
    local msgParam = {}
    msgParam.type = type
    self:SendProto2(msgId, msgParam)
  else
    local msg = SceneUser_pb.ReliveUserCmd()
    msg.type = type
    self:SendProto(msg)
  end
end

function ServiceSceneProxy:RecvUserActionNtf(data)
  self:Notify(ServiceEvent.SceneUserActionNtf, data)
end

local GoToEffect = GameConfig.GoToEffect
local BWTransferSquareRange = 2500

function ServiceSceneProxy:RecvGoToUserCmd(data)
  if data.charid and data.charid == Game.Myself.data.id and Game.MapManager:GetMapID() == 149 then
    local squareRange = VectorUtility.DistanceXZ_Square(Game.Myself:GetPosition(), LuaVector3.New(data.pos.x / 1000, data.pos.y / 1000, data.pos.z / 1000))
    if squareRange > BWTransferSquareRange then
      FloatingPanel.Instance:HandlePlayBWMapTransferEffect()
      BigWorld.BigWorldManager.Instance:Transmit(Game.Myself:GetPosition(), function()
        FloatingPanel.Instance:HandlePlayBWMapTransferEffect()
      end)
    end
  end
  SceneCreatureProxy.ResetPos(data.charid, data.pos, data.isgomap)
  self:Notify(ServiceEvent.SceneGoToUserCmd, data)
  EventManager.Me():DispatchEvent(ServiceEvent.SceneGoToUserCmd, data)
  local creature = SceneCreatureProxy.FindCreature(data.charid)
  local pathEffectID = data.path_effect or 0
  local pathEffectConfig = GoToEffect[pathEffectID]
  if pathEffectConfig and creature then
    local currentPosition = creature:GetPosition()
    local posX, posY, posZ = creature.assetRole:GetEPPosition(pathEffectConfig.epID)
    local targetPos = LuaGeometry.GetTempVector3((data.pos.x or 0) / 1000, posY or 0, (data.pos.z or 0) / 1000)
    creature:PlayProjectileEffect(data.charid, pathEffectConfig.effectPath, currentPosition, pathEffectConfig.speed, targetPos, true)
  end
end

return ServiceSceneProxy
