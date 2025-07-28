import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

import "crankken"

local pd <const> = playdate
local gfx <const> = pd.graphics

local crankkenGame

function pd.update()
    if crankkenGame then
        crankkenGame:update()
    end
    
    pd.timer.updateTimers()
    gfx.sprite.update()
end

function pd.gameWillTerminate()
    -- Save game state if needed
end

-- Initialize the game
crankkenGame = CrankKen()
crankkenGame:showSizeSelection()