local inspect = require('inspect')
local lpeg = require('lpeg')
lpeg.locale(lpeg)

local compiler = require('compiler')
local supertable = require('supertable')

-- -----------------------------------------------------------------------------
-- Environment
--
-- Sets the fenv so that we don't have to prefix everything with `lpeg.` and
-- don't have to manually destructure everything.
-- -----------------------------------------------------------------------------

local env = setmetatable({}, { __index = _G })

for k, v in pairs(lpeg) do
  if _G[k] == nil then
    env[k] = v
  end
end

setfenv(1, env)

-- -----------------------------------------------------------------------------
-- State
-- -----------------------------------------------------------------------------

local state = {}

function state.reset()
  state.line = 1
  state.colstart = 0
end

function state.newline(position)
  state.colstart = position
  state.line = state.line + 1
end

-- -----------------------------------------------------------------------------
-- Grammar Helpers
-- -----------------------------------------------------------------------------

local function Pad(pattern)
  return V('Space') * pattern * V('Space')
end

local function PadC(pattern)
  return V('Space') * C(pattern) * V('Space')
end

local function Sum(...)
  return supertable({ ... }):reduce(function(sum, pattern)
    return sum + pattern
  end, P(false))
end

local function Product(...)
  return supertable({ ... }):reduce(function(product, pattern)
    return product * pattern
  end, P(true))
end

local function Demand(pattern)
  return pattern + Cc('__ORBIT_ERROR__') * Cp() / function(capture, position)
    if capture == '__ORBIT_ERROR__' then
      error(('Line %s, Column %s: Error'):format(
        state.line,
        position - state.colstart
      ))
    else
      return capture
    end
  end
end

-- -----------------------------------------------------------------------------
-- Rule Helpers
-- -----------------------------------------------------------------------------

function Binop(op)
  return V('Expr') * op * V('Expr')
end

function Csv(pattern, commacapture)
  local comma = commacapture and PadC(',') or Pad(',')
  return pattern * (comma * pattern) ^ 0 * Pad(',') ^ -1
end

-- -----------------------------------------------------------------------------
-- Rule Sets
-- -----------------------------------------------------------------------------

function RuleSet(patterns)
  return supertable(patterns):map(function(pattern, rule)
    return Cp() * pattern / function(position, ...)
      local node = supertable(
        { rule = rule, position = position },
        supertable({ ... }):filter(function(value)
          return value ~= nil
        end)
      )
      return #node > 0 and node or nil
    end
  end)
end

local Core = RuleSet({
  Keyword = Pad(Sum(
    P('local'),
    P('if'),
    P('elseif'),
    P('else'),
    P('false'),
    P('true'),
    P('nil'),
    P('return')
  )),

  Id = C(-V('Keyword') * (alpha + P('_')) * (alnum + P('_')) ^ 0),
  IdExpr = (PadC('(') * V('Expr') * PadC(')') + V('Id')) * V('IndexChain') ^ -1,

  Newline = P('\n') * (Cp() / state.newline),
  Space = (V('Newline') + space) ^ 0,

  SingleLineComment = Pad('//') * (P(1) - V('Newline')) ^ 0,
  MultiLineComment = Pad('/*') * (P(1) - P('*/')) ^ 0 * Pad('*/'),
  Comment = V('SingleLineComment') + V('MultiLineComment'),

  Integer = digit ^ 1,
  Hex = (P('0x') + P('0X')) * xdigit ^ 1,
  Exponent = S('eE') * S('+-') ^ -1 * V('Integer'),
  Float = Sum(
    digit ^ 0 * P('.') * V('Integer') * V('Exponent') ^ -1,
    V('Integer') * V('Exponent')
  ),
  Number = C(V('Float') + V('Hex') + V('Integer')),
})

local Strings = RuleSet({
  EscapedChar = C(V('Newline') + P('\\') * P(1)),

  Interpolation = P('{') * Pad(Demand(V('Expr'))) * P('}'),
  LongString = Product(
    P('`'),
    Sum(
      V('EscapedChar'),
      V('Interpolation'),
      C(P(1) - P('`'))
    ) ^ 0,
    P('`')
  ),

  String = Sum(
    V('LongString'),
    C("'") * (V('EscapedChar') + C(1) - P("'")) ^ 0 * C("'"), -- single quote
    C('"') * (V('EscapedChar') + C(1) - P('"')) ^ 0 * C('"') -- double quote
  ),
})

local Tables = RuleSet({
  StringTableKey = V('String'),
  MapTableField = (V('StringTableKey') + V('Id')) * Pad(':') * V('Expr'),
  InlineTableField = Pad(P(':') * V('Id')),
  TableField = V('InlineTableField') + V('MapTableField') + V('Expr'),
  Table = PadC('{') * (Csv(V('TableField'), true) + V('Space')) * PadC('}'),

  DotIndex = V('Space') * C('.') * V('Id'),
  BracketIndex = PadC('[') * V('Expr') * PadC(']'),
  IndexChain = (V('DotIndex') + V('BracketIndex')) ^ 1,
  IndexExpr = (PadC('(') * V('Expr') * PadC(')') + V('Id')) * V('IndexChain'),

  Destruct = Product(
    C(':') + Cc(false),
    V('Id'),
    V('Destructure') + Cc(false),
    (Pad('=') * Demand(V('Expr'))) + Cc(false)
  ),
  Destructure = Pad('{') * Csv(V('Destruct')) * Pad('}'),
})

local Functions = RuleSet({
  Arg = Sum(
    Cc(false) * V('Id'),
    Cc(true) * V('Destructure')
  ),
  OptArg = V('Arg') * Pad('=') * V('Expr'),
  VarArgs = Pad('...') * V('Id') ^ -1,
  ParamComma = (#Pad(')') * Pad(',') ^ -1) + Pad(','),
  Params = V('Arg') + Product(
    Pad('('),
    (V('Arg') * V('ParamComma')) ^ 0,
    (V('OptArg') * V('ParamComma')) ^ 0,
    (V('VarArgs') * V('ParamComma')) ^ -1,
    Cc({}),
    Pad(')')
  ),

  FunctionExprBody = V('Expr'),
  FunctionBody = Pad('{') * V('Block') * Pad('}') + V('FunctionExprBody'),
  Function = Sum(
    Cc(false) * V('Params') * Pad('->') * V('FunctionBody'),
    Cc(true) * V('Params') * Pad('=>') * V('FunctionBody')
  ),

  FunctionCall = Product(
    V('IdExpr'),
    (PadC(':') * V('Id')) ^ -1,
    PadC('('),
    Csv(V('Expr'), true) + V('Space'),
    PadC(')')
  ),
})

local LogicFlow = RuleSet({
  If = Pad('if') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  ElseIf = Pad('elseif') * V('Expr') * Pad('{') * V('Block') * Pad('}'),
  Else = Pad('else') * Pad('{') * V('Block') * Pad('}'),
  IfElse = V('If') * V('ElseIf') ^ 0 * V('Else') ^ -1,

  Return = PadC('return') * V('Expr') ^ -1,
})

local Expressions = RuleSet({
  AtomExpr = Sum(
    V('Function'),
    V('Table'),
    V('Id'),
    V('String'),
    V('Number'),
    PadC('true'),
    PadC('false')
  ),

  MoleculeExpr = Sum(
    V('FunctionCall'),
    V('IndexExpr'),
    V('Binop'),
    V('AtomExpr')
  ),

  OrganismExpr = Sum(
    V('Ternary'),
    V('NullCoalescence'),
    V('MoleculeExpr')
  ),

  Expr = PadC('(') * V('Expr') * PadC(')') + V('OrganismExpr'),
})

local Operators = RuleSet({
  LogicalAnd = Binop(Pad('&&')),
  LogicalOr = Binop(Pad('||')),

  EchoOperator = Binop(PadC(Sum(
    P('>='),
    P('<='),
    P('=='),
    P('~='),
    S('+-*/%><')
  ))),

  Binop = Sum(
    V('LogicalAnd'),
    V('LogicalOr'),
    V('EchoOperator')
  ),

  Ternary = V('MoleculeExpr') * Pad('?') * V('Expr') * (Pad(':') * V('Expr')) ^ -1,
  NullCoalescence = V('MoleculeExpr') * Pad('??') * V('Expr'),
})

local Declaration = RuleSet({
  IdDeclaration = Product(
    PadC('local') + C(false),
    V('Id'),
    (PadC('=') * Demand(V('Expr'))) ^ -1
  ),

  VarArgsDeclaration = Product(
    PadC('local') + C(false),
    Pad('...'),
    V('Id'),
    Demand(Pad('=') * V('Expr'))
  ),

  DestructureDeclaration = Product(
    PadC('local') + C(false),
    V('Destructure'),
    Demand(Pad('=') * V('Expr'))
  ),

  Declaration = Sum(
    V('DestructureDeclaration'),
    V('VarArgsDeclaration'),
    V('IdDeclaration')
  ),
})

local Blocks = RuleSet({
  Block = V('Statement') ^ 0,
  Statement = Pad(Sum(
    V('FunctionCall'),
    V('Declaration'),
    V('Return'),
    V('IfElse'),
    V('Comment')
  )),
})

-- -----------------------------------------------------------------------------
-- Grammar
-- -----------------------------------------------------------------------------

local grammar = P(supertable(
  { V('Block') },
  Blocks,
  Declaration,
  Operators,
  Expressions,
  LogicFlow,
  Functions,
  Tables,
  Strings,
  Core
))

return function(subject)
  lpeg.setmaxstack(1000)
  state.reset()
  local ast = grammar:match(subject, nil, {})
  return ast or {}, state
end
