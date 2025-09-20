WaitFrame = {
  SUFFIXES = {
    wait_frame="wait_frame",
    register_frame="register_frame"
  },

  removeRegister = function(self, entity_id, variable_name)
    RemoveInternalVariableValue(entity_id, variable_name .. self.SUFFIXES["wait_frame"], "value_int")
    RemoveInternalVariableValue(entity_id, variable_name .. self.SUFFIXES["register_frame"], "value_int")
  end,

  canCall = function(self, entity_id, variable_name)
    local current_frame = GameGetFrameNum()
    local wait_frame = GetInternalVariableValue(entity_id, variable_name .. self.SUFFIXES["wait_frame"], "value_int")
    local register_frame = GetInternalVariableValue(entity_id, variable_name .. self.SUFFIXES["register_frame"], "value_int")

    if wait_frame == nil or wait_frame == 0 or register_frame == nil or register_frame == 0 then
      return false
    end

    return current_frame - register_frame >= wait_frame
  end,

  addWaitFrame = function(self, entity_id, variable_name, wait_frame)
    local current_frame = GameGetFrameNum()
    local register_frame = GetInternalVariableValue(entity_id, variable_name .. self.SUFFIXES["register_frame"], "value_int")

    if register_frame == nil or register_frame == 0 then
      -- 未登録
      register_frame = current_frame
      AddNewInternalVariable(entity_id, variable_name .. self.SUFFIXES["wait_frame"], "value_int", wait_frame)
      AddNewInternalVariable(entity_id, variable_name .. self.SUFFIXES["register_frame"], "value_int", register_frame)
    end
  end,

  updateWaitFrame = function(self, entity_id, variable_name, wait_frame)
    local current_frame = GameGetFrameNum()
    local register_frame = current_frame
    SetInternalVariableValue(entity_id, variable_name .. self.SUFFIXES["wait_frame"], "value_int", wait_frame)
    SetInternalVariableValue(entity_id, variable_name .. self.SUFFIXES["register_frame"], "value_int", register_frame)
  end,

  registered = function(self, entity_id, variable_name)
    local register_frame = GetInternalVariableValue(entity_id, variable_name .. self.SUFFIXES["register_frame"], "value_int")
    return not (register_frame == nil or register_frame == 0)
  end,

  -- 呼べそうなら、callbackを呼び出した後再登録する
  -- 呼べない場合はなにもしない
  -- return boolean: 呼び出せたか？
  tryCall = function(self, entity_id, variable_name, callback, wait_frame)
    if wait_frame == nil then
      -- default
      wait_frame = 120
    end

    if self:registered(entity_id, variable_name) then
      if self:canCall(entity_id, variable_name) then
        callback()
        self:removeRegister(entity_id, variable_name)
        self:addWaitFrame(entity_id, variable_name, wait_frame)
        return true
      end
    else
      self:addWaitFrame(entity_id, variable_name, wait_frame)
      callback()
      return true
    end
    return false
  end
}
