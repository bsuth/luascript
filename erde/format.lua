local C = require('erde.constants')
local parse = require('erde.parse')

-- Foward declare rules
local ArrowFunction, Assignment, Block, Break, Continue, Declaration, Destructure, DoBlock, Expr, ForLoop, Function, Goto, IfElse, Module, OptChain, Params, RepeatUntil, Return, Self, Spread, String, Table, TryCatch, WhileLoop
local SUB_FORMATTERS

-- =============================================================================
-- State
-- =============================================================================

local indentLevel
local indentWidth

-- The line prefix
local linePrefix

-- Used to indicate to rules to format to a single line.
local forceSingleLine

-- =============================================================================
-- Helpers
-- =============================================================================

-- Forward declare
local precompileNode, precompileChildren

local function reset(node)
  indentLevel = 0
  indentWidth = 2
  linePrefix = ''
  forceSingleLine = false
end

local function backup()
  return {
    indentLevel = indentLevel,
    indentWidth = indentWidth,
    linePrefix = linePrefix,
    forceSingleLine = forceSingleLine,
  }
end

local function restore(state)
  indentLevel = state.indentLevel
end

local function indent(levelDiff)
  indentLevel = indentLevel + levelDiff
  linePrefix = (' '):rep(indentLevel * indentWidth)
end

local function line(code)
  return linePrefix .. code
end

local function formatNode(node)
  if type(node) == 'string' then
    return node
  elseif type(node) ~= 'table' then
    error(('Invalid node type (%s): %s'):format(type(node), tostring(node)))
  elseif type(SUB_FORMATTERS[node.ruleName]) ~= 'function' then
    error(('Invalid ruleName: %s'):format(node.ruleName))
  end

  local formatted = SUB_FORMATTERS[node.ruleName](node)
  return node.parens and '(' .. formatted .. ')' or formatted
end

local function list(nodes, sep)
  local formattedNodes = {}

  for _, node in ipairs(nodes) do
    table.insert(formattedNodes, formatNode(node))
  end

  return table.concat(formattedNodes, sep)
end

-- =============================================================================
-- Macros
-- =============================================================================

-- =============================================================================
-- Rules
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

function ArrowFunction(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

function Assignment(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Block
-- -----------------------------------------------------------------------------

function Block(node)
  indent(1)
  local formatted = list(node, '\n')
  indent(-1)
  return formatted
end

-- -----------------------------------------------------------------------------
-- Break
-- -----------------------------------------------------------------------------

function Break(node)
  return line('break')
end

-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

function Continue(node)
  return line('continue')
end

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

function Declaration(node)
  return table.concat({
    node.variant,
    list(node.varList, ', '),
    #node.exprList > 0 and '=' or '',
    list(node.exprList, ', '),
  }, ' ')
end

-- -----------------------------------------------------------------------------
-- Destructure
-- -----------------------------------------------------------------------------

function Destructure(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- DoBlock
-- -----------------------------------------------------------------------------

function DoBlock(node)
  return table.concat({
    line('do {'),
    formatNode(node.body),
    line('}'),
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Expr
-- -----------------------------------------------------------------------------

function Expr(node)
  -- TODO: wrap
  if node.variant == 'unop' then
    return node.op.token .. formatNode(node.operand)
  elseif node.ternaryExpr then
    return ('%s ? %s : %s'):format(
      formatNode(node.lhs),
      formatNode(node.ternaryExpr),
      formatNode(node.rhs)
    )
  else
    return table.concat({
      formatNode(node.lhs),
      node.op.token,
      formatNode(node.rhs),
    }, ' ')
  end
end

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

function ForLoop(node)
  local formatted = {}
  local forceSingleLineBackup = forceSingleLine
  forceSingleLine = true

  if node.variant == 'numeric' then
    table.insert(
      formatted,
      line(table.concat({
        'for',
        node.name,
        '=',
        list(node.parts, ', '),
        '{',
      }, ' '))
    )
  else
    table.insert(
      formatted,
      line(table.concat({
        'for',
        list(node.varList, ', '),
        'in',
        list(node.exprList, ', '),
        '{',
      }, ' '))
    )
  end

  forceSingleLine = forceSingleLineBackup
  table.insert(formatted, formatNode(node.body))
  table.insert(formatted, line('}'))
  return table.concat(formatted, '\n')
end

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

function Function(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Goto
-- -----------------------------------------------------------------------------

function Goto(node)
  if node.variant == 'jump' then
    return line('goto ' .. node.name)
  elseif node.variant == 'definition' then
    return line('::' .. node.name .. '::')
  end
end

-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

function IfElse(node)
  local formatted = {
    line('if ' .. formatNode(node.ifNode.condition) .. ' {'),
    formatNode(node.ifNode.body),
  }

  for _, elseifNode in ipairs(node.elseifNodes) do
    table.insert(
      formatted,
      line('} elseif ' .. formatNode(elseifNode.condition) .. ' {')
    )
    table.insert(formatted, formatNode(elseifNode.body))
  end

  if node.elseNode then
    table.insert(formatted, line('} else {'))
    table.insert(formatted, formatNode(node.elseNode.body))
  end

  table.insert(formatted, line('}'))
  return table.concat(formatted, '\n')
end

-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

function Module(node)
  local formatted = {}

  if node.shebang then
    table.insert(formatted, node.shebang)
  end

  for _, statement in ipairs(node) do
    table.insert(formatted, formatNode(statement))
  end

  return table.concat(formatted, '\n')
end

-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

function OptChain(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

function Params(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

function RepeatUntil(node)
  return table.concat({
    line('repeat'),
    formatNode(node.body),
    line('until ' .. formatNode(node.condition)),
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

function Return(node)
  -- TODO: check line limit?
  return line('return ' .. list(node, ', '))
end

-- -----------------------------------------------------------------------------
-- Self
-- -----------------------------------------------------------------------------

function Self(node)
  if node.variant == 'self' then
    return '$'
  else
    return '$' .. node.value
  end
end

-- -----------------------------------------------------------------------------
-- Spread
-- -----------------------------------------------------------------------------

function Spread(node)
  return '...' .. (node.value and formatNode(node.value) or '')
end

-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

function String(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

function Table(node)
  return ''
end

-- -----------------------------------------------------------------------------
-- TryCatch
-- -----------------------------------------------------------------------------

function TryCatch(node)
  return table.concat({
    line('try {'),
    formatNode(node.try),
    line('} catch (' .. formatNode(node.errorName) .. ') {'),
    formatNode(node.catch),
    line('}'),
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

function WhileLoop(node)
  return table.concat({
    line('while ' .. formatNode(node.condition) .. ' {'),
    formatNode(node.body),
    line('}'),
  }, '\n')
end

-- =============================================================================
-- Format
-- =============================================================================

local format, formatMT = {}, {}
setmetatable(format, formatMT)

formatMT.__call = function(self, textOrAst)
  return format.Module(textOrAst)
end

SUB_FORMATTERS = {
  -- Rules
  ArrowFunction = ArrowFunction,
  Assignment = Assignment,
  Block = Block,
  Break = Break,
  Continue = Continue,
  Declaration = Declaration,
  Destructure = Destructure,
  DoBlock = DoBlock,
  Expr = Expr,
  ForLoop = ForLoop,
  Function = Function,
  Goto = Goto,
  IfElse = IfElse,
  Module = Module,
  OptChain = OptChain,
  Params = Params,
  RepeatUntil = RepeatUntil,
  Return = Return,
  Self = Self,
  Spread = Spread,
  String = String,
  Table = Table,
  TryCatch = TryCatch,
  WhileLoop = WhileLoop,

  -- Pseudo-Rules
  -- Var = Var,
  -- Name = Name,
  -- Number = Number,
  -- Terminal = Terminal,
  FunctionCall = OptChain,
  Id = OptChain,
}

for name, subFormatter in pairs(SUB_FORMATTERS) do
  format[name] = function(textOrAst, ...)
    local ast = type(textOrAst) == 'string' and parse[name](textOrAst, ...)
      or textOrAst
    reset()
    return subFormatter(ast)
  end
end

return format
