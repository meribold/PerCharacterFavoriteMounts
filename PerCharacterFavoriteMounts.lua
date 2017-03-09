local addonName, addon = ...

addon._G = _G
setfenv(1, addon)

print = function(...)
  _G.print("|cffff7d0a" .. addonName .. "|r:", ...)
end

local C_MountJournal = _G.C_MountJournal
local GetMountInfoByID = C_MountJournal.GetMountInfoByID
local GetDisplayedMountInfo = C_MountJournal.GetDisplayedMountInfo

function updateFavorites()
  for i = 1, C_MountJournal.GetNumDisplayedMounts() do
    local _, spellId, _, _, _, _, isFav, _, _, hideOnChar, isCollected = GetDisplayedMountInfo(i)
    if spellId and not hideOnChar and isCollected then
      -- The mount is set as character-specific favorite, but was unfavorited: clear it.
      if _G.FavoriteMounts[spellId] and not isFav then
	_G.FavoriteMounts[spellId] = nil
      -- The mount is not set as character-specific favorite, but was favorited.
      elseif not _G.FavoriteMounts[spellId] and isFav then
	_G.FavoriteMounts[spellId] = true
      end
    end
  end
end

function hookSetIsFavorite()
  -- Save favorite mounts as they are added.
  _G.hooksecurefunc(C_MountJournal, "SetIsFavorite", function(index, value)
    -- print("SetIsFavorite(" .. index .. ", " .. _G.tostring(value) .. ")")
    updateFavorites()
  end)
end

function restoreFavoriteMounts()
  -- Not generally true: _G.assert(C_MountJournal.GetNumMounts() == C_MountJournal.GetNumDisplayedMounts())
  for i = 1, C_MountJournal.GetNumDisplayedMounts() do
  -- for i, mountId in _G.ipairs(C_MountJournal.GetMountIDs()) do
    local isFav, canFavorite = C_MountJournal.GetIsFavorite(i)
    -- Not in the cards.  I.e., this assertion isn't generally true so we can't use the indices that work for
    -- GetIsFavorite() and SetIsFavorite() for C_MountJournal.GetMountInfoByID().
    -- _G.assert(isFav == (_G.select(7, GetMountInfoByID(C_MountJournal.GetMountIDs()[i]))))
    if canFavorite then
      -- local creatureName, spellId, _, _, _, _, reallyIsFav, _, _, hideOnChar, isCollected = GetMountInfoByID(mountId)
      local creatureName, spellId, _, _, _, _, reallyIsFav, _, _, hideOnChar, isCollected = GetDisplayedMountInfo(i)
      -- _G.assert(isFav == reallyIsFav)
      if spellId and not hideOnChar and isCollected then -- Weird things happen when we try to (un)favorite hidden mounts.
        local shouldFavorite = _G.FavoriteMounts[spellId] or false
        if isFav ~= shouldFavorite then
          C_MountJournal.SetIsFavorite(i, shouldFavorite)
          -- Removing a favorite changes what mount is displayed at the current index: use the same value of i again.
          if not shouldFavorite then i = i - 1 end
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
  -- Check that the actual favorites are consistent with the ones we just set.  This should always be the case, of
  -- course, but usually isn't until waiting and repeating the process a few times.
  for i = 1, C_MountJournal.GetNumDisplayedMounts() do
    local isFav, canFavorite = C_MountJournal.GetIsFavorite(i)
    if canFavorite then
      local _, spellId, _, _, _, _, _, _, _, hideOnChar, isCollected = GetDisplayedMountInfo(i)
      if spellId and not hideOnChar and isCollected then
        local shouldFavorite = _G.FavoriteMounts[spellId] or false
        if isFav ~= shouldFavorite then
          --print("Trying again in 0.5 seconds...")
          _G.C_Timer.After(.5, restoreFavoriteMounts)
          return
        end
      end
    end
  end
  -- Once all favorite mounts are restored, we can hook SetIsFavorite() and update our list when the favorites change.
  hookSetIsFavorite()
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
  -- TODO: we should probably restore the values of these settings after setting the favorites...
  C_MountJournal.SetCollectedFilterSetting(_G.LE_MOUNT_JOURNAL_FILTER_COLLECTED, true)
  C_MountJournal.SetCollectedFilterSetting(_G.LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, true)
  eventHandler:UnregisterEvent("PLAYER_ENTERING_WORLD")
  restoreFavoriteMounts()
  self.PLAYER_ENTERING_WORLD = nil
end

eventHandler:RegisterEvent("ADDON_LOADED")

--[[
Links to webpages that were useful.
  https://github.com/Adirelle/Squire3/blob/master/Squire3.lua
  http://wowpedia.org/API_C_MountJournal.GetIsFavorite
  http://wowpedia.org/API_C_MountJournal.SetIsFavorite
  http://wowpedia.org/API_C_MountJournal.GetNumMounts
  http://wowpedia.org/API_C_MountJournal.GetNumDisplayedMounts
  http://wowpedia.org/API_C_MountJournal.GetDisplayedMountInfo
  http://wowpedia.org/API_C_MountJournal.GetMountInfoByID
  http://wowpedia.org/API_C_MountJournal.GetMountInfoExtra
]]

-- vim: tw=120 sts=2 sw=2 et
