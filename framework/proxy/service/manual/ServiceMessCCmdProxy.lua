autoImport("ServiceMessCCmdAutoProxy")
ServiceMessCCmdProxy = class("ServiceMessCCmdProxy", ServiceMessCCmdAutoProxy)
ServiceMessCCmdProxy.Instance = nil
ServiceMessCCmdProxy.NAME = "ServiceMessCCmdProxy"

function ServiceMessCCmdProxy:ctor(proxyName)
  if ServiceMessCCmdProxy.Instance == nil then
    self.proxyName = proxyName or ServiceMessCCmdProxy.NAME
    ServiceProxy.ctor(self, self.proxyName)
    self:Init()
    ServiceMessCCmdProxy.Instance = self
  end
end

function ServiceMessCCmdProxy:RecvChooseNewProfessionMessCCmd(data)
  ProfessionProxy.Instance:HandleChooseNewProfessionMess(data.bornprofession)
  self:Notify(ServiceEvent.MessCCmdChooseNewProfessionMessCCmd, data)
end

function ServiceMessCCmdProxy:RecvInviterReceiveConfessionMessCCmd(data)
  MiniGameProxy.Instance:RecvInviterReceiveConfessionMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdInviterReceiveConfessionMessCCmd, data)
end

function ServiceMessCCmdProxy:RecvFingerLoseLoveConfessionMessCCmd(data)
  MiniGameProxy.Instance:RecvFingerLoseLoveConfessionMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdFingerLoseLoveConfessionMessCCmd, data)
end

function ServiceMessCCmdProxy:RecvInviterResultLoveConfessionMessCCmd(data)
  MiniGameProxy.Instance:RecvInviterResultLoveConfessionMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdInviterResultLoveConfessionMessCCmd, data)
end

function ServiceMessCCmdProxy:RecvSyncMapStepForeverRewardInfo(data)
  WorldMapProxy.Instance:SetMapStepForeverRewardInfo(data)
  self:Notify(ServiceEvent.MessCCmdSyncMapStepForeverRewardInfo, data)
end

function ServiceMessCCmdProxy:RecvBalanceModeChooseMessCCmd(data)
  SkillProxy.Instance:SetBalanceModeChooseMess(data)
  self:Notify(ServiceEvent.MessCCmdBalanceModeChooseMessCCmd, data)
end

function ServiceMessCCmdProxy:RecvSetPippiStateMessCCmd(data)
  PetProxy.Instance:RecvSetPippiStateMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdSetPippiStateMessCCmd, data)
end

function ServiceMessCCmdProxy:RecvPurifyProductsMaterialsMessCCmd(data)
  CraftingPotProxy.Instance:InitCall(false)
  CraftingPotProxy.Instance:RecvPurifyProductsMaterialsMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdPurifyProductsMaterialsMessCCmd, data)
end

function ServiceMessCCmdProxy:RecvPurifyProductsRefineMessCCmd(data)
  CraftingPotProxy.Instance:RecvPurifyProductsRefineMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdPurifyProductsRefineMessCCmd, data)
end

function ServiceMessCCmdProxy:RecvSyncDestinyGraphMessCCmd(data)
  AstralProxy.Instance:SyncDestinyGraphInfo(data.curseason, data.graphinfos)
  self:Notify(ServiceEvent.MessCCmdSyncDestinyGraphMessCCmd, data)
end

function ServiceMessCCmdProxy:RecvAstralSyncSeasonInfoMessCCmd(data)
  redlog("ServiceMessCCmdProxy:RecvAstralSyncSeasonInfoMessCCmd", data.season)
  AstralProxy.Instance:SyncAstralSeason(data.season)
  self:Notify(ServiceEvent.MessCCmdAstralSyncSeasonInfoMessCCmd, data)
end
