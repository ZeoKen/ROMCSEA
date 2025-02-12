Table_DateBattleCity = {
  [10001] = {
    id = 10001,
    Name = "##42533187",
    MapId = 2,
    Text = "##42534687",
    TelePort = {2, 6},
    RaidId = 9033,
    LobbyRaidID = 9032,
    Point = {
      [1] = {
        pos = {
          -29.24,
          2.44,
          48.69
        },
        range = 7,
        protect_metal = 1
      },
      [2] = {
        pos = {
          29.24,
          2.44,
          48.69
        },
        range = 7,
        protect_metal = 1
      },
      [3] = {
        pos = {
          0,
          2.19,
          -43.46
        },
        range = 7,
        protect_metal = 1
      },
      [4] = {
        pos = {
          -50,
          2.19,
          -15
        },
        range = 7,
        protect_metal = 1
      },
      [5] = {
        pos = {
          50,
          2.19,
          -15
        },
        range = 7,
        protect_metal = 1
      },
      [6] = {
        pos = {
          0,
          2,
          -110
        },
        range = 7
      },
      [7] = {
        pos = {
          -85,
          1.45,
          -64
        },
        range = 7
      },
      [8] = {
        pos = {
          85,
          1.53,
          -64
        },
        range = 7
      }
    },
    CityType = 3,
    Icon = "tab_icon_castle_c",
    IconColor = "98B8FFFF",
    Mode = 1
  },
  [20001] = {
    id = 20001,
    Name = "##42533189",
    MapId = 42,
    Text = "##42534687",
    TelePort = {42, 8},
    RaidId = 9101,
    LobbyRaidID = 9100,
    Point = {
      [1] = {
        pos = {
          65.7,
          -1,
          52.5
        },
        range = 7,
        calc_ratio = 8,
        protect_metal = 1
      }
    },
    CityType = 3,
    Icon = "tab_icon_castle_c",
    IconColor = "EFBA6EFF",
    Mode = 2
  }
}
Table_DateBattleCity_fields = {
  "id",
  "Name",
  "MapId",
  "Text",
  "TelePort",
  "RaidId",
  "LobbyRaidID",
  "GuildEp",
  "Point",
  "CityType",
  "Icon",
  "IconColor",
  "Mode"
}
return Table_DateBattleCity
