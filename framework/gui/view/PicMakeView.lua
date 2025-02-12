PicMakeView = class("PicMakeView", BaseView)
PicMakeView.ViewType = UIViewType.NormalLayer
autoImport("PicMakeCell")
PicMakeView.PosConfig = {
  LeftGrid = Vector3(-372, 0, 0),
  MidGrid = Vector3.zero
}
local PicMake_BagCheckTypes, bagProxy

function PicMakeView:Init()
  self:InitView()
  self:MapEvent()
  PicMake_BagCheckTypes = BagProxy.Instance:Get_PackageMaterialCheck_BagTypes(BagProxy.MaterialCheckBag_Type.Produce)
  bagProxy = BagProxy.Instance
end

function PicMakeView:InitView()
  self.mainBord = self:FindGO("MainBord")
  self.blackBg = self:FindComponent("BlackBg", UISprite)
  self.scrollView = self:FindComponent("ScrollView", UIScrollView)
  self.grid = self:FindGO("PicMakeGrid")
  local WrapCfg = {
    wrapObj = self.grid,
    cellName = "PicMakeCell",
    control = PicMakeCell,
    dir = 2,
    disableDragIfFit = true
  }
  self.picMakeCtl = WrapCellHelper.new(WrapCfg)
  self.picMakeCtl:AddEventListener(MouseEvent.MouseClick, self.ClickCombine, self)
  self.picMakeCtl:AddEventListener(PicMakeCell.ClickMaterial, self.ClickMaterial, self)
  self.picMakeCtl:AddEventListener(PicMakeCell.ClickToItem, self.ClickMaterial, self)
end

function PicMakeView:ClickCombine(cellctl)
  if cellctl.data then
    self.composeData = Table_Compose[cellctl.data.staticData.ComposeID]
    if self.composeData.ROB <= MyselfProxy.Instance:GetROB() then
      if not cellctl:CheckCanMake(cellctl.data) then
        MsgManager.ShowMsgByIDTable(40594)
        return
      end
      local useDeduction = cellctl.checkBtn.value
      ServiceItemProxy.Instance:CallProduce(SceneItem_pb.EPRODUCETYPE_HEAD, self.composeData.id, self.npcinfo.data.id, nil, nil, nil, useDeduction)
      self:PlayPicMakeAnim()
    else
      MsgManager.ShowMsgByIDTable(1)
    end
  end
end

function PicMakeView:ClickMaterial(materialcell)
  self:ShowPicMakeItemTip(materialcell.data, materialcell.gameObject)
end

function PicMakeView:ShowPicMakeItemTip(data, obj)
  if data == self.chooseData then
    self.chooseData = nil
    TipManager.Instance:CloseItemTip()
  else
    self.chooseData = data
    local callback = function()
      self.chooseData = nil
    end
    local tipData = {
      itemdata = data,
      funcConfig = {},
      callback = callback,
      ignoreBounds = {obj}
    }
    local stick = UIUtil.GetAllComponentInChildren(obj, UIWidget)
    self:ShowItemTip(tipData, stick, NGUIUtil.AnchorSide.Left, {300, 0})
  end
end

function PicMakeView:UpdateDatas(datas)
  datas = datas or {}
  table.sort(datas, PicMakeView.SortPicData)
  self.picMakeCtl:ResetDatas(datas, true, true)
end

function PicMakeView.SortPicData(a, b)
  local aComposeId, bComposeId = a.staticData.ComposeID, b.staticData.ComposeID
  if aComposeId and bComposeId and aComposeId ~= bComposeId then
    local aCData, bCData = Table_Compose[aComposeId], Table_Compose[bComposeId]
    if aCData and bCData then
      local aCanCompose, bCanCompose = true, true
      for i = 1, #aCData.BeCostItem do
        local material = aCData.BeCostItem[i]
        local num = bagProxy:GetItemNumByStaticID(material.id, PicMake_BagCheckTypes)
        if num < material.num then
          aCanCompose = false
          break
        end
      end
      for i = 1, #bCData.BeCostItem do
        local material = bCData.BeCostItem[i]
        local num = bagProxy:GetItemNumByStaticID(material.id, PicMake_BagCheckTypes)
        if num < material.num then
          bCanCompose = false
          break
        end
      end
      if aCanCompose ~= bCanCompose then
        return aCanCompose
      end
      local aProduce, bProduce = aCData.Product.id, bCData.Product.id
      if aProduce and bProduce and aProduce ~= bProduce then
        local aPItem, bPItem = Table_Item[aProduce], Table_Item[bProduce]
        if aPItem and bPItem and aPItem.AdventureValue and aPItem.AdventureValue > 0 and bPItem.AdventureValue and bPItem.AdventureValue > 0 and aPItem.AdventureValue ~= bPItem.AdventureValue then
          return aPItem.AdventureValue < bPItem.AdventureValue
        end
      end
    end
  end
  if a.staticData.Quality ~= b.staticData.Quality then
    return a.staticData.Quality > b.staticData.Quality
  end
  return a.staticData.id > b.staticData.id
end

function PicMakeView:PlayPicMakeAnim()
  self:ActiveView(false)
  TimeTickManager.Me():ClearTick(self)
  TimeTickManager.Me():CreateOnceDelayTick(4000, function(owner, deltaTime)
    self:PicMakeDone()
  end, self)
end

function PicMakeView:ActiveView(b)
  self.mainBord:SetActive(b)
  self.blackBg.color = b and Color(1, 1, 1, 1) or Color(1, 1, 1, 0.00392156862745098)
end

function PicMakeView:PicMakeDone()
  FunctionVisitNpc.Me():AccessTarget(self.npcinfo)
  self:CloseSelf()
end

function PicMakeView:MapEvent()
  self:AddListenEvt(ItemEvent.ItemUpdate, self.HandleUpdateMaterial)
end

function PicMakeView:HandleUpdateMaterial(note)
  local cells = self.picMakeCtl:GetCellCtls()
  for i = 1, #cells do
    cells[i]:Refresh()
  end
end

function PicMakeView:OnEnter()
  PicMakeView.super.OnEnter(self)
  local viewdata = self.viewdata.viewdata
  if viewdata then
    self.datas = viewdata.datas
    self.npcinfo = viewdata.npcdata
  end
  self:UpdateDatas(self.datas)
  local npcRootTrans = self.npcinfo.assetRole.completeTransform
  if npcRootTrans then
    local viewPort = CameraConfig.NPC_Dialog_ViewPort
    if type(self.camera) == "number" then
      viewPort = Vector3(viewPort.x, viewPort.y, self.camera)
    end
    local duration = CameraConfig.NPC_Dialog_DURATION
    self:CameraFocusOnNpc(npcRootTrans, viewPort, duration)
  end
end

function PicMakeView:OnShow()
  self.scrollView:ResetPosition()
end

function PicMakeView:OnExit()
  PicMakeView.super.OnExit(self)
  local cells = self.picMakeCtl:GetCellCtls()
  for i = 1, #cells do
    cells[i]:OnRemove()
  end
  self:CameraReset()
end
