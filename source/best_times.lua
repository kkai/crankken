-- Best times management for CrankKen puzzle game
-- Handles persistent storage of best completion times using Playdate datastore

local pd <const> = playdate

class("BestTimes").extends()

-- Constants
local DATASTORE_KEY = "besttimes"
local DEFAULT_TIME_DISPLAY = "--:--"
local MILLISECONDS_PER_SECOND = 1000
local SECONDS_PER_MINUTE = 60

function BestTimes:init()
    -- Load best times from datastore, initialize with nil values if not found
    self.times = pd.datastore.read(DATASTORE_KEY) or {
        [3] = nil,  -- 3x3 best time in milliseconds
        [4] = nil,  -- 4x4 best time in milliseconds  
        [5] = nil,  -- 5x5 best time in milliseconds
        [6] = nil   -- 6x6 best time in milliseconds
    }
end

--- Get the best time for a specific puzzle size
-- @param size number: The puzzle size (3, 4, 5, or 6)
-- @return number|nil: Best time in milliseconds, or nil if no record exists
function BestTimes:get_best_time(size)
    return self.times[size]
end

--- Update best time if the new time is better
-- @param size number: The puzzle size (3, 4, 5, or 6)
-- @param completion_time number: Completion time in milliseconds
-- @return boolean: true if new record was set, false otherwise
function BestTimes:update_best_time(size, completion_time)
    if not self.times[size] or completion_time < self.times[size] then
        self.times[size] = completion_time
        self:_save()
        return true
    end
    return false
end

--- Format time in milliseconds to MM:SS display format
-- @param time_ms number|nil: Time in milliseconds
-- @return string: Formatted time string (MM:SS or "--:--")
function BestTimes:format_time(time_ms)
    if not time_ms then
        return DEFAULT_TIME_DISPLAY
    end
    
    local seconds = math.floor(time_ms / MILLISECONDS_PER_SECOND)
    local minutes = math.floor(seconds / SECONDS_PER_MINUTE)
    local remaining_seconds = seconds % SECONDS_PER_MINUTE
    
    return string.format("%02d:%02d", minutes, remaining_seconds)
end

--- Save current times to datastore (private method)
function BestTimes:_save()
    pd.datastore.write(self.times, DATASTORE_KEY)
end