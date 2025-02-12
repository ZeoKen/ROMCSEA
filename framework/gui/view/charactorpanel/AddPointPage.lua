AddPointPage = class("AddPointPage", SubView)
autoImport("AttributePointModifyCell")
AddPointPage.times = {
  "STRPOINT",
  "AGIPOINT",
  "VITPOINT",
  "INTPOINT",
  "DEXPOINT",
  "LUKPOINT"
}
AddPointPage.addPointAction = "AddPointPage_addPointAction"
local ResetPointConig = GameConfig.ResetSkill[1]
local hideType = {hideClickSound = true}

function AddPointPage:Init()
  self.leftPoint = {}
  self:initView()
  self:initData()
  self:UpdateProps()
  self:addViewEventListener()
  self:AddListenerEvts()
end

function AddPointPage:initData()
  self.leftPoint = {}
  self.leftPoint.currentLeftPoint = 0
  self.leftPoint.originLeftPoint = 0
end

function AddPointPage:initView()
  local centerGrid = self:FindChild("addPointPageCenterRegion"):GetComponent(UIGrid)
  self.centerGridList = UIGridListCtrl.new(centerGrid, AttributePointModifyCell, "AttributePointModifyCell")
  self.leftPointLabel = self:FindGO("leftPointLabel"):GetComponent(UILabel)
  self.resetBtn = self:FindGO("ResetBtn")
  self:AddClickEvent(self.resetBtn, function()
    self:DoResetSkill()
  end)
  self.solutionConfirmBtn = self:FindGO("solutionConfirmBtn")
  self.disableConfirm = self:FindGO("disableConfirm")
  self.addPointSolutionBtn = self:FindGO("addPointSolutionBtn")
  self:AddOrRemoveGuideId(self.solutionConfirmBtn.gameObject, 7)
  self:AddOrRemoveGuideId(self.addPointSolutionBtn.gameObject, 462)
  self:disableConfirmMt(false)
end

function AddPointPage:DoResetSkill()
  local totalUsed = 0
  for i = 1, #GameConfig.ClassInitialAttr do
    totalUsed = totalUsed + Game.Myself.data.userdata:Get(AddPointPage.times[i]) or 0
  end
  if totalUsed <= 0 then
    MsgManager.ShowMsgByID(43106)
    return
  end
  local itemData = BagProxy.Instance:GetItemByStaticID(ResetPointConig.ItemID)
  if itemData then
    MsgManager.ConfirmMsgByID(43104, function()
      ServiceSkillProxy.Instance:CallResetSkill(SceneSkill_pb.ERESETSKILLTYPE_ATTR, SceneSkill_pb.ERESETSKILLCASTTYPE_ITEM)
      return
    end, nil, nil)
  else
    local zeny = MyselfProxy.Instance:GetROB()
    if zeny >= ResetPointConig.MoneyCount then
      local data = Table_Sysmsg[43105]
      local text = data and data.Text or ""
      local str = string.format(text, ResetPointConig.MoneyCount)
      UIUtil.PopUpConfirmYesNoView("", str, function()
        ServiceSkillProxy.Instance:CallResetSkill(SceneSkill_pb.ERESETSKILLTYPE_ATTR, SceneSkill_pb.ERESETSKILLCASTTYPE_MONEY)
      end, nil, nil, data.button, data.buttonF)
    else
      MsgManager.ShowMsgByID(43102)
    end
  end
end

function AddPointPage:disableConfirmMt(enable)
  local isDead = Game.Myself:IsDead()
  if isDead then
    enable = false
  end
  if enable then
    self:Show(self.solutionConfirmBtn)
    self:Hide(self.disableConfirm)
  else
    self:Hide(self.solutionConfirmBtn)
    self:Show(self.disableConfirm)
  end
end

function AddPointPage:AddListenerEvts()
  self:AddListenEvt(MyselfEvent.MyPropChange, self.UpdateMyPropData)
  self:AddListenEvt(ServiceEvent.NUserAddAttrPoint, self.resetAttrPointDatas)
end

function AddPointPage:selectAddPointSolution(data)
  if not data then
    return
  end
  local cells = self.centerGridList:GetCells()
  local cellList = {}
  for i = 1, #cells do
    local single = cells[i]
    single:resetTimeOfAdd()
    cellList[single.data.prop.propVO.name] = single
  end
  local baseLv = Game.Myself.data.userdata:Get(UDEnum.ROLELEVEL) or -1
  local pointTbData = Table_AddPoint[baseLv]
  if not pointTbData then
    printRed("can not find data in table:AddPoint by baseLv:" .. baseLv)
    return
  end
  pointTbData = pointTbData["AddPointSolution_" .. data.id]
  if not pointTbData then
    printRed("can not find data in addsolution in table AddPoint by solutionId:" .. data.id)
    return
  end
  if data then
    local goOn = 0
    local count = 0
    while goOn < 6 do
      goOn = 0
      for i = 1, #data.AddPoint do
        local single = data.AddPoint[i]
        local cell = cellList[single.key]
        if cell.timeOfAdd + cell.originTimeOfAdd < pointTbData[single.key] then
          goOn = cell:addPoint(single.value) + goOn
        else
          goOn = goOn + 1
        end
      end
    end
  else
    printRed("error solutionId!!!")
  end
  for i = 1, #cells do
    local single = cells[i]
    single:updateLeftPoint()
  end
  self:updateTempData(true)
end

function AddPointPage:addViewEventListener()
  self:AddClickEvent(self.solutionConfirmBtn, function()
    local cells = self.centerGridList:GetCells()
    local changePoint = 0
    local mapData = {}
    for i = 1, #cells do
      local single = cells[i]
      changePoint = changePoint + single.timeOfAdd
      mapData[single:GetAttrName()] = single.timeOfAdd
    end
    if changePoint == 0 then
      MsgManager.ShowMsgByIDTable(20)
      return
    end
    self:PlayUISound(AudioMap.UI.AbilityAdd)
    ServiceNUserProxy.Instance:CallAddAttrPoint(SceneUser2_pb.POINTTYPE_ADD, mapData.Str, mapData.Int, mapData.Agi, mapData.Dex, mapData.Vit, mapData.Luk)
  end, hideType)
  self.centerGridList:AddEventListener(MouseEvent.MouseClick, self.updateTempData, self)
  self:AddButtonEvent("addPointSolutionBtn", function()
    GameFacade.Instance:sendNotification(XDEUIEvent.CloseCharTitle)
  end)
end

function AddPointPage:getPlayerData()
  local datas = {}
  local props
  for i = 1, #GameConfig.ClassInitialAttr do
    local single = GameConfig.ClassInitialAttr[i]
    local prop = Game.Myself.data.props:GetPropByName(single)
    local extraP = MyselfProxy.Instance.extraProps:GetPropByName(single)
    local data = {}
    data.prop = prop
    data.extraP = extraP
    data.timeOfAdd = Game.Myself.data.userdata:Get(AddPointPage.times[i]) or 0
    data.leftPoint = self.leftPoint
    table.insert(datas, data)
  end
  return datas
end

function AddPointPage:UpdateProps()
  local currentProps = self:getPlayerData()
  local isResetData = false
  local leftPt = Game.Myself.data.userdata:Get(UDEnum.TOTALPOINT) or 0
  local diff = leftPt - self.leftPoint.originLeftPoint
  if diff ~= 0 and leftPt ~= self.leftPoint.currentLeftPoint then
    isResetData = true
  end
  if isResetData then
    self.leftPoint.currentLeftPoint = self.leftPoint.currentLeftPoint + diff
  end
  self.centerGridList:ResetDatas(currentProps)
  self.leftPoint.originLeftPoint = leftPt
  if 0 > self.leftPoint.currentLeftPoint then
    self.leftPointLabel.text = 0
  else
    self.leftPointLabel.text = self.leftPoint.currentLeftPoint
  end
end

function AddPointPage:updateTempData(fromSolution)
  local cells = self.centerGridList:GetCells()
  local timeOfAdd = 0
  local addCoundMap = {}
  for i = 1, #cells do
    local single = cells[i]
    timeOfAdd = timeOfAdd + single.timeOfAdd
    local countData = {}
    countData.totalCount = single.originTimeOfAdd + single.timeOfAdd
    countData.addCount = single.timeOfAdd
    addCoundMap[single:GetAttrName()] = countData
    single:updateLeftPoint()
  end
  local notifyData = {}
  notifyData.addCoundMap = nil
  notifyData.from = fromSolution
  if 0 < timeOfAdd then
    self:disableConfirmMt(true)
    notifyData.addCoundMap = addCoundMap
  else
    self:disableConfirmMt(false)
  end
  self:PassEvent(AddPointPage.addPointAction, notifyData)
  if 0 > self.leftPoint.currentLeftPoint then
    self.leftPointLabel.text = 0
  else
    self.leftPointLabel.text = self.leftPoint.currentLeftPoint
  end
end

function AddPointPage:UpdateMyPropData(note)
  self:UpdateProps()
end

function AddPointPage:resetAttrPointDatas()
  local cells = self.centerGridList:GetCells()
  for i = 1, #cells do
    local single = cells[i]
    single:clearTimeOfAdd()
  end
  self:PassEvent(AddPointPage.addPointAction)
  self:disableConfirmMt(false)
end

function AddPointPage:OnExit()
  self.centerGridList:RemoveAll()
end
