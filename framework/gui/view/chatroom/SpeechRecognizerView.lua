SpeechRecognizerView = class("SpeechRecognizerView", ContainerView)
SpeechRecognizerView.ViewType = UIViewType.PopUpLayer

function SpeechRecognizerView:Init()
  self:FindObjs()
  self:AddEvts()
  self:InitShow()
end

function SpeechRecognizerView:FindObjs()
  self.speechRecognizer = UIManagerProxy.Instance.speechRecognizer
  self.speechRecognizerRoot = self:FindGO("SpeechRecognizerRoot")
  self.speech = self:FindGO("Speech")
  self.cancel = self:FindGO("Cancel")
  self.tip = self:FindGO("Tip"):GetComponent(UILabel)
  self.tipBg = self:FindGO("TipBg")
  self.voiceList = {}
  for i = 1, 8 do
    local go = self:FindGO("voice" .. i, self.speechRecognizerRoot)
    table.insert(self.voiceList, go)
  end
end

function SpeechRecognizerView:AddEvts()
  local updateVolume = function(volume)
    local level = 8 * volume / 30
    level = math.floor(level)
    for i = 1, #self.voiceList do
      if i <= level then
        self.voiceList[i]:SetActive(true)
      else
        self.voiceList[i]:SetActive(false)
      end
    end
  end
  self.speechRecognizer.updateVolume = updateVolume
end

function SpeechRecognizerView:InitShow()
  self:SetSpeechView(true)
  self:AddListenEvt(ChatRoomEvent.StopRecognizer, self.CloseSelf)
end

function SpeechRecognizerView:OnEnter()
  local funcIn = function()
    if not self.isInRange then
      self:SetSpeechView(true)
    end
  end
  local funcNotIn = function()
    if self.isInRange then
      self:SetSpeechView(false)
    end
  end
  Game.UILongPressManager:StartCheck(100, 100, funcIn, funcNotIn)
  ExternalInterfaces.StartRecognizer()
  TimeTickManager.Me():CreateOnceDelayTick(30000, function(owner, deltaTime)
    self:CloseSelf()
  end, self)
  FunctionBGMCmd.Me():SetMute(true)
end

function SpeechRecognizerView:OnExit()
  Game.UILongPressManager:StopCheck()
  ExternalInterfaces.StopRecognizer()
  TimeTickManager.Me():ClearTick(self)
  self.speechRecognizer.updateVolume = nil
  FunctionBGMCmd.Me():SetMute(false)
end

function SpeechRecognizerView:SetSpeechView(isSpeech)
  self.speech:SetActive(isSpeech)
  self.cancel:SetActive(not isSpeech)
  self.tipBg:SetActive(not isSpeech)
  if isSpeech then
    self.tip.text = ZhString.Chat_speechRecognizer
  else
    self.tip.text = ZhString.Chat_speechCancel
  end
  self.isInRange = isSpeech
end
