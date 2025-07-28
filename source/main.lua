import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

import "kenken"

local pd <const> = playdate
local gfx <const> = pd.graphics

local kenkenGame

function pd.update()
    if kenkenGame then
        kenkenGame:update()
    end
    
    pd.timer.updateTimers()
    gfx.sprite.update()
end

function pd.gameWillTerminate()
    -- Save game state if needed
end

-- Initialize the game
kenkenGame = Kenken()
kenkenGame:showSizeSelection()