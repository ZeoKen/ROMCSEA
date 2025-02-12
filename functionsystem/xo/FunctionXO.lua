FunctionXO = class("FunctionXO")

function FunctionXO.Me()
  if nil == FunctionXO.me then
    FunctionXO.me = FunctionXO.new()
  end
  return FunctionXO.me
end

function FunctionXO:ctor()
end

function FunctionXO:QueryQuestion(npcid)
  helplog("QueryQuestion", npcid)
  self.queryNpcid = npcid
  ServiceSceneInterlocutionProxy.Instance:CallQuery(npcid)
end

function FunctionXO:QueryQuestionResult(result, npcid)
  npcid = npcid or self.queryNpcid
  self.queryNpcid = nil
  local npc = NSceneNpcProxy.Instance:Find(npcid)
  if npc then
    local viewdata = {viewname = "DialogView"}
    viewdata.npcinfo = npc
    if result == SceneInterlocution_pb.EQUERYSTATE_ANSWERED_RIGHT then
      viewdata.dialoglist = {
        ZhString.FunctionXO_AlreadyAnswerdTip
      }
    elseif result == SceneInterlocution_pb.EQUERYSTATE_ANSWERED_WRONG then
      viewdata.dialoglist = {
        ZhString.FunctionXO_AlreadyAnswerdFailedTip
      }
    end
    GameFacade.Instance:sendNotification(UIEvent.ShowUI, viewdata)
  end
end

function FunctionXO:NewInter(inter, npcid)
  helplog("FunctionXO NewInter")
  if not inter then
    return
  end
  FunctionSystem.WeakInterruptMyself(true)
  local viewdata = {
    npcid = npcid,
    guid = inter.guid,
    interid = inter.interid,
    questid = inter.paramid
  }
  GameFacade.Instance:sendNotification(UIEvent.JumpPanel, {
    view = PanelConfig.XOView,
    viewdata = viewdata
  })
end

function FunctionXO:Answer(npcid, guid, interid, questid, answer)
  if guid == MiniROProxy.QuestionGUID then
    redlog("FunctionXO:Answer ================== interid = " .. tostring(interid) .. ", answer = " .. answer)
    ServiceActMiniRoCmdProxy.Instance:CallActMiniRoEventFAQS(interid, answer)
  else
    ServiceSceneInterlocutionProxy.Instance:CallAnswer(npcid, guid, interid, questid, answer)
  end
end

function FunctionXO:AnswerResult(correct, npcid, source)
  if npcid then
    local npc = NSceneNpcProxy.Instance:Find(npcid)
    if npc then
      local sceneUI = npc:GetSceneUI()
      if sceneUI then
        if correct then
          sceneUI.roleTopUI:PlayEmojiById(32)
        else
          sceneUI.roleTopUI:PlayEmojiById(31)
        end
      end
      if not correct and source == ProtoCommon_pb.ESOURCE_QA then
        local viewdata = {viewname = "DialogView"}
        viewdata.npcinfo = npc
        viewdata.dialoglist = {
          ZhString.FunctionXO_AlreadyAnswerdFailedTip
        }
        GameFacade.Instance:sendNotification(UIEvent.ShowUI, viewdata)
      end
    end
  end
end

local Answer_LoverQuestion = function(npcInfo, optionId)
  helplog("Answer_LoverQuestion", optionId)
end

function FunctionXO:DoLoverQuestion(loverQuestionId)
  local config = Table_Valentine[loverQuestionId]
  if config then
    local viewdata = {viewname = "DialogView"}
    viewdata.dialoglist = {
      config.TitleDesc
    }
    local option = config.Option
    if 0 < #option then
      viewdata.addfunc = {}
      for i = 1, #option do
        local optCfg = option[i]
        if optCfg then
          local chooseFunc = {}
          chooseFunc.NameZh = optCfg[1]
          chooseFunc.eventParam = optCfg[2]
          chooseFunc.event = Answer_LoverQuestion
          chooseFunc.closeDialog = true
          chooseFunc.waitClose = 1
          table.insert(viewdata.addfunc, chooseFunc)
        end
      end
      viewdata.forceClickMenu = true
    end
    local nnpc = FunctionVisitNpc.Me():GetTarget()
    if nnpc == nil then
      nnpc = NSceneNpcProxy.Instance:FindNearestNpc(Game.Myself:GetPosition(), nearDis, function(npc)
      end)
    end
    viewdata.npcinfo = nnpc
    GameFacade.Instance:sendNotification(UIEvent.ShowUI, viewdata)
  end
end
