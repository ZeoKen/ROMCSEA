local baseCell = autoImport("BaseCell")
MessageFlyer = class("MessageFlyer", baseCell)
MessageFlyer.resID = ResourcePathHelper.UICell("MessageFlyer")

function MessageFlyer:ctor()
end

function MessageFlyer:AttachGO(parent)
  self.parent = parent
  self.gameObject = self:CreateObj(MessageFlyer.resID, parent)
  self.transform = self.gameObject.transform
  self.transform.localScale = LuaGeometry.GetTempVector3(40, 40, 0)
end

function MessageFlyer:Initialize(str, color, xAxis, zAxis, speed, height)
  self.lab = self.gameObject:GetComponentInChildren("UILabel")
  self.lab.text = str
  self.lab.color = LuaColor(color.r / 255, color.g / 255, color.b / 255, 1)
  self.lab.alpha = 0
  local ta = TweenAlpha.Begin(self.gameObject, 1, 1)
  self.transform.localPosition = LuaGeometry.GetTempVector3(xAxis, 3000, zAxis)
  self.rotatePoint = self.parent.transform.position
  self.r = 200
  self.speed = speed
  self.height = height
  self.rotateAroundNoParent = self.gameObject:GetComponent("RotateAroundNoParent")
  self.rotateAroundNoParent.TargetPoint = self.rotatePoint
  self.rotateAroundNoParent:Initialize(speed, self.r, height)
end

function MessageFlyer:Start()
  self.rotateAroundNoParent:DoStart()
end

function MessageFlyer:Stop()
  self.rotateAroundNoParent:DoStop()
end

function MessageFlyer:Reset()
  self.rotateAroundNoParent:DoEnd()
  GameObject.Destroy(self.gameObject)
end

function MessageFlyer:ResetLab()
  self.lab.text = ""
end
