local addonName, addon = ...

addon._G = _G
setfenv(1, addon)

print = function(...)
  _G.print("|cffff7d0a" .. addonName .. "|r:", ...)
end

local C_MountJournal = _G.C_MountJournal

function restoreFavoriteMounts()
  for i = 1, C_MountJournal.GetNumMounts() do
    local isFavorite, canFavorite = C_MountJournal.GetIsFavorite(i)
    if canFavorite then
      local creatureName, spellId, _, _, _, _, _, _, _, hideOnChar, isCollected = C_MountJournal.GetMountInfo(i)
      if not hideOnChar and isCollected then -- Weird things happen when we try to (un)favorite hidden mounts.
        local shouldFavorite = _G.FavoriteMounts[spellId] or false
        if isFavorite ~= shouldFavorite then
          C_MountJournal.SetIsFavorite(i, shouldFavorite)
          --[[
          if shouldFavorite then
            print("Favoriting \"" .. creatureName .. "\" (" .. spellId .. ")")
          else
            print("Unfavoriting \"" .. creatureName .. "\" (" .. spellId .. ")")
          end
          --]]
        end
      end
    end
  end
  for i = 1, C_MountJournal.GetNumMounts() do
    local isFavorite, canFavorite = C_MountJournal.GetIsFavorite(i)
    if canFavorite then
      local _, spellId, _, _, _, _, _, _, _, hideOnChar, isCollected = C_MountJournal.GetMountInfo(i)
      if not hideOnChar and isCollected then
        local shouldFavorite = _G.FavoriteMounts[spellId] or false
        if isFavorite ~= shouldFavorite then
          --print("Trying again in 0.5 seconds...")
          _G.C_Timer.After(.5, restoreFavoriteMounts)
          break
        end
      end
    end
  end
end

--_G.restoreFavoriteMounts = restoreFavoriteMounts

local eventHandler = _G.CreateFrame("Frame")
eventHandler:SetScript("OnEvent", function(_, event, ...)
  return addon[event](addon, ...)
end)

function addon:ADDON_LOADED(name)
  if name ~= addonName then return end

  eventHandler:UnregisterEvent("ADDON_LOADED")

  _G.FavoriteMounts = _G.FavoriteMounts or {}
  eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")

  self.ADDON_LOADED = nil
end

function addon:PLAYER_ENTERING_WORLD()
  --_G.assert(C_MountJournal)
  eventHandler:UnregisterEvent("PLAYER_ENTERING_WORLD")

  restoreFavoriteMounts()

  -- Save favorite mounts as they are added.
  _G.hooksecurefunc(C_MountJournal, "SetIsFavorite", function(index, value)
    --print("SetIsFavorite(" .. index .. ", " .. _G.tostring(value) .. ")")
    local _, spellId = C_MountJournal.GetMountInfo(index)
    _G.FavoriteMounts[spellId] = value or nil -- Assign nil (remove the key) when value == false.
  end)

  self.PLAYER_ENTERING_WORLD = nil
end

eventHandler:RegisterEvent("ADDON_LOADED")

--[[
Links to webpages that were useful.
  https://github.com/Adirelle/Squire3/blob/master/Squire3.lua
  http://wowpedia.org/API_C_MountJournal.GetIsFavorite
  http://wowpedia.org/API_C_MountJournal.SetIsFavorite
  http://wowpedia.org/API_C_MountJournal.GetNumMounts
  http://wowpedia.org/API_C_MountJournal.GetMountInfo
  http://wowpedia.org/API_C_MountJournal.GetMountInfoExtra
]]

-- vim: tw=120 sts=2 sw=2 et
