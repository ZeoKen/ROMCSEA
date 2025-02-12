ConditionItem = class("ConditionItem", BaseCell)
autoImport("TutorItemCell")
autoImport("WrapListCtrl")
local tipData = {}
tipData.funcConfig = {}

function ConditionItem:Init()
  self.scrollBg = self:FindGO("ScrollBg"):GetComponent(UISprite)
  self.conditionTitle = self:FindGO("Condition"):GetComponent(UILabel)
  self.isAchieve = self:FindGO("Achieve"):GetComponent(UIMultiSprite)
  self.rewardGrid = self:FindGO("Grid"):GetComponent(UIGrid)
  self.itemCtl = UIGridListCtrl.new(self.rewardGrid, TutorItemCell, "TutorItemCell")
  self.itemCtl:AddEventListener(MouseEvent.MouseClick, self.ClickItem, self)
  self.boxCollider = self.scrollBg.gameObject:GetComponent(BoxCollider)
end

function ConditionItem:SetData(data)
  self.data = data
  if data then
    local studentReward = ItemUtil.GetRewardItemIdsByTeamId(self.data.StudentReward)
    if data.Type == 2 then
      studentReward = ItemUtil.GetRewardItemIdsByTeamId(GameConfig.Tutor.student_graduation_reward)
      self.conditionTitle.text = ZhString.Tutor_GraduationRewardTtile
    else
      self.conditionTitle.text = string.format(ZhString.Tutor_Graduation, self.data.MaxLevel)
    end
    if studentReward then
      self.itemCtl:ResetDatas(studentReward)
      local length = #studentReward
      local line = math.floor(length / 4)
      local rest = length % 4
      if rest ~= 0 then
        line = line + 1
      end
      local height = line * 109
      local p = -54.5 * (line - 1)
      self.scrollBg.transform.localPosition = LuaGeometry.GetTempVector3(-8, p, 0)
      self.scrollBg.height = height
      self.boxCollider.size = LuaGeometry.GetTempVector3(454, height + 60, 1)
    end
    self.canGet = data.canGet
    if data.Type == 1 then
      self:UpdateStatus(self.canGet)
    else
      self.isAchieve.gameObject:SetActive(false)
    end
  end
end

function ConditionItem:UpdateStatus(newState)
  self.isAchieve.CurrentState = newState
  self.isAchieve:MakePixelPerfect()
  if newState == 0 or newState == 2 then
    self.isAchieve.gameObject:SetActive(true)
  else
    self.isAchieve.gameObject:SetActive(false)
  end
end

function ConditionItem:ClickItem(cell)
  local data = cell.data
  if data then
    tipData.itemdata = data
    self:ShowItemTip(tipData, cell.icon, NGUIUtil.AnchorSide.Left, {-220, 0})
  end
end
