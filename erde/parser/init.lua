_ENV = require('erde.parser._env').load()

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

local function parse()
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return {
  parse = function(input)
    loadBuffer(input)
    state = STATE_FREE
  end,
}
