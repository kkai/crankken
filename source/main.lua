import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

import "crankken"

local pd <const> = playdate
local gfx <const> = pd.graphics

local crankken_game

function pd.update()
    if crankken_game then
        crankken_game:update()
    end
    
    pd.timer.updateTimers()
    gfx.sprite.update()
end

function pd.gameWillTerminate()
    -- Save game state if needed
end

-- Initialize the game
crankken_game = CrankKen()
crankken_game:show_size_selection()