ServiceMessCCmdAutoProxy = class("ServiceMessCCmdAutoProxy", ServiceProxy)
ServiceMessCCmdAutoProxy.Instance = nil
ServiceMessCCmdAutoProxy.NAME = "ServiceMessCCmdAutoProxy"

function ServiceMessCCmdAutoProxy:ctor(proxyName)
  if ServiceMessCCmdAutoProxy.Instance == nil then
    self.proxyName = proxyName or ServiceMessCCmdAutoProxy.NAME
    ServiceProxy.ctor(self, self.proxyName)
    self:Init()
    ServiceMessCCmdAutoProxy.Instance = self
  end
end

function ServiceMessCCmdAutoProxy:Init()
end

function ServiceMessCCmdAutoProxy:onRegister()
  self:Listen(83, 1, function(data)
    self:RecvChooseNewProfessionMessCCmd(data)
  end)
  self:Listen(83, 2, function(data)
    self:RecvInviterSendLoveConfessionMessCCmd(data)
  end)
  self:Listen(83, 3, function(data)
    self:RecvInviteeReceiveLoveConfessionMessCCmd(data)
  end)
  self:Listen(83, 4, function(data)
    self:RecvInviteeProcessLoveConfessionMessCCmd(data)
  end)
  self:Listen(83, 5, function(data)
    self:RecvInviterReceiveConfessionMessCCmd(data)
  end)
  self:Listen(83, 6, function(data)
    self:RecvFingerGuessLoveConfessionMessCCmd(data)
  end)
  self:Listen(83, 7, function(data)
    self:RecvFingerLoseLoveConfessionMessCCmd(data)
  end)
  self:Listen(83, 8, function(data)
    self:RecvInviterResultLoveConfessionMessCCmd(data)
  end)
  self:Listen(83, 9, function(data)
    self:RecvSyncMapStepForeverRewardInfo(data)
  end)
  self:Listen(83, 10, function(data)
    self:RecvBalanceModeChooseMessCCmd(data)
  end)
  self:Listen(83, 11, function(data)
    self:RecvSetPippiStateMessCCmd(data)
  end)
  self:Listen(83, 12, function(data)
    self:RecvSyncDestinyGraphMessCCmd(data)
  end)
  self:Listen(83, 13, function(data)
    self:RecvLightenDestinyGraphMessCCmd(data)
  end)
  self:Listen(83, 14, function(data)
    self:RecvAstralRewardMessCCmd(data)
  end)
  self:Listen(83, 15, function(data)
    self:RecvPurifyProductsMaterialsMessCCmd(data)
  end)
  self:Listen(83, 16, function(data)
    self:RecvPurifyProductsRefineMessCCmd(data)
  end)
  self:Listen(83, 17, function(data)
    self:RecvAstralSyncSeasonInfoMessCCmd(data)
  end)
end

function ServiceMessCCmdAutoProxy:CallChooseNewProfessionMessCCmd(bornprofession, chooseprofession)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.ChooseNewProfessionMessCCmd()
    if bornprofession ~= nil then
      msg.bornprofession = bornprofession
    end
    if chooseprofession ~= nil then
      msg.chooseprofession = chooseprofession
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.ChooseNewProfessionMessCCmd.id
    local msgParam = {}
    if bornprofession ~= nil then
      msgParam.bornprofession = bornprofession
    end
    if chooseprofession ~= nil then
      msgParam.chooseprofession = chooseprofession
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallInviterSendLoveConfessionMessCCmd(invitee, invitername)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.InviterSendLoveConfessionMessCCmd()
    if invitee ~= nil then
      msg.invitee = invitee
    end
    if invitername ~= nil then
      msg.invitername = invitername
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.InviterSendLoveConfessionMessCCmd.id
    local msgParam = {}
    if invitee ~= nil then
      msgParam.invitee = invitee
    end
    if invitername ~= nil then
      msgParam.invitername = invitername
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallInviteeReceiveLoveConfessionMessCCmd(invitername, inviter)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.InviteeReceiveLoveConfessionMessCCmd()
    if invitername ~= nil then
      msg.invitername = invitername
    end
    if inviter ~= nil then
      msg.inviter = inviter
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.InviteeReceiveLoveConfessionMessCCmd.id
    local msgParam = {}
    if invitername ~= nil then
      msgParam.invitername = invitername
    end
    if inviter ~= nil then
      msgParam.inviter = inviter
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallInviteeProcessLoveConfessionMessCCmd(accept, inviter)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.InviteeProcessLoveConfessionMessCCmd()
    if accept ~= nil then
      msg.accept = accept
    end
    if inviter ~= nil then
      msg.inviter = inviter
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.InviteeProcessLoveConfessionMessCCmd.id
    local msgParam = {}
    if accept ~= nil then
      msgParam.accept = accept
    end
    if inviter ~= nil then
      msgParam.inviter = inviter
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallInviterReceiveConfessionMessCCmd(accept, inviter)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.InviterReceiveConfessionMessCCmd()
    if accept ~= nil then
      msg.accept = accept
    end
    if inviter ~= nil then
      msg.inviter = inviter
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.InviterReceiveConfessionMessCCmd.id
    local msgParam = {}
    if accept ~= nil then
      msgParam.accept = accept
    end
    if inviter ~= nil then
      msgParam.inviter = inviter
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallFingerGuessLoveConfessionMessCCmd(item, inviter)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.FingerGuessLoveConfessionMessCCmd()
    if item ~= nil then
      msg.item = item
    end
    if inviter ~= nil then
      msg.inviter = inviter
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.FingerGuessLoveConfessionMessCCmd.id
    local msgParam = {}
    if item ~= nil then
      msgParam.item = item
    end
    if inviter ~= nil then
      msgParam.inviter = inviter
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallFingerLoseLoveConfessionMessCCmd(inviter, winnerfinger, loserfinger, winner)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.FingerLoseLoveConfessionMessCCmd()
    if inviter ~= nil then
      msg.inviter = inviter
    end
    if winnerfinger ~= nil then
      msg.winnerfinger = winnerfinger
    end
    if loserfinger ~= nil then
      msg.loserfinger = loserfinger
    end
    if winner ~= nil then
      msg.winner = winner
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.FingerLoseLoveConfessionMessCCmd.id
    local msgParam = {}
    if inviter ~= nil then
      msgParam.inviter = inviter
    end
    if winnerfinger ~= nil then
      msgParam.winnerfinger = winnerfinger
    end
    if loserfinger ~= nil then
      msgParam.loserfinger = loserfinger
    end
    if winner ~= nil then
      msgParam.winner = winner
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallInviterResultLoveConfessionMessCCmd(success, invitee)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.InviterResultLoveConfessionMessCCmd()
    if success ~= nil then
      msg.success = success
    end
    if invitee ~= nil then
      msg.invitee = invitee
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.InviterResultLoveConfessionMessCCmd.id
    local msgParam = {}
    if success ~= nil then
      msgParam.success = success
    end
    if invitee ~= nil then
      msgParam.invitee = invitee
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallSyncMapStepForeverRewardInfo(infos)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.SyncMapStepForeverRewardInfo()
    if infos ~= nil then
      if msg == nil then
        msg = {}
      end
      if msg.infos == nil then
        msg.infos = {}
      end
      for i = 1, #infos do
        table.insert(msg.infos, infos[i])
      end
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.SyncMapStepForeverRewardInfo.id
    local msgParam = {}
    if infos ~= nil then
      if msgParam == nil then
        msgParam = {}
      end
      if msgParam.infos == nil then
        msgParam.infos = {}
      end
      for i = 1, #infos do
        table.insert(msgParam.infos, infos[i])
      end
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallBalanceModeChooseMessCCmd(extraction_atk_id, extraction_def_id, personal_artifact_id)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.BalanceModeChooseMessCCmd()
    if extraction_atk_id ~= nil then
      msg.extraction_atk_id = extraction_atk_id
    end
    if extraction_def_id ~= nil then
      msg.extraction_def_id = extraction_def_id
    end
    if personal_artifact_id ~= nil then
      msg.personal_artifact_id = personal_artifact_id
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.BalanceModeChooseMessCCmd.id
    local msgParam = {}
    if extraction_atk_id ~= nil then
      msgParam.extraction_atk_id = extraction_atk_id
    end
    if extraction_def_id ~= nil then
      msgParam.extraction_def_id = extraction_def_id
    end
    if personal_artifact_id ~= nil then
      msgParam.personal_artifact_id = personal_artifact_id
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallSetPippiStateMessCCmd(summon, time, state)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.SetPippiStateMessCCmd()
    if summon ~= nil then
      msg.summon = summon
    end
    if time ~= nil then
      msg.time = time
    end
    if state ~= nil then
      msg.state = state
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.SetPippiStateMessCCmd.id
    local msgParam = {}
    if summon ~= nil then
      msgParam.summon = summon
    end
    if time ~= nil then
      msgParam.time = time
    end
    if state ~= nil then
      msgParam.state = state
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallSyncDestinyGraphMessCCmd(graphinfos, curseason)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.SyncDestinyGraphMessCCmd()
    if graphinfos ~= nil then
      if msg == nil then
        msg = {}
      end
      if msg.graphinfos == nil then
        msg.graphinfos = {}
      end
      for i = 1, #graphinfos do
        table.insert(msg.graphinfos, graphinfos[i])
      end
    end
    if curseason ~= nil then
      msg.curseason = curseason
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.SyncDestinyGraphMessCCmd.id
    local msgParam = {}
    if graphinfos ~= nil then
      if msgParam == nil then
        msgParam = {}
      end
      if msgParam.graphinfos == nil then
        msgParam.graphinfos = {}
      end
      for i = 1, #graphinfos do
        table.insert(msgParam.graphinfos, graphinfos[i])
      end
    end
    if curseason ~= nil then
      msgParam.curseason = curseason
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallLightenDestinyGraphMessCCmd(season, point)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.LightenDestinyGraphMessCCmd()
    if season ~= nil then
      msg.season = season
    end
    if point ~= nil then
      msg.point = point
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.LightenDestinyGraphMessCCmd.id
    local msgParam = {}
    if season ~= nil then
      msgParam.season = season
    end
    if point ~= nil then
      msgParam.point = point
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallAstralRewardMessCCmd(season, pass_num)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.AstralRewardMessCCmd()
    if season ~= nil then
      msg.season = season
    end
    if pass_num ~= nil then
      msg.pass_num = pass_num
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.AstralRewardMessCCmd.id
    local msgParam = {}
    if season ~= nil then
      msgParam.season = season
    end
    if pass_num ~= nil then
      msgParam.pass_num = pass_num
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallPurifyProductsMaterialsMessCCmd(materials)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.PurifyProductsMaterialsMessCCmd()
    if materials ~= nil then
      if msg == nil then
        msg = {}
      end
      if msg.materials == nil then
        msg.materials = {}
      end
      for i = 1, #materials do
        table.insert(msg.materials, materials[i])
      end
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.PurifyProductsMaterialsMessCCmd.id
    local msgParam = {}
    if materials ~= nil then
      if msgParam == nil then
        msgParam = {}
      end
      if msgParam.materials == nil then
        msgParam.materials = {}
      end
      for i = 1, #materials do
        table.insert(msgParam.materials, materials[i])
      end
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallPurifyProductsRefineMessCCmd(productid, times)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.PurifyProductsRefineMessCCmd()
    if productid ~= nil then
      msg.productid = productid
    end
    if times ~= nil then
      msg.times = times
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.PurifyProductsRefineMessCCmd.id
    local msgParam = {}
    if productid ~= nil then
      msgParam.productid = productid
    end
    if times ~= nil then
      msgParam.times = times
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:CallAstralSyncSeasonInfoMessCCmd(season)
  if not NetConfig.PBC then
    local msg = MessCCmd_pb.AstralSyncSeasonInfoMessCCmd()
    if season ~= nil then
      msg.season = season
    end
    self:SendProto(msg)
  else
    local msgId = ProtoReqInfoList.AstralSyncSeasonInfoMessCCmd.id
    local msgParam = {}
    if season ~= nil then
      msgParam.season = season
    end
    self:SendProto2(msgId, msgParam)
  end
end

function ServiceMessCCmdAutoProxy:RecvChooseNewProfessionMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdChooseNewProfessionMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvInviterSendLoveConfessionMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdInviterSendLoveConfessionMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvInviteeReceiveLoveConfessionMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdInviteeReceiveLoveConfessionMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvInviteeProcessLoveConfessionMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdInviteeProcessLoveConfessionMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvInviterReceiveConfessionMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdInviterReceiveConfessionMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvFingerGuessLoveConfessionMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdFingerGuessLoveConfessionMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvFingerLoseLoveConfessionMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdFingerLoseLoveConfessionMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvInviterResultLoveConfessionMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdInviterResultLoveConfessionMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvSyncMapStepForeverRewardInfo(data)
  self:Notify(ServiceEvent.MessCCmdSyncMapStepForeverRewardInfo, data)
end

function ServiceMessCCmdAutoProxy:RecvBalanceModeChooseMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdBalanceModeChooseMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvSetPippiStateMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdSetPippiStateMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvSyncDestinyGraphMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdSyncDestinyGraphMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvLightenDestinyGraphMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdLightenDestinyGraphMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvAstralRewardMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdAstralRewardMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvPurifyProductsMaterialsMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdPurifyProductsMaterialsMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvPurifyProductsRefineMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdPurifyProductsRefineMessCCmd, data)
end

function ServiceMessCCmdAutoProxy:RecvAstralSyncSeasonInfoMessCCmd(data)
  self:Notify(ServiceEvent.MessCCmdAstralSyncSeasonInfoMessCCmd, data)
end

ServiceEvent = _G.ServiceEvent or {}
ServiceEvent.MessCCmdChooseNewProfessionMessCCmd = "ServiceEvent_MessCCmdChooseNewProfessionMessCCmd"
ServiceEvent.MessCCmdInviterSendLoveConfessionMessCCmd = "ServiceEvent_MessCCmdInviterSendLoveConfessionMessCCmd"
ServiceEvent.MessCCmdInviteeReceiveLoveConfessionMessCCmd = "ServiceEvent_MessCCmdInviteeReceiveLoveConfessionMessCCmd"
ServiceEvent.MessCCmdInviteeProcessLoveConfessionMessCCmd = "ServiceEvent_MessCCmdInviteeProcessLoveConfessionMessCCmd"
ServiceEvent.MessCCmdInviterReceiveConfessionMessCCmd = "ServiceEvent_MessCCmdInviterReceiveConfessionMessCCmd"
ServiceEvent.MessCCmdFingerGuessLoveConfessionMessCCmd = "ServiceEvent_MessCCmdFingerGuessLoveConfessionMessCCmd"
ServiceEvent.MessCCmdFingerLoseLoveConfessionMessCCmd = "ServiceEvent_MessCCmdFingerLoseLoveConfessionMessCCmd"
ServiceEvent.MessCCmdInviterResultLoveConfessionMessCCmd = "ServiceEvent_MessCCmdInviterResultLoveConfessionMessCCmd"
ServiceEvent.MessCCmdSyncMapStepForeverRewardInfo = "ServiceEvent_MessCCmdSyncMapStepForeverRewardInfo"
ServiceEvent.MessCCmdBalanceModeChooseMessCCmd = "ServiceEvent_MessCCmdBalanceModeChooseMessCCmd"
ServiceEvent.MessCCmdSetPippiStateMessCCmd = "ServiceEvent_MessCCmdSetPippiStateMessCCmd"
ServiceEvent.MessCCmdSyncDestinyGraphMessCCmd = "ServiceEvent_MessCCmdSyncDestinyGraphMessCCmd"
ServiceEvent.MessCCmdLightenDestinyGraphMessCCmd = "ServiceEvent_MessCCmdLightenDestinyGraphMessCCmd"
ServiceEvent.MessCCmdAstralRewardMessCCmd = "ServiceEvent_MessCCmdAstralRewardMessCCmd"
ServiceEvent.MessCCmdPurifyProductsMaterialsMessCCmd = "ServiceEvent_MessCCmdPurifyProductsMaterialsMessCCmd"
ServiceEvent.MessCCmdPurifyProductsRefineMessCCmd = "ServiceEvent_MessCCmdPurifyProductsRefineMessCCmd"
ServiceEvent.MessCCmdAstralSyncSeasonInfoMessCCmd = "ServiceEvent_MessCCmdAstralSyncSeasonInfoMessCCmd"
