local pd <const> = playdate

class("PuzzleGenerator").extends()

function PuzzleGenerator:init()
    math.randomseed(pd.getSecondsSinceEpoch())
end

function PuzzleGenerator:generate_puzzle(size)
    local puzzle = {
        size = size,
        solution = {},
        cages = {}
    }
    
    -- Generate a valid Latin square solution
    puzzle.solution = self:generate_latin_square(size)
    
    -- Create cages from the solution
    puzzle.cages = self:generate_cages(puzzle.solution, size)
    
    return puzzle
end

function PuzzleGenerator:generate_latin_square(size)
    local grid = {}
    
    -- Initialize empty grid
    for x = 1, size do
        grid[x] = {}
        for y = 1, size do
            grid[x][y] = 0
        end
    end
    
    -- Fill the grid using backtracking
    if self:fill_latin_square(grid, 1, 1, size) then
        return grid
    else
        -- Fallback to a simple pattern if backtracking fails
        return self:generate_simple_pattern(size)
    end
end

function PuzzleGenerator:fill_latin_square(grid, x, y, size)
    if y > size then
        return true -- Successfully filled the grid
    end
    
    local next_x, next_y = x + 1, y
    if next_x > size then
        next_x, next_y = 1, y + 1
    end
    
    -- Try each number from 1 to size
    local numbers = {}
    for i = 1, size do
        table.insert(numbers, i)
    end
    
    -- Shuffle the numbers for randomness
    for i = #numbers, 2, -1 do
        local j = math.random(i)
        numbers[i], numbers[j] = numbers[j], numbers[i]
    end
    
    for _, num in ipairs(numbers) do
        if self:is_valid_placement(grid, x, y, num, size) then
            grid[x][y] = num
            if self:fill_latin_square(grid, next_x, next_y, size) then
                return true
            end
            grid[x][y] = 0
        end
    end
    
    return false
end

function PuzzleGenerator:is_valid_placement(grid, x, y, num, size)
    -- Check row constraint
    for i = 1, size do
        if i ~= x and grid[i][y] == num then
            return false
        end
    end
    
    -- Check column constraint
    for i = 1, size do
        if i ~= y and grid[x][i] == num then
            return false
        end
    end
    
    return true
end

function PuzzleGenerator:generate_simple_pattern(size)
    local grid = {}
    for x = 1, size do
        grid[x] = {}
        for y = 1, size do
            grid[x][y] = ((x + y - 2) % size) + 1
        end
    end
    return grid
end

function PuzzleGenerator:generate_cages(solution, size)
    local cages = {}
    local used = {}
    
    -- Initialize used grid
    for x = 1, size do
        used[x] = {}
        for y = 1, size do
            used[x][y] = false
        end
    end
    
    -- Create cages
    for x = 1, size do
        for y = 1, size do
            if not used[x][y] then
                local cage = self:create_cage(solution, used, x, y, size)
                if cage then
                    table.insert(cages, cage)
                end
            end
        end
    end
    
    return cages
end

function PuzzleGenerator:create_cage(solution, used, start_x, start_y, size)
    local cells = {{start_x, start_y}}
    used[start_x][start_y] = true
    
    -- Randomly decide cage size (1-4 cells)
    local max_cage_size = math.min(4, math.random(1, 3))
    
    -- Try to add adjacent cells
    while #cells < max_cage_size do
        local added = false
        local last_cell = cells[#cells]
        local directions = {
            {0, 1}, {0, -1}, {1, 0}, {-1, 0}
        }
        
        -- Shuffle directions
        for i = #directions, 2, -1 do
            local j = math.random(i)
            directions[i], directions[j] = directions[j], directions[i]
        end
        
        for _, dir in ipairs(directions) do
            local new_x = last_cell[1] + dir[1]
            local new_y = last_cell[2] + dir[2]
            
            if new_x >= 1 and new_x <= size and new_y >= 1 and new_y <= size 
               and not used[new_x][new_y] then
                table.insert(cells, {new_x, new_y})
                used[new_x][new_y] = true
                added = true
                break
            end
        end
        
        if not added then
            break
        end
    end
    
    -- Calculate cage operation and target
    local values = {}
    for _, cell in ipairs(cells) do
        table.insert(values, solution[cell[1]][cell[2]])
    end
    
    return self:determine_cage_operation(cells, values)
end

function PuzzleGenerator:determine_cage_operation(cells, values)
    if #cells == 1 then
        return {
            cells = cells,
            operation = "=",
            target = values[1]
        }
    elseif #cells == 2 then
        local operations = {"+", "-", "*", "/"}
        local op = operations[math.random(#operations)]
        
        if op == "+" then
            return {
                cells = cells,
                operation = "+",
                target = values[1] + values[2]
            }
        elseif op == "-" then
            return {
                cells = cells,
                operation = "-",
                target = math.abs(values[1] - values[2])
            }
        elseif op == "*" then
            return {
                cells = cells,
                operation = "x",
                target = values[1] * values[2]
            }
        elseif op == "/" then
            local max_val = math.max(values[1], values[2])
            local min_val = math.min(values[1], values[2])
            if min_val > 0 and max_val % min_val == 0 then
                return {
                    cells = cells,
                    operation = "/",
                    target = max_val / min_val
                }
            else
                -- Fallback to addition if division doesn't work
                return {
                    cells = cells,
                    operation = "+",
                    target = values[1] + values[2]
                }
            end
        end
    else
        -- For larger cages, use addition or multiplication
        local op = math.random(2) == 1 and "+" or "x"
        
        if op == "+" then
            local sum = 0
            for _, v in ipairs(values) do
                sum = sum + v
            end
            return {
                cells = cells,
                operation = "+",
                target = sum
            }
        else
            local product = 1
            for _, v in ipairs(values) do
                product = product * v
            end
            return {
                cells = cells,
                operation = "x",
                target = product
            }
        end
    end
end