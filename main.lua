--[[============================================================================
com.bystrano.AutoClonePatterns.xrnx/main.lua v1.00
============================================================================]]--
  
----------------------------------------------------
--Preferences
----------------------------------------------------

local preferences = renoise.Document.create("ScriptingToolPreferences") {
  enabled = false,
  delete_unused = false
}

renoise.tool().preferences = preferences

-- notifications

renoise.tool().app_new_document_observable:add_notifier(function() 
    if preferences.enabled.value then enable_auto_clone()
    else disable_auto_clone() end
  end
  )

----------------------------------------------------
--Functions
----------------------------------------------------

local cloning = false 

function enable_auto_clone() -- add notifiers and update rec state

  if not renoise.song().transport.edit_mode_observable:has_notifier(rec_event) then
    renoise.song().transport.edit_mode_observable:add_notifier(rec_event)
  end
  if not renoise.song().transport.playing_observable:has_notifier(rec_event) then
    renoise.song().transport.playing_observable:add_notifier(rec_event)
  end
  if not renoise.song().transport.follow_player_observable:has_notifier(rec_event) then
    renoise.song().transport.follow_player_observable:add_notifier(rec_event)
  end
  rec_event()
  preferences.enabled.value = true

end

function disable_auto_clone() -- remove all notifiers

  if renoise.song().transport.edit_mode_observable:has_notifier(rec_event) then
    renoise.song().transport.edit_mode_observable:remove_notifier(rec_event)
  end
  if renoise.song().transport.playing_observable:has_notifier(rec_event) then
    renoise.song().transport.playing_observable:remove_notifier(rec_event)
  end
  if renoise.song().transport.follow_player_observable:has_notifier(rec_event) then
    renoise.song().transport.follow_player_observable:remove_notifier(rec_event)
  end
  if renoise.tool().app_idle_observable:has_notifier(update_pattern_sequencer) then
    renoise.tool().app_idle_observable:remove_notifier(update_pattern_sequencer)
  end
  preferences.enabled.value = false

end

function toggle_auto_clone()

  if preferences.enabled.value then
    disable_auto_clone()
  else
    enable_auto_clone()
  end

end

function rec_event() -- update the tool's rec state

  if renoise.song().transport.edit_mode and renoise.song().transport.playing 
      and renoise.song().transport.follow_player then -- if recording...
    -- add idle notifier
    if not renoise.tool().app_idle_observable:has_notifier(update_pattern_sequencer) then
      renoise.tool().app_idle_observable:add_notifier(update_pattern_sequencer)
    end
  else -- if not recording..
    if cloning then -- on cloning stop 
      cloning = false      
      if preferences.delete_unused.value then
        local loop_start = renoise.song().transport.loop_sequence_start
        local loop_end = renoise.song().transport.loop_sequence_end
        local loop_length = loop_end-loop_start+1
        local new_loop_start = loop_start - loop_length
        local new_loop_end = loop_end - loop_length
        
        -- clear and remove unused cloned patterns
        if loop_start ~= 0 then
          local index = 1
          while index <= loop_length do 
            local pattern_index = renoise.song().sequencer.pattern_sequence[loop_start]
            renoise.song().patterns[pattern_index]:clear()
            renoise.song().sequencer:delete_sequence_at(loop_start)
            index = index + 1
          end
        end
        -- after deletion, update loop sequence
        renoise.song().transport.loop_sequence_range = {new_loop_start, new_loop_end}
      end      
    end
    -- remove idle notifier
    if renoise.tool().app_idle_observable:has_notifier(update_pattern_sequencer) then
      renoise.tool().app_idle_observable:remove_notifier(update_pattern_sequencer)
    end
  end

end

function update_pattern_sequencer() -- clone patterns and update loop sequence
  
  local loop_start = renoise.song().transport.loop_sequence_start
  local loop_end = renoise.song().transport.loop_sequence_end
  local new_loop_start = loop_end + 1
  local new_loop_end = new_loop_start + (loop_end - loop_start)  
  
  if loop_start <= renoise.song().transport.playback_pos.sequence and 
      renoise.song().transport.playback_pos.sequence <= loop_end then
    -- clone sequences
    local sequencer = renoise.song().sequencer
    sequencer:clone_range(loop_start, loop_end)
        
    -- update loop sequence
    renoise.song().transport.loop_sequence_range = {new_loop_start, new_loop_end}
    cloning = true

  end
end

----------------------------------------------------
--Menu Items
----------------------------------------------------

renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:AutoClonePatterns:Enable",
    invoke = function()
      enable_auto_clone()
    end,
    selected = function() return preferences.enabled.value end
}

renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:AutoClonePatterns:Disable",
    invoke = function()
      disable_auto_clone()
    end,
    selected = function() return not preferences.enabled.value end
}

renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:AutoClonePatterns:Preferences:Delete Unused Clones On Rec Stop",
    invoke = function()
      if preferences.delete_unused.value then
        preferences.delete_unused.value = false
      else
        preferences.delete_unused.value = true
      end
    end,
    selected = function() return preferences.delete_unused.value end
}

----------------------------------------------------
--Keybindings
----------------------------------------------------

renoise.tool():add_keybinding {
  name = "Pattern Sequencer:Tools:AutoClonePatterns Enable",
  invoke = function(repeated)
    if not repeated then
      enable_auto_clone() 
    end
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Sequencer:Tools:AutoClonePatterns Disable",
  invoke = function(repeated) 
    if not repeated then
      disable_auto_clone() 
    end
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Sequencer:Tools:AutoClonePatterns Toggle On/Off",
  invoke = function(repeated) 
    if not repeated then
      toggle_auto_clone() 
    end
   end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:AutoClonePatterns Enable",
  invoke = function(repeated)
    if not repeated then
      enable_auto_clone() 
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:AutoClonePatterns Disable",
  invoke = function(repeated) 
    if not repeated then
      disable_auto_clone() 
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:AutoClonePatterns Toggle On/Off",
  invoke = function(repeated) 
    if not repeated then
      toggle_auto_clone() 
    end
   end
}
