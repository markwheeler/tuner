-- Tuner
-- 1.0.2 @markeats
-- llllllll.co/t/tuner
--
-- Responds to audio input.
-- E2 : Reference note
-- E3 : Reference volume
--

local ControlSpec = require "controlspec"
local MusicUtil = require "musicutil"
local Formatters = require "formatters"

engine.name = "TestSine"

local SCREEN_FRAMERATE = 15
local screen_dirty = true

local current_freq = -1
local last_freq = -1

NOTE_NAMES = {"A0", "A#0", "B0", "C1", "C#1", "D1", "D#1", "E1", "F1", "F#1", "G1", "G#1", "A1", "A#1", "B1", "C2", "C#2", "D2", "D#2", "E2", "F2", "F#2", "G2", "G#2", "A2", "A#2", "B2", "C3", "C#3", "D3", "D#3", "E3", "F3", "F#3", "G3", "G#3", "A3", "A#3", "B3", "C4", "C#4", "D4", "D#4", "E4", "F4", "F#4", "G4", "G#4", "A4", "A#4", "B4", "C5", "C#5", "D5", "D#5", "E5", "F5", "F#5", "G5", "G#5", "A5", "A#5", "B5", "C6", "C#6", "D6", "D#6", "E6", "F6", "F#6", "G6", "G#6", "A6", "A#6", "B6", "C7", "C#7", "D7", "D#7", "E7", "F7", "F#7", "G7", "G#7", "A7", "A#7", "B7", "C8"}


-- Encoder input
function enc(n, delta)
  
  if n == 2 then
    params:delta("note", delta)        
  elseif n == 3 then
    params:delta("note_vol", delta)
  end
end

-- Key input
function key(n, z)
  if z == 1 then
    if n == 2 then
      
    elseif n == 3 then
      
    end
  end
end


local function update_freq(freq)
  current_freq = freq
  if current_freq > 0 then last_freq = current_freq end
  screen_dirty = true
end


function init()
  
  engine.amp(0)
  
  -- Add params
  
  params:add{type = "option", id = "in_channel", name = "In Channel", options = {"Left", "Right"}}
  params:add{type = "option", id = "note", name = "Note", options = NOTE_NAMES, default = 37, action = function(value)
    engine.hz(MusicUtil.note_num_to_freq(32 + value))
    screen_dirty = true
  end}
  params:add{type = "control", id = "note_vol", name = "Note Volume", controlspec = ControlSpec.UNIPOLAR, action = function(value)
    engine.amp(value)
    screen_dirty = true
  end}
  
  params:bang()
  
  -- Polls
  
  local pitch_poll_l = poll.set("pitch_in_l", function(value)
    if params:get("in_channel") == 1 then
      update_freq(value)
    end
  end)
  pitch_poll_l:start()
  
  local pitch_poll_r = poll.set("pitch_in_r", function(value)
    if params:get("in_channel") == 2 then
      update_freq(value)
    end
  end)
  pitch_poll_r:start()
  
  local screen_refresh_metro = metro.init()
  screen_refresh_metro.event = function()
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)
  screen.aa(1)
end


function redraw()
  screen.clear()
  
  -- Draw rules
  
  for i = 1, 11 do
    local x = util.round(12.7 * (i - 1)) + 0.5
    if i == 6 then
      if current_freq > 0 then screen.level(15)
      else screen.level(3) end
      screen.move(x, 24)
      screen.line(x, 35)
    else
      if current_freq > 0 then screen.level(3)
      else screen.level(1) end
      screen.move(x, 29)
      screen.line(x, 35)
    end
    screen.stroke()
  end
  
  -- Draw last freq line
  
  local note_num = MusicUtil.freq_to_note_num(last_freq)
  local freq_x
  if last_freq > 0 then
    freq_x = util.explin(math.max(MusicUtil.note_num_to_freq(note_num - 0.5), 0.00001), MusicUtil.note_num_to_freq(note_num + 0.5), 0, 128, last_freq)
    freq_x = util.round(freq_x) + 0.5
  else
    freq_x = 64.5
  end
  if current_freq > 0 then screen.level(15)
  else screen.level(3) end
  screen.move(freq_x, 29)
  screen.line(freq_x, 40)
  screen.stroke()
  
  -- Draw text
  
  screen.move(64, 19)
  if current_freq > 0 then screen.level(15)
  else screen.level(3) end
  
  if last_freq > 0 then
    screen.text_center(MusicUtil.note_num_to_name(note_num, true))
  end
  
  if last_freq > 0 then
    screen.move(64, 50)
    if current_freq > 0 then screen.level(3)
    else screen.level(1) end
    screen.text_center(Formatters.format_freq_raw(last_freq))
  end
  
  -- Draw ref note
  
  screen.move(128, 8)
  screen.level(util.round(params:get("note_vol") * 15))
  screen.text_right(params:string("note"))
  
  screen.fill()
  
  screen.update()
end

