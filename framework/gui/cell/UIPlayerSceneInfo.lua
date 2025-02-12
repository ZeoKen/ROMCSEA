local BaseCell = autoImport("BaseCell")
UIPlayerSceneInfo = class("UIPlayerSceneInfo", BaseCell)
UIPlayerSceneInfo.Pos = Vector3(-293, -215, 0)
autoImport("WrapCellHelper")
autoImport("TitleCombineItemCell")

function UIPlayerSceneInfo:ctor(parent, panelId)
  local obj = self:LoadPreferb("cell/UIPlayerSceneInfo", parent)
  self.gameObject = obj
  self.gameObject.transform.localPosition = LuaGeometry.GetTempVector3(-293, -215, 0)
  self.panelId = panelId
  self:Init()
end

function UIPlayerSceneInfo:Init()
  local namelab = self:FindComponent("Name", UILabel)
  namelab.text = Game.Myself.data:GetName()
  self.hpSlider = self:FindComponent("Hp", UISlider)
  self.mpSlider = self:FindComponent("Mp", UISlider)
  self.id = self:FindComponent("ID", UILabel)
  self.titleFilter = self:FindGO("Title")
  self.curTitleLab = self:FindGO("TitleName", self.titleFilter):GetComponent(UILabel)
  self.titlePropBtn = self:FindGO("TitlePropBtn")
  self.arrowRot = self:FindComponent("TitleIcon", TweenRotation)
  self.titleRoot = self:FindGO("TitleList")
  local svObj = self:FindGO("TitleSc", self.titleRoot)
  self.titleScrollV = svObj:GetComponent(UIScrollView)
  self.itemRoot = self:FindGO("Container")
  self.copyIdBtn = self:FindGO("CopyIDBtn")
  self.titlePropObj = self:FindGO("TitlePropInfo")
  self.cancelTitle = self:FindComponent("cancelTitleBtn", UILabel)
  self.cancelTitle.text = ZhString.AchievementTitle_NoTitle
  self:ShowId()
  self:AddEvn()
  self:ResetCellData()
  self.destroyed = false
end

function UIPlayerSceneInfo:ResetCellData()
  local allTitle = TitleProxy.Instance:GetTitle()
  self:ShowTitleList(allTitle)
end

function UIPlayerSceneInfo:TitleCellClick(cellCtl)
  local data = cellCtl and cellCtl.data
  local go = cellCtl and cellCtl.titleName
  local newChooseID = data and data.id or 0
  if self.chooseId ~= newChooseID then
    self.chooseId = newChooseID
    self:ShowTitleTip(data, go)
  else
    self.chooseId = 0
    TipManager.Instance:HideTitleTip()
  end
  self:_refreshChoose()
end

function UIPlayerSceneInfo:_refreshChoose()
  local cells = self.itemWrapHelper:GetCellCtls()
  for i = 1, #cells do
    local cell = cells[i]
    for j = 1, #cell.childrenObjs do
      local child = cell.childrenObjs[j]
      child:SetChoose(self.chooseId)
    end
  end
end

function UIPlayerSceneInfo:ReUniteCellData(datas, perRowNum)
  local newData = {}
  if datas ~= nil and 0 < #datas then
    for i = 1, #datas do
      local i1 = math.floor((i - 1) / perRowNum) + 1
      local i2 = math.floor((i - 1) % perRowNum) + 1
      newData[i1] = newData[i1] or {}
      if datas[i] == nil then
        newData[i1][i2] = nil
      else
        newData[i1][i2] = datas[i]
      end
    end
  end
  return newData
end

function UIPlayerSceneInfo:ShowTitleList(data)
  local newData = self:ReUniteCellData(data, 1)
  if self.itemWrapHelper == nil then
    local wrapConfig = {
      wrapObj = self.itemRoot,
      pfbNum = 8,
      cellName = "TitleCombineItemCell",
      control = TitleCombineItemCell,
      dir = 1
    }
    self.itemWrapHelper = WrapCellHelper.new(wrapConfig)
    self.itemWrapHelper:AddEventListener(MouseEvent.MouseClick, self.TitleCellClick, self)
  end
  self.itemWrapHelper:UpdateInfo(newData)
end

function UIPlayerSceneInfo:ShowTitleTip(data, stick)
  local callback = function()
    if not self.destroyed then
      self.chooseId = 0
      self:_refreshChoose()
    end
  end
  local sdata = {
    itemdata = data,
    ignoreBounds = ignoreBounds,
    callback = callback
  }
  local tip = TipManager.Instance:ShowTitleTip(sdata, stick, NGUIUtil.AnchorSide.Right, {215, 0})
  tip:AddIgnoreBounds(self.titleRoot)
end

function UIPlayerSceneInfo:AddEvn()
  self:AddClickEvent(self.titleFilter, function()
    self:ShowTitle()
  end)
  self:AddClickEvent(self.titlePropBtn, function()
    self:ShowPropInfo()
  end)
  self:AddClickEvent(self.cancelTitle.gameObject, function()
    self:CancelTitle()
  end)
  self:AddClickEvent(self.copyIdBtn, function()
    local result = ApplicationInfo.CopyToSystemClipboard(Game.Myself.data.id)
    if result then
      MsgManager.ShowMsgByID(40200)
    end
  end)
  EventManager.Me():AddEventListener(ServiceEvent.UserEventChangeTitle, self.HandleChangeTitle, self)
end

function UIPlayerSceneInfo:HandleChangeTitle(data)
  self.chooseId = 0
  self:_refreshChoose()
  self:Hide(self.titleRoot)
  self.arrowRot:PlayForward()
  self:SetCurAchTitle()
  TipManager.Instance:HideTitleTip()
  self:ResetCellData()
end

function UIPlayerSceneInfo:ShowTitle()
  local activeState = self.titleRoot.activeSelf
  if activeState then
    self:Hide(self.titleRoot)
    self.arrowRot:PlayForward()
  else
    self:Show(self.titleRoot)
    self.arrowRot:PlayReverse()
  end
end

local titleType = UserEvent_pb.ETITLE_TYPE_ACHIEVEMENT

function UIPlayerSceneInfo:CancelTitle()
  local title = TitleProxy.Instance:GetCurAchievementTitle()
  if not title then
    return
  end
  if "" ~= title then
    TitleProxy.Instance:ChangeTitle(titleType, 0)
  end
  self:ShowTitle()
  TipManager.Instance:HideTitleTip()
end

function UIPlayerSceneInfo:ShowPropInfo()
  local pointData = TitleProxy.Instance:GetAllTitleProp()
  TipManager.Instance:ShowTitlePropTip(pointData, nil, nil, {-100, 0})
end

function UIPlayerSceneInfo:ShowId()
  if self.panelId == 1 then
    self:Show(self.id.gameObject)
  else
    self:Hide(self.id.gameObject)
  end
end

function UIPlayerSceneInfo:OnEnter()
  TimeTickManager.Me():CreateTick(0, 100, function(self, deltatime)
    if Game.GameObjectUtil:ObjectIsNULL(self.gameObject) then
      TimeTickManager.Me():ClearTick(self, 1)
    else
      self:SetRoleHpSp()
    end
  end, self, 1)
  self:SetCurAchTitle()
end

function UIPlayerSceneInfo:SetCurAchTitle()
  local title = TitleProxy.Instance:GetCurAchievementTitle()
  if nil == title then
  end
  self.curTitleLab.text = title or ZhString.Charactor_NoTitleTip
end

function UIPlayerSceneInfo:SetRoleHpSp()
  local props = Game.Myself.data.props
  local hp = props:GetPropByName("Hp"):GetValue() or 0
  local maxhp = math.max(props:GetPropByName("MaxHp"):GetValue(), 1)
  self.hpSlider.value = hp / maxhp
  local sp = props:GetPropByName("Sp"):GetValue() or 0
  local maxsp = math.max(props:GetPropByName("MaxSp"):GetValue(), 1)
  self.mpSlider.value = sp / maxsp
  local data = Game.Myself.data
  self.id.text = string.format(ZhString.UIPlayerSceneInfo_IDTip, data.id)
end

function UIPlayerSceneInfo:OnExit()
  TimeTickManager.Me():ClearTick(self, 1)
  GameObject.DestroyImmediate(self.gameObject)
  self.destroyed = true
  EventManager.Me():RemoveEventListener(ServiceEvent.UserEventChangeTitle, self.HandleChangeTitle, self)
  self.itemWrapHelper:Destroy()
end

function UIPlayerSceneInfo:HideTitle()
  local activeState = self.titleRoot.activeSelf
  if activeState then
    self:Hide(self.titleRoot)
    self.arrowRot:PlayForward()
  end
end
