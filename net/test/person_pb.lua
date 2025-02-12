local protobuf = protobuf
module("person_pb")
local DATA1 = protobuf.EnumDescriptor()
local DATA1_FRR_OK_ENUM = protobuf.EnumValueDescriptor()
local DATA1_FRR_LOWPOW_ENUM = protobuf.EnumValueDescriptor()
local DATA1_FRR_REJECT_ENUM = protobuf.EnumValueDescriptor()
local DATA2 = protobuf.Descriptor()
local DATA2_ARMPOS_FIELD = protobuf.FieldDescriptor()
local DATA2_GUID_FIELD = protobuf.FieldDescriptor()
local DATA2_PETID_FIELD = protobuf.FieldDescriptor()
local DATA2_STARS_FIELD = protobuf.FieldDescriptor()
local DATA = protobuf.Descriptor()
local DATA_UID_FIELD = protobuf.FieldDescriptor()
local DATA_RESULT_FIELD = protobuf.FieldDescriptor()
local DATA_PETS_FIELD = protobuf.FieldDescriptor()
DATA1_FRR_OK_ENUM.name = "FRR_OK"
DATA1_FRR_OK_ENUM.index = 0
DATA1_FRR_OK_ENUM.number = 1
DATA1_FRR_LOWPOW_ENUM.name = "FRR_LOWPOW"
DATA1_FRR_LOWPOW_ENUM.index = 1
DATA1_FRR_LOWPOW_ENUM.number = 2
DATA1_FRR_REJECT_ENUM.name = "FRR_REJECT"
DATA1_FRR_REJECT_ENUM.index = 2
DATA1_FRR_REJECT_ENUM.number = 3
DATA1.name = "Data1"
DATA1.full_name = ".Data1"
DATA1.values = {
  DATA1_FRR_OK_ENUM,
  DATA1_FRR_LOWPOW_ENUM,
  DATA1_FRR_REJECT_ENUM
}
DATA2_ARMPOS_FIELD.name = "armpos"
DATA2_ARMPOS_FIELD.full_name = ".Data2.armpos"
DATA2_ARMPOS_FIELD.number = 1
DATA2_ARMPOS_FIELD.index = 0
DATA2_ARMPOS_FIELD.label = 1
DATA2_ARMPOS_FIELD.has_default_value = false
DATA2_ARMPOS_FIELD.default_value = 0
DATA2_ARMPOS_FIELD.type = 5
DATA2_ARMPOS_FIELD.cpp_type = 1
DATA2_GUID_FIELD.name = "guid"
DATA2_GUID_FIELD.full_name = ".Data2.guid"
DATA2_GUID_FIELD.number = 2
DATA2_GUID_FIELD.index = 1
DATA2_GUID_FIELD.label = 1
DATA2_GUID_FIELD.has_default_value = false
DATA2_GUID_FIELD.default_value = 0
DATA2_GUID_FIELD.type = 4
DATA2_GUID_FIELD.cpp_type = 4
DATA2_PETID_FIELD.name = "petid"
DATA2_PETID_FIELD.full_name = ".Data2.petid"
DATA2_PETID_FIELD.number = 3
DATA2_PETID_FIELD.index = 2
DATA2_PETID_FIELD.label = 1
DATA2_PETID_FIELD.has_default_value = false
DATA2_PETID_FIELD.default_value = 0
DATA2_PETID_FIELD.type = 5
DATA2_PETID_FIELD.cpp_type = 1
DATA2_STARS_FIELD.name = "stars"
DATA2_STARS_FIELD.full_name = ".Data2.stars"
DATA2_STARS_FIELD.number = 5
DATA2_STARS_FIELD.index = 3
DATA2_STARS_FIELD.label = 1
DATA2_STARS_FIELD.has_default_value = false
DATA2_STARS_FIELD.default_value = 0
DATA2_STARS_FIELD.type = 5
DATA2_STARS_FIELD.cpp_type = 1
DATA2.name = "Data2"
DATA2.full_name = ".Data2"
DATA2.nested_types = {}
DATA2.enum_types = {}
DATA2.fields = {
  DATA2_ARMPOS_FIELD,
  DATA2_GUID_FIELD,
  DATA2_PETID_FIELD,
  DATA2_STARS_FIELD
}
DATA2.is_extendable = false
DATA2.extensions = {}
DATA_UID_FIELD.name = "uid"
DATA_UID_FIELD.full_name = ".Data.uid"
DATA_UID_FIELD.number = 1
DATA_UID_FIELD.index = 0
DATA_UID_FIELD.label = 2
DATA_UID_FIELD.has_default_value = false
DATA_UID_FIELD.default_value = 0
DATA_UID_FIELD.type = 4
DATA_UID_FIELD.cpp_type = 4
DATA_RESULT_FIELD.name = "result"
DATA_RESULT_FIELD.full_name = ".Data.result"
DATA_RESULT_FIELD.number = 2
DATA_RESULT_FIELD.index = 1
DATA_RESULT_FIELD.label = 2
DATA_RESULT_FIELD.has_default_value = false
DATA_RESULT_FIELD.default_value = nil
DATA_RESULT_FIELD.enum_type = DATA1
DATA_RESULT_FIELD.type = 14
DATA_RESULT_FIELD.cpp_type = 8
DATA_PETS_FIELD.name = "pets"
DATA_PETS_FIELD.full_name = ".Data.pets"
DATA_PETS_FIELD.number = 3
DATA_PETS_FIELD.index = 2
DATA_PETS_FIELD.label = 3
DATA_PETS_FIELD.has_default_value = false
DATA_PETS_FIELD.default_value = {}
DATA_PETS_FIELD.message_type = DATA2
DATA_PETS_FIELD.type = 11
DATA_PETS_FIELD.cpp_type = 10
DATA.name = "Data"
DATA.full_name = ".Data"
DATA.nested_types = {}
DATA.enum_types = {}
DATA.fields = {
  DATA_UID_FIELD,
  DATA_RESULT_FIELD,
  DATA_PETS_FIELD
}
DATA.is_extendable = false
DATA.extensions = {}
Data = protobuf.Message(DATA)
Data2 = protobuf.Message(DATA2)
FRR_LOWPOW = 2
FRR_OK = 1
FRR_REJECT = 3
