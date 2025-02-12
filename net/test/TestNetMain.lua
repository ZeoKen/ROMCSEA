require("Script.Main.FilePath")
require("Script.Main.init")
require("Script.Main.Import")
require("Script.Net.NetPrefix")
GameFacade = {}
GameFacade.Instance = pm.Facade:getInstance("Game")
GameFacade.Instance:registerCommand(StartEvent.StartUp, StartUpCommand)
GameFacade.Instance:sendNotification(StartEvent.StartUp)
local TestStartGamePanel = class("TestStartGamePanel", BaseView)

function TestStartGamePanel:Init()
  self:MapSwitchHandler()
end

local uiRoot = GameObject.Find("UIRoot")
local TestNetUI = Game.GameObjectUtil:DeepFindChild(uiRoot, "TestNet")
local testStartGamePanel = TestStartGamePanel.new(TestNetUI)
testStartGamePanel:OnEnter()
