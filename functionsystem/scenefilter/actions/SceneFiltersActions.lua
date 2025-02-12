autoImport("LActionNode")
SceneFilterSetDataAction = class("SceneFilterSetDataAction", LActionNode)

function SceneFilterSetDataAction:ctor(tree, key, data)
  SceneFilterSetDataAction.super.ctor(self, tree)
  self.key = key
  self.data = data
end

function SceneFilterSetDataAction:DoAction()
  self.behaviorTree.blackBoard[self.key] = self.data
  return TaskState.Failure
end

SceneFilterActiveNode = class("SceneFilterActiveNode", LActionNode)

function SceneFilterActiveNode:DoAction()
  local node = self.behaviorTree.blackBoard.groupNode
  local rangeCon
  for k, v in pairs(node.filterMap) do
    rangeCon = SceneFilterNode.GetRangeConNode(v.Range[1])
    if rangeCon and rangeCon:Update() == TaskState.Success then
      SceneFilterProxy.Instance:SceneFilterCheck(k, self.behaviorTree.blackBoard.ftarget, node.counterwise)
    end
  end
  return TaskState.Running
end

SceneFilterInActiveNode = class("SceneFilterInActiveNode", LActionNode)

function SceneFilterInActiveNode:DoAction()
  local node = self.behaviorTree.blackBoard.groupNode
  for k, v in pairs(node.filterMap) do
    SceneFilterProxy.Instance:SceneFilterUnCheck(k, self.behaviorTree.blackBoard.ftarget, nil, nil, node.counterwise)
  end
  return TaskState.Running
end
