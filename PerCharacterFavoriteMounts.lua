local addOnName, addOn = ...

addOn._G = _G
setfenv(1, addOn)

local C_MountJournal = _G.C_MountJournal

function restoreFavoriteMounts()
  for i = 1, C_MountJournal.GetNumMounts() do
    local isFavorite, canFavorite = C_MountJournal.GetIsFavorite(i)
    if canFavorite then
      local _, spellID, _, _, _, _, _, _, _, hideOnChar, isCollected = C_MountJournal.GetMountInfo(i)
      if not hideOnChar and isCollected then -- Weird things happen when we try to (un)favorite hidden mounts.
        local shouldFavorite = _G.FavoriteMounts[spellID] or false
        if isFavorite ~= shouldFavorite then
          --_G.print(i, spellID, _G.GetSpellInfo(spellID), shouldFavorite)
          C_MountJournal.SetIsFavorite(i, shouldFavorite)
        end
      end
    end
  end
end

local eventHandler = _G.CreateFrame("Frame")
eventHandler:SetScript("OnEvent", function(_, event, ...)
  return addOn[event](addOn, ...)
end)

function addOn:ADDON_LOADED(name)
  if name ~= addOnName then return end

  eventHandler:UnregisterEvent("ADDON_LOADED")

  _G.FavoriteMounts = _G.FavoriteMounts or {}
  eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")

  self.ADDON_LOADED = nil
end

function addOn:PLAYER_ENTERING_WORLD()
  --_G.assert(C_MountJournal)
  eventHandler:UnregisterEvent("PLAYER_ENTERING_WORLD")

  restoreFavoriteMounts()

  -- Save favorite mounts as they are added.
  _G.hooksecurefunc(C_MountJournal, "SetIsFavorite", function(index, value)
    --_G.print("SetIsFavorite(" .. index .. ", " .. _G.tostring(value) .. ")")
    local _, spellID = C_MountJournal.GetMountInfo(index)
    _G.FavoriteMounts[spellID] = value or nil -- Assign nil (remove the key) when value == false.
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

-- vim: tw=120 sw=2 et
