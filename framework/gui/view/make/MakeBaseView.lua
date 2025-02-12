autoImport("BusinessmanMakeMaterialCell")
autoImport("BusinessmanMakeItemCell")
autoImport("BusinessmanMakeModelCell")
autoImport("BusinessmanMakeTypeCell")
MakeBaseView = class("MakeBaseView", ContainerView)
MakeBaseView.ViewType = UIViewType.NormalLayer
local bgName = "shop_bg_05"
local normalMaterialPosVec = LuaVector3.Zero()
local greatMaterialPosVec = LuaVector3.Zero()

function MakeBaseView:OnExit()
  self.modelCell:OnRemove()
  if self.plusTick ~= nil then
    TimeTickManager.Me():ClearTick(self, 1)
    self.plusTick = nil
  end
  if self.subtractTick ~= nil then
    TimeTickManager.Me():ClearTick(self, 2)
    self.subtractTick = nil
  end
  local _PictureManager = PictureManager.Instance
  _PictureManager:UnLoadUI(bgName, self.normalNormalProductBg)
  _PictureManager:UnLoadUI(bgName, self.modelNormalProductBg)
  _PictureManager:UnLoadUI(bgName, self.normalGreatProductBg)
  _PictureManager:UnLoadUI(bgName, self.greatGreatProductBg)
  MakeBaseView.super.OnExit(self)
end

function MakeBaseView:Init()
  self:FindObjs()
  self:AddEvts()
  self:AddViewEvts()
  self:InitShow()
end

function MakeBaseView:FindObjs()
  self.makeRoot = self:FindGO("MakeRoot")
  self.makeBtn = self:FindGO("MakeBtn"):GetComponent(UISprite)
  self.makeCount = self:FindGO("MakeCount"):GetComponent(UIInput)
  self.countPlusBg = self:FindGO("CountPlusBg"):GetComponent(UISprite)
  self.countPlus = self:FindGO("CountPlus"):GetComponent(UISprite)
  self.countSubtractBg = self:FindGO("CountSubtractBg"):GetComponent(UISprite)
  self.countSubtract = self:FindGO("CountSubtract"):GetComponent(UISprite)
  self.lockTip = self:FindGO("LockTip"):GetComponent(UILabel)
  self.itemTable = self:FindGO("ItemTable"):GetComponent(UITable)
  self.normalProduct = self:FindGO("NormalProduct")
  self.greatProduct = self:FindGO("GreatProduct")
  self.normalRoot = self:FindGO("NormalRoot", self.normalProduct)
  self.normalNormalProductBg = self:FindGO("Bg", self.normalRoot):GetComponent(UITexture)
  self.modelRoot = self:FindGO("ModelRoot", self.normalProduct)
  self.modelNormalProductBg = self:FindGO("Bg", self.modelRoot):GetComponent(UITexture)
  self.makeMaterial = self:FindGO("MakeMaterialGrid")
end

function MakeBaseView:AddEvts()
  self:AddClickEvent(self.makeBtn.gameObject, function()
    if self.curComposeId == nil then
      return
    end
    if self.validStamp and ServerTime.CurServerTime() / 1000 < self.validStamp then
      return
    end
    self.validStamp = ServerTime.CurServerTime() / 1000 + 0.6
    self:calcMakeMaterial()
    local enoughMaterial = self.total - self.need
    local makeData = BusinessmanMakeProxy.Instance:GetMakeData(self.curComposeId)
    if enoughMaterial < 0 then
      MsgManager.ShowMsgByID(8)
      return
    elseif makeData:IsLock() then
      local composeData = Table_Compose[self.curComposeId]
      if composeData and composeData.MenuID then
        local menuData = Table_Menu[composeData.MenuID]
        if menuData and menuData.sysMsg and menuData.sysMsg.id then
          MsgManager.ShowMsgByID(menuData.sysMsg.id)
        end
      end
      return
    end
    ServiceItemProxy.Instance:CallProduce(SceneItem_pb.EPRODUCETYPE_TRADER, self.curComposeId, nil, nil, self.makeTimes)
  end)
  self:AddPressEvent(self.countPlus.gameObject, function(g, b)
    self:PressCountPlus(b)
  end)
  self:AddPressEvent(self.countSubtract.gameObject, function(g, b)
    self:PressCountSubtract(b)
  end)
  EventDelegate.Set(self.makeCount.onChange, function()
    self:InputOnChange()
  end)
end

function MakeBaseView:AddViewEvts()
  self:AddListenEvt(ItemEvent.ItemUpdate, self.HandleItemUpdate)
  self:AddListenEvt(MyselfEvent.MyDataChange, self.HandleItemUpdate)
end

function MakeBaseView:InitShow()
  self.isSelfProfession = true
  self.tipData = {}
  self.tipData.funcConfig = {}
  local x, y, z = LuaGameObject.GetLocalPosition(self.makeMaterial.transform)
  LuaVector3.Better_Set(normalMaterialPosVec, x, -131, z)
  LuaVector3.Better_Set(greatMaterialPosVec, x, -159, z)
  self.normalCell = BusinessmanMakeItemCell.new(self.normalRoot)
  self.normalCell:AddEventListener(MouseEvent.MouseClick, self.ClickCell, self)
  self.modelCell = BusinessmanMakeModelCell.new(self.modelRoot)
  self.modelCell:AddEventListener(MouseEvent.MouseClick, self.ClickModelCell, self)
  local greatNormalRoot = self:FindGO("NormalRoot", self.greatProduct)
  self.greatNormalCell = BusinessmanMakeItemCell.new(greatNormalRoot)
  self.greatNormalCell:AddEventListener(MouseEvent.MouseClick, self.ClickCell, self)
  local greatRoot = self:FindGO("GreatRoot", self.greatProduct)
  self.greatCell = BusinessmanMakeItemCell.new(greatRoot)
  self.greatCell:AddEventListener(MouseEvent.MouseClick, self.ClickCell, self)
  local makeMaterialGrid = self.makeMaterial:GetComponent(UIGrid)
  self.makeMatCtl = UIGridListCtrl.new(makeMaterialGrid, BusinessmanMakeMaterialCell, "BusinessmanMakeMaterialCell")
  self.makeMatCtl:AddEventListener(MouseEvent.MouseClick, self.ClickMakeMaterialItem, self)
  self.typeCtl = UIGridListCtrl.new(self.itemTable, BusinessmanMakeTypeCell, "BusinessmanMakeTypeCell")
  self.typeCtl:AddEventListener(MouseEvent.MouseClick, self.ClickItem, self)
  BusinessmanMakeProxy.Instance:InitItemList(self.type.Type)
  self.normalGreatProductBg = self:FindGO("Bg", greatNormalRoot):GetComponent(UITexture)
  self.greatGreatProductBg = self:FindGO("Bg", greatRoot):GetComponent(UITexture)
  local _PictureManager = PictureManager.Instance
  _PictureManager:SetUI(bgName, self.normalNormalProductBg)
  _PictureManager:SetUI(bgName, self.modelNormalProductBg)
  _PictureManager:SetUI(bgName, self.normalGreatProductBg)
  _PictureManager:SetUI(bgName, self.greatGreatProductBg)
  self:UpdateItemList()
  self:SelectFirst()
  self:ResetMakeCount()
end

function MakeBaseView:ClickCell(cellctl)
  self.tipData.itemdata = cellctl.data
  self:ShowItemTip(self.tipData, cellctl.icon, NGUIUtil.AnchorSide.Left, {-170, 0})
end

function MakeBaseView:ClickModelCell(cellctl)
  self.tipData.itemdata = cellctl.data
  self:ShowItemTip(self.tipData, self.makeBtn, NGUIUtil.AnchorSide.Left, {-220, 0})
end

function MakeBaseView:ClickMakeMaterialItem(cellctl)
  self.tipData.itemdata = cellctl.itemData
  self:ShowItemTip(self.tipData, cellctl.icon, NGUIUtil.AnchorSide.Left, {-220, 0})
end

function MakeBaseView:ClickItem(cellctl)
  local data = cellctl.data
  if data then
    if self.lastItemCell then
      self.lastItemCell:SetChoose(false)
    end
    cellctl:SetChoose(true)
    self.lastItemCell = cellctl
    self.curComposeId = data.id
    self:UpdateItem(data)
    self:ResetMakeCount()
  end
end

function MakeBaseView:PressCountPlus(isPressed)
  if isPressed then
    self.countChangeRate = 1
    TimeTickManager.Me():CreateTick(0, 150, function(owner, deltaTime)
      self:PressCount(1)
    end, self, 1001)
  else
    TimeTickManager.Me():ClearTick(self, 1001)
  end
end

function MakeBaseView:PressCountSubtract(isPressed)
  if isPressed then
    self.countChangeRate = 1
    TimeTickManager.Me():CreateTick(0, 150, function(owner, deltaTime)
      self:PressCount(-1)
    end, self, 1002)
  else
    TimeTickManager.Me():ClearTick(self, 1002)
  end
end

function MakeBaseView:PressCount(change)
  self.makeTimes = self.makeTimes + self.countChangeRate * change
  self:UpdateMakeCount()
  if self.countChangeRate <= 3 then
    self.countChangeRate = self.countChangeRate + 1
  end
end

function MakeBaseView:InputOnChange()
  local count = tonumber(self.makeCount.value)
  if count == nil then
    return
  end
  self.makeTimes = count
  self:UpdateMakeCount()
end

function MakeBaseView:UpdateItemList()
  if self.type ~= nil then
    self.typeCtl:ResetDatas(self.type.Category)
  end
end

function MakeBaseView:UpdateMakeMaterial()
  local data = Table_Compose[self.curComposeId]
  local datas = data and data.BeCostItem or {}
  self.makeMatCtl:ResetDatas(datas)
end

function MakeBaseView:UpdateProduceCell(itemData)
  if itemData then
    self.produceCell:SetData(itemData)
  end
  local isShow = itemData ~= nil
  self.produceCell.gameObject:SetActive(isShow)
end

function MakeBaseView:UpdateItem(data)
  local isGreatProduce = data.produceItemData ~= nil
  local composeData = Table_Compose[self.curComposeId]
  if isGreatProduce then
    self.greatNormalCell:SetData(data.itemData)
    self.greatCell:SetData(data.produceItemData)
    self.greatNormalCell:SetProduceRate(composeData)
    self.greatNormalCell:SetProductNum(data, self.makeTimes)
    self.greatCell:SetProductNum(data, self.makeTimes)
    self.makeMaterial.transform.localPosition = greatMaterialPosVec
  else
    local showType = BusinessmanMakeProxy.Instance:CheckItemType(data.itemData)
    if showType then
      self.modelCell:SetData(data.itemData, showType)
      self.modelCell:SetProduceRate(composeData)
      self.modelCell:SetProductNum(data, self.makeTimes)
    else
      self.normalCell:SetData(data.itemData)
      self.normalCell:SetProduceRate(composeData)
      self.normalCell:SetProductNum(data, self.makeTimes)
    end
    self.normalRoot:SetActive(showType == nil)
    self.modelRoot:SetActive(showType ~= nil)
    self.makeMaterial.transform.localPosition = normalMaterialPosVec
  end
  self.greatProduct:SetActive(isGreatProduce)
  self.normalProduct:SetActive(not isGreatProduce)
  self:UpdateMakeMaterial()
  if data:IsLock() then
    self:Hide(self.makeRoot)
    self:Show(self.lockTip.gameObject)
    local composeData = Table_Compose[data.id]
    self.lockTip.text = ZhString.Businessman_Need .. Table_Menu[composeData.MenuID].Tip
  else
    self:Show(self.makeRoot)
    self:Hide(self.lockTip.gameObject)
  end
end

function MakeBaseView:UpdateMakeCount()
  if self.maxTimes == 1 then
    self:SetCountSubtract(0.5)
    self:SetCountPlus(0.5)
    self.makeTimes = 1
    self.countChangeRate = 1
  elseif 1 >= self.makeTimes then
    self:SetCountSubtract(0.5)
    self:SetCountPlus(1)
    self.makeTimes = 1
    self.countChangeRate = 1
  elseif self.makeTimes >= self.maxTimes then
    self:SetCountSubtract(1)
    self:SetCountPlus(0.5)
    self.makeTimes = self.maxTimes
    self.countChangeRate = 1
  else
    self:SetCountSubtract(1)
    self:SetCountPlus(1)
  end
  self.makeCount.value = self.makeTimes
  local data = BusinessmanMakeProxy.Instance:GetMakeData(self.curComposeId)
  local isGreatProduce = data.produceItemData ~= nil
  if isGreatProduce then
    self.greatNormalCell:SetProductNum(data, self.makeTimes)
    self.greatCell:SetProductNum(data, self.makeTimes)
  else
    local showType = BusinessmanMakeProxy.Instance:CheckItemType(data.itemData)
    if showType then
      self.modelCell:SetProductNum(data, self.makeTimes)
    else
      self.normalCell:SetProductNum(data, self.makeTimes)
    end
  end
  local cells = self.makeMatCtl:GetCells()
  for i = 1, #cells do
    local cell = cells[i]
    cell:SetNum(nil, self.makeTimes)
  end
end

function MakeBaseView:HandleItemUpdate()
  local typeList = self.typeCtl:GetCells()
  for i = 1, #typeList do
    local typeCell = typeList[i]
    for j = 1, #typeCell:GetCombineCellList() do
      local combineCell = typeCell:GetCombineCellList()[j]
      for k = 1, #combineCell.childrenObjs do
        local cell = combineCell.childrenObjs[k]
        if cell and cell.data then
          cell:SetCanMakeNum()
        end
      end
    end
  end
  self:UpdateMakeMaterial()
  self:ResetMakeCount()
end

function MakeBaseView:SelectFirst()
  local itemList = self.typeCtl:GetCells()[1]
  if itemList then
    local combineCell = itemList:GetCombineCellList()[1]
    if combineCell then
      local cell = combineCell.childrenObjs[1]
      if cell then
        self:ClickItem(cell)
      end
    end
  end
end

function MakeBaseView:ResetMakeCount()
  if not self.lastComposeId or self.lastComposeId ~= self.curComposeId then
    self.makeTimes = 1
  end
  self.maxTimes = BusinessmanMakeData.GetCanMakeTimes(self.curComposeId)
  if self.maxTimes == 0 then
    self.maxTimes = 1
  end
  self.maxTimes = math.min(self.maxTimes, 999)
  self.makeTimes = math.min(self.maxTimes, self.makeTimes)
  self:UpdateMakeCount()
end

function MakeBaseView:calcMakeMaterial()
  local cells = self.makeMatCtl:GetCells()
  self.need = #cells
  self.total = 0
  for i = 1, self.need do
    local cell = cells[i]
    if cell:IsEnough() then
      self.total = self.total + 1
    end
  end
end

function MakeBaseView:SetCountPlus(alpha)
  if self.countPlusBg.color.a ~= alpha then
    self:SetSpritAlpha(self.countPlusBg, alpha)
    self:SetSpritAlpha(self.countPlus, alpha)
  end
end

function MakeBaseView:SetCountSubtract(alpha)
  if self.countSubtractBg.color.a ~= alpha then
    self:SetSpritAlpha(self.countSubtractBg, alpha)
    self:SetSpritAlpha(self.countSubtract, alpha)
  end
end

function MakeBaseView:SetSpritAlpha(sprit, alpha)
  sprit.color = Color(sprit.color.r, sprit.color.g, sprit.color.b, alpha)
end
