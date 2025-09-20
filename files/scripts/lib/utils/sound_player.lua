-- 音声再生を行うObject
-- Note: Noitaの音声はframe計測ではなくリアルタイム計測（ポーズメニュー時にも流れる）なため注意すること
SoundPlayer = {
  IS_LOADED_VARIABLE_NAME = "is_Loaded_variable_name",
  SOUND_TYPE_VARIABLE_NAME = "sound_type_variable_name",
  XML_FILE_VARIABLE_NAME = "xml_file_variable_name",
  SOUND_TYPES = {
    FORCE = "force", -- 強制的に他の音声を止めてから再生する
    COVER = "cover", -- 他の音声と被せて音声を再生する
    ONLY_EMPTY = 'only_empty', -- 他の音声が登録されている場合、再生しない
  },

  create = function(self, target_entity_id, sound_player_name, xml_file_variable_name)
    local sound_player_entity_id = EntityCreateNew(sound_player_name)
    addNewInternalVariable(sound_player_entity_id, self.XML_FILE_VARIABLE_NAME, "value_string", xml_file_variable_name)
    EntityAddChild(target_entity_id, sound_player_entity_id)
    return sound_player_entity_id
  end,

  playSound = function(self, sound_player_entity_id)
    local playlist = EntityGetAllChildren(sound_player_entity_id)
    if playlist == nil or #playlist == 0 then
      return
    end

    self:_syncEntityPosition(sound_player_entity_id, playlist)

    local hasForceType = false
    local hasCoverType = false
    local hasOnlyEmpty = false
    for i, sound_entity_id in ipairs(playlist) do
      local sound_type = getInternalVariableValue(sound_entity_id, self.SOUND_TYPE_VARIABLE_NAME, "value_string")
      if sound_type == self.SOUND_TYPES.FORCE then
        hasForceType = true
      elseif sound_type == self.SOUND_TYPES.COVER then
        hasCoverType = true
      elseif sound_type == self.SOUND_TYPES.ONLY_EMPTY then
        hasOnlyEmpty = true
      end
    end

    if hasOnlyEmpty then
      self:_playOnlyEmptySound(sound_player_entity_id, playlist)
      return
    end

    if hasForceType then
      self:_playForceSound(sound_player_entity_id, playlist)
      return
    end

    if hasCoverType then
      self:_playCoverSound(sound_player_entity_id, playlist)
    end

    self:_playSound(sound_player_entity_id, playlist[1])
  end,

  seachSoundPlayer = function(self, parent_entity_id, sound_player_name)
    if parent_entity_id == nil then
      return nil
    end

    for _, child_entity_id in ipairs(EntityGetAllChildren(parent_entity_id)) do
      if EntityGetName(child_entity_id) == sound_player_name then
        return child_entity_id
      end
    end

    return nil
  end,

  destroySoundPlayer = function(self, parent_entity_id, sound_player_name)
    if parent_entity_id == nil then
      return false
    end

    for _, child_entity_id in ipairs(EntityGetAllChildren(parent_entity_id) or {}) do
      if EntityGetName(child_entity_id) == sound_player_name then
        EntityKill(child_entity_id)
      end
    end

    return true
  end,

  registerSoundEntity = function(self, sound_player_entity_id, xml_file_name)
    self:_registerSoundEntity(sound_player_entity_id, xml_file_name, nil)
  end,

  registerForceSoundEntity = function(self, sound_player_entity_id, xml_file_name)
    self:_registerSoundEntity(sound_player_entity_id, xml_file_name, self.SOUND_TYPES.FORCE)
  end,

  registerCoverSoundEntity = function(self, sound_player_entity_id, xml_file_name)
    self:_registerSoundEntity(sound_player_entity_id, xml_file_name, self.SOUND_TYPES.COVER)
  end,

  registerOnlyEmptySoundEntity = function(self, sound_player_entity_id, xml_file_name)
    self:_registerSoundEntity(sound_player_entity_id, xml_file_name, self.SOUND_TYPES.ONLY_EMPTY)
  end,

  deleteSoundEntity = function(self, sound_entity_id)
    EntityKill(sound_entity_id)
  end,

  _registerSoundEntity = function(self, sound_player_entity_id, xml_file_name, type)
    local sound_entity_id = EntityCreateNew(xml_file_name)
    local xml_file_variable_name = getInternalVariableValue(sound_player_entity_id, self.XML_FILE_VARIABLE_NAME, "value_string")
    addNewInternalVariable(sound_entity_id, xml_file_variable_name, "value_string", xml_file_name)

    if type ~= nil then
      addNewInternalVariable(sound_entity_id, self.SOUND_TYPE_VARIABLE_NAME, "value_string", type)
    end

    EntityAddChild(sound_player_entity_id, sound_entity_id)
  end,

  _syncEntityPosition = function(self, sound_player_entity_id, playlist)
    for _, sound_entity_id in ipairs(playlist) do
      local x, y = EntityGetTransform(EntityGetParent(sound_player_entity_id))
      EntitySetTransform(sound_entity_id, x, y)
    end
  end,

  _playForceSound = function(self, sound_player_entity_id, playlist)
    local force_entity_ids = {}
    for _, sound_entity_id in ipairs(playlist) do
      local sound_type = getInternalVariableValue(sound_entity_id, self.SOUND_TYPE_VARIABLE_NAME, "value_string")
      if sound_type == self.SOUND_TYPES.FORCE then
        table.insert(force_entity_ids, sound_entity_id)
      end
    end

    -- 最終のforceSoundのみ残す
    if #force_entity_ids > 1 then
      for i, sound_entity_id in ipairs(force_entity_ids) do
        if i ~= #force_entity_ids then
          EntityKill(sound_entity_id)
        end
      end
    end

    self:_playSound(sound_player_entity_id, playlist[1])
  end,

  _playCoverSound = function(self, sound_player_entity_id, playlist)
    for _, sound_entity_id in ipairs(playlist) do
      local sound_type = getInternalVariableValue(sound_entity_id, self.SOUND_TYPE_VARIABLE_NAME, "value_string")
      if sound_type == self.SOUND_TYPES.COVER then
        self:_playSound(sound_player_entity_id, sound_entity_id)
      end
    end
  end,

  _playOnlyEmptySound = function(self, sound_player_entity_id, playlist)
    for _, sound_entity_id in ipairs(playlist) do
      local sound_type = getInternalVariableValue(sound_entity_id, self.SOUND_TYPE_VARIABLE_NAME, "value_string")
      if sound_type == self.SOUND_TYPES.ONLY_EMPTY then
        if #playlist > 1 then
          EntityKill(sound_entity_id)
          self:playSound(sound_player_entity_id)
        else
          self:_playSound(sound_player_entity_id, sound_entity_id)
        end
      end
    end
  end,

  _playSound = function(self, sound_player_entity_id, sound_entity_id)
    local is_loaded = getInternalVariableValue(sound_entity_id, self.IS_LOADED_VARIABLE_NAME, "value_bool") or false
    if is_loaded then
      return
    end

    local xml_file_variable_name = getInternalVariableValue(sound_player_entity_id, self.XML_FILE_VARIABLE_NAME, "value_string")
    local xml_file_name = getInternalVariableValue(sound_entity_id, xml_file_variable_name, "value_string")

    if xml_file_name == nil then
      p("===\nreturn xml_file not found\n===")
      return
    end

    EntityLoadToEntity(xml_file_name, sound_entity_id)
    addNewInternalVariable(sound_entity_id, self.IS_LOADED_VARIABLE_NAME, "value_bool", true)
  end,

  _debug_printPlaylist = function(self, playlist)
    for i, sound_entity_id in ipairs(playlist) do
      p(EntityGetName(sound_entity_id))
    end
  end,
}

