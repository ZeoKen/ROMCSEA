NpcFeatures = {}
NpcFeatures.PickUp = {PickupRange = 10, PickupMaxItem = 20}
NpcFeatures.TeamWork = {
  TeamHelpRange = 7,
  TeamHelpHp = 90,
  TeamAttack = {
    range = 3,
    responseTime = 1,
    emoji = 7
  }
}
NpcFeatures.Ghost = {
  BirthBuff = {
    160100,
    160101,
    160104,
    160105,
    160106,
    160108
  },
  DamPer = 5
}
NpcFeatures.Demon = {BuffID = 150010, DizzyVal = 15}
NpcFeatures.Flight = {
  ImmuneSkill = {
    93,
    97,
    99,
    116,
    117,
    122
  }
}
NpcFeatures.ShowMoe = {
  BuffID = 150030,
  ShowMoeRange = 10,
  ShowMoeVal = 10,
  StayTime = 3
}
NpcFeatures.SceneStealing = {
  BuffID = 150040,
  Distance = 15,
  Pos = 1,
  Val = 15
}
NpcFeatures.Mischievous = {
  ResponseTime = 1,
  SkillID = 10022001,
  Emoji1 = 1,
  Emoji2 = 5
}
NpcFeatures.Alert = {
  FindRange = 10,
  Emoji = 5,
  ResponseTime = 1,
  SkillID = 10022001,
  SkillVal = 10
}
NpcFeatures.Expel = {
  FindRange = 10,
  Emoji = 5,
  ExpelVal = 10,
  SkillID = 10021001
}
NpcFeatures.Jealous = {FindRange = 8, Emoji = 12}
NpcFeatures.ItemFind = {FindRange = 6}
NpcFeatures.LeaveBattle = {
  LeaveRange = 10,
  LeaveTime = 5,
  MVPLeaveRange = 15,
  MVPLeaveTime = 8
}
NpcFeatures.TeamBattle = {
  FindRange = 6,
  {status = 5, skill = 107},
  {status = 6, skill = 74}
}
NpcFeatures.Night = {
  Buffer = {150050}
}
NpcFeatures.Endure = {Cd = 6, skill = 14}
NpcFeatures.Servant = {keep_distance = 4}
NpcFeatures.GoBack = {
  buff = {},
  noattacked = 160200,
  noattack = 151190
}
NpcFeatures.AIParams = {run_away_time = 2, crowd_check_range = 0.1}
