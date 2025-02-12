local ReconnInitCommand = class("ReconnInitCommand", pm.SimpleCommand)

function ReconnInitCommand:execute(note)
  self:Init()
end

function ReconnInitCommand:Init()
  if Game.Myself then
    Game.Myself:Client_ClearFollower()
    Game.Myself:Server_SetHandInHand(Game.Myself:Client_GetFollowLeaderID(), false)
  end
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_WALLET, true)
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_MAIN, true)
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_EQUIP, true)
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_FASHIONEQUIP, true)
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_STORE, true)
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_PERSONAL_STORE, true)
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_TEMP_MAIN, true)
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_QUEST or 10, true)
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_FOOD or 11, true)
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_PET or 12, true)
  GemProxy.QueryPackage(true)
  PersonalArtifactProxy.QueryPackage(true)
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_SHADOWEQUIP, true)
  ServiceItemProxy.Instance:CallPackageItem(SceneItem_pb.EPACKTYPE_MEMORY, true)
  redlog("---------------------ReconnInitCommand 请求背包")
  GameFacade.Instance:sendNotification(ServiceEvent.ReloadDatas)
  ServiceNUserProxy.Instance:CallQueryShopGotItem()
  ServiceNUserProxy.Instance:CallNewDressing()
  FunctionGuide.Me():stopGuide()
  FunctionCheck.Me():Reset()
  FloatingPanel.Instance:CloseMaintenanceMsg()
  ComboCtl.Instance:Clear()
  QuestProxy.Instance:CleanAllQuest()
  PvpProxy.Instance:Reconnect()
  PlotAudioProxy.Instance:ResetAll()
  DungeonProxy.Instance:Reconnect()
  Game.PlotStoryManager:Clear()
  Game.PlotStoryManager:ClearMyTempEffect()
  FunctionPve.QueryPvePassInfo()
  TeamProxy.Instance:Reconnect()
end

return ReconnInitCommand
