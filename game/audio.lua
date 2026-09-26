-- FMOD Studio events for game feedback. Banks are supplied by the project
-- author; without them the game remains silent and fully playable.
local Audio = {}
Audio.__index = Audio

local BANK_PATHS = {
  "/banks/Master Bank.strings.bank",
  "/banks/Master Bank.bank",
  "/banks/Hanafuda.bank",
}

local EVENTS = {
  ui = "event:/UI/Click",
  select = "event:/Cards/Select",
  play = "event:/Cards/Play",
  draw = "event:/Cards/Draw",
  deal = "event:/Cards/Deal",
  koi_koi = "event:/Round/KoiKoi",
  win = "event:/Round/Win",
  lose = "event:/Round/Lose",
  draw_round = "event:/Round/Draw",
}

function Audio.new()
  return setmetatable({ banks = {}, events = {}, ready = false }, Audio)
end

function Audio:init()
  if not fmod or not fmod.studio or not fmod.studio.system then return false end
  local system = fmod.studio.system
  local loaded = {}
  for _, path in ipairs(BANK_PATHS) do
    local ok, bank = pcall(function()
      return system:load_bank_memory(resource.load(path), fmod.STUDIO_LOAD_BANK_NORMAL)
    end)
    if not ok or not bank then
      for i = #loaded, 1, -1 do pcall(function() loaded[i]:unload() end) end
      print("FMOD audio unavailable: could not load " .. path .. ". Export the banks described in docs/AUDIO.md.")
      return false
    end
    loaded[#loaded + 1] = bank
  end
  self.banks = loaded
  self.ready = true
  return true
end

function Audio:play(cue)
  if not self.ready then return false end
  local path = EVENTS[cue]
  if not path then return false end
  local ok = pcall(function()
    local description = self.events[cue]
    if not description then
      description = fmod.studio.system:get_event(path)
      self.events[cue] = description
    end
    description:create_instance():start()
  end)
  return ok
end

function Audio:final()
  for i = #self.banks, 1, -1 do pcall(function() self.banks[i]:unload() end) end
  self.banks, self.events, self.ready = {}, {}, false
end

return Audio
